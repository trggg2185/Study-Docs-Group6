import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../struct/document_struct.dart';
import '../modified/models/document_model.dart';
import '../widgets/framework/app_scaffold.dart';
import '../widgets/util/loading_indicator.dart';
import 'document_form_page.dart';

/// Trang chi tiết tài liệu - hiển thị đầy đủ thông tin + nút sửa/xóa
/// Sử dụng StreamBuilder để reactive khi tài liệu được cập nhật
class DocumentDetailPage extends StatelessWidget {
  final String documentId;

  const DocumentDetailPage({super.key, required this.documentId});

  /// Mở liên kết nếu là URL
  Future<void> _launchFilePath(BuildContext context, String path) async {
    try {
      final uri = Uri.parse(path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở liên kết này')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi khi mở liên kết: $e')));
      }
    }
  }

  /// Xác nhận và xóa tài liệu
  Future<void> _confirmDelete(BuildContext context, DocumentModel doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa "${doc.title}"?\n\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<DocumentStruct>().deleteById(doc.id);
      if (context.mounted) {
        Navigator.pop(context); // Quay về trang trước
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Đã xóa "${doc.title}"')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final docStruct = context.read<DocumentStruct>();

    return StreamBuilder<DocumentModel?>(
      // Reactive: tự cập nhật khi tài liệu thay đổi trong DB
      stream: docStruct.watchById(documentId),
      builder: (context, snapshot) {
        final doc = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppScaffold(
            title: 'Chi tiết',
            body: LoadingIndicator(message: 'Đang tải...'),
          );
        }

        if (doc == null) {
          return AppScaffold(
            title: 'Chi tiết',
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text('Tài liệu không tồn tại hoặc đã bị xóa'),
                ],
              ),
            ),
          );
        }

        return AppScaffold(
          title: 'Chi tiết tài liệu',
          actions: [
            // Nút sửa
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DocumentFormPage(documentId: doc.id),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              tooltip: 'Sửa',
            ),
            // Nút xóa
            IconButton(
              onPressed: () => _confirmDelete(context, doc),
              icon: const Icon(Icons.delete),
              tooltip: 'Xóa',
            ),
          ],
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === Tiêu đề ===
                Text(
                  doc.title,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // === Badge loại tài liệu ===
                _buildTypeBadge(doc.type),
                const SizedBox(height: 16),

                // === Thông tin chi tiết ===
                _buildInfoCard(context, doc),
                const SizedBox(height: 16),

                // === Mô tả ===
                if (doc.description.isNotEmpty) ...[
                  Text(
                    'Mô tả',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        doc.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Badge hiển thị loại tài liệu với màu sắc
  Widget _buildTypeBadge(DocumentType type) {
    Color color;
    IconData icon;
    switch (type) {
      case DocumentType.lecture:
        color = Colors.blue;
        icon = Icons.school;
        break;
      case DocumentType.exercise:
        color = Colors.orange;
        icon = Icons.assignment;
        break;
      case DocumentType.reference:
        color = Colors.green;
        icon = Icons.menu_book;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            type.displayName,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// Card thông tin chi tiết
  Widget _buildInfoCard(BuildContext context, DocumentModel doc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow(context, Icons.subject, 'Môn học', doc.subject),
            const Divider(),
            _filePathRow(context, doc.filePath),
            const Divider(),
            _infoRow(
              context,
              Icons.calendar_today,
              'Ngày tạo',
              _formatDateTime(doc.createdAt),
            ),
            const Divider(),
            _infoRow(
              context,
              Icons.update,
              'Cập nhật lần cuối',
              _formatDateTime(doc.updatedAt),
            ),
          ],
        ),
      ),
    );
  }

  /// Hàng thông tin đường dẫn file (hỗ trợ mở link & copy)
  Widget _filePathRow(BuildContext context, String filePath) {
    final hasPath = filePath.isNotEmpty;
    final isUrl =
        filePath.startsWith('http://') || filePath.startsWith('https://');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.attach_file, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            'Tệp đính kèm:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasPath ? filePath : '(chưa có)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: hasPath ? FontStyle.normal : FontStyle.italic,
                color: hasPath
                    ? (isUrl
                          ? Colors.blue
                          : Theme.of(context).colorScheme.primary)
                    : Colors.grey,
                decoration: isUrl ? TextDecoration.underline : null,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          if (hasPath) ...[
            if (isUrl)
              IconButton(
                icon: const Icon(
                  Icons.open_in_new,
                  size: 18,
                  color: Colors.blue,
                ),
                tooltip: 'Mở liên kết',
                visualDensity: VisualDensity.compact,
                onPressed: () => _launchFilePath(context, filePath),
              ),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'Sao chép đường dẫn',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: filePath));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã sao chép đường dẫn vào clipboard!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Hàng thông tin
  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  /// Format ngày giờ
  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
