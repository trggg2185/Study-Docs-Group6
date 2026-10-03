import 'package:flutter/material.dart';
import '../../modified/models/document_model.dart';

/// Widget hiển thị một tài liệu trong danh sách (ListTile nâng cao)
class DocumentTile extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const DocumentTile({
    super.key,
    required this.document,
    this.onTap,
    this.onDelete,
  });

  /// Lấy icon tương ứng với loại tài liệu
  IconData _getTypeIcon() {
    switch (document.type) {
      case DocumentType.lecture:
        return Icons.school;
      case DocumentType.exercise:
        return Icons.assignment;
      case DocumentType.reference:
        return Icons.menu_book;
    }
  }

  /// Lấy màu tương ứng với loại tài liệu
  Color _getTypeColor() {
    switch (document.type) {
      case DocumentType.lecture:
        return Colors.blue;
      case DocumentType.exercise:
        return Colors.orange;
      case DocumentType.reference:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTypeColor();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(_getTypeIcon(), color: color, size: 22),
        ),
        title: Text(
          document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              document.subject,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                // Badge loại tài liệu
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    document.type.displayName,
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                ),
                const Spacer(),
                // Ngày tạo
                Text(
                  _formatDate(document.updatedAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        onTap: onTap,
        trailing: onDelete != null
            ? IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                onPressed: onDelete,
                tooltip: 'Xóa tài liệu',
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }

  /// Format ngày tháng dạng dd/MM/yyyy
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
