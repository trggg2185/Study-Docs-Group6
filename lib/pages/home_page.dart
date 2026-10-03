import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../struct/document_struct.dart';
import '../struct/search_struct.dart';
import '../modified/models/document_model.dart';
import '../widgets/framework/app_scaffold.dart';
import '../widgets/framework/document_tile.dart';
import '../widgets/framework/search_field.dart';
import '../widgets/util/loading_indicator.dart';
import '../widgets/util/empty_state.dart';
import 'document_form_page.dart';
import 'document_detail_page.dart';

/// Trang chính - hiển thị danh sách tài liệu, search bar, bộ lọc
/// Sử dụng StreamBuilder để reactive rebuild khi DB thay đổi
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DocumentType? _filterType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Mở form thêm tài liệu mới
  void _openAddDocument() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const DocumentFormPage()));
  }

  /// Mở chi tiết tài liệu
  void _openDocumentDetail(DocumentModel doc) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DocumentDetailPage(documentId: doc.id)),
    );
  }

  /// Xác nhận và xóa tài liệu
  Future<void> _confirmDelete(DocumentModel doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${doc.title}"?'),
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

    if (confirmed == true && mounted) {
      await context.read<DocumentStruct>().deleteById(doc.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Đã xóa "${doc.title}"')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchStruct = context.read<SearchStruct>();
    final docStruct = context.read<DocumentStruct>();

    return AppScaffold(
      title: 'StudyDocs',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDocument,
        icon: const Icon(Icons.add),
        label: const Text('Thêm'),
      ),
      body: Column(
        children: [
          // === Ô tìm kiếm ===
          SearchField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            onClear: () => setState(() => _searchQuery = ''),
          ),

          // === Bộ lọc theo loại tài liệu ===
          _buildFilterChips(),

          // === Thống kê số lượng (bonus) ===
          _buildStats(docStruct),

          const Divider(height: 1),

          // === Danh sách tài liệu (reactive) ===
          Expanded(
            child: StreamBuilder<List<DocumentModel>>(
              // Luồng reactive: UI tự rebuild khi DB thay đổi
              stream: searchStruct.search(
                query: _searchQuery.isEmpty ? null : _searchQuery,
                type: _filterType,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator(
                    message: 'Đang tải tài liệu...',
                  );
                }

                if (snapshot.hasError) {
                  return EmptyState(
                    icon: Icons.error_outline,
                    title: 'Có lỗi xảy ra',
                    subtitle: snapshot.error.toString(),
                  );
                }

                final docs = snapshot.data ?? [];

                if (docs.isEmpty) {
                  return EmptyState(
                    icon: Icons.description_outlined,
                    title: _searchQuery.isNotEmpty || _filterType != null
                        ? 'Không tìm thấy tài liệu'
                        : 'Chưa có tài liệu nào',
                    subtitle: _searchQuery.isNotEmpty || _filterType != null
                        ? 'Thử thay đổi bộ lọc hoặc từ khóa'
                        : 'Nhấn nút + để thêm tài liệu mới',
                    action: _searchQuery.isEmpty && _filterType == null
                        ? FilledButton.icon(
                            onPressed: _openAddDocument,
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm tài liệu'),
                          )
                        : null,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 80),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return DocumentTile(
                      document: doc,
                      onTap: () => _openDocumentDetail(doc),
                      onDelete: () => _confirmDelete(doc),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Chips lọc theo loại tài liệu
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Chip "Tất cả"
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: _filterType == null,
                label: const Text('Tất cả'),
                onSelected: (_) => setState(() => _filterType = null),
              ),
            ),
            // Chip cho mỗi loại
            ...DocumentType.values.map(
              (type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: _filterType == type,
                  label: Text(type.displayName),
                  onSelected: (_) => setState(() {
                    _filterType = _filterType == type ? null : type;
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget thống kê số lượng tài liệu theo loại (Bonus - StreamBuilder)
  Widget _buildStats(DocumentStruct docStruct) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: DocumentType.values.map((type) {
          return Expanded(
            child: StreamBuilder<int>(
              stream: docStruct.watchCountByType(type),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Chip(
                    avatar: Text(
                      '$count',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    label: Text(
                      type.displayName,
                      style: const TextStyle(fontSize: 11),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
