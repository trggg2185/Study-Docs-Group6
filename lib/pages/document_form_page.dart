import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../struct/document_struct.dart';
import '../struct/category_struct.dart';
import '../modified/models/document_model.dart';
import '../modified/models/category_model.dart';
import '../widgets/framework/app_scaffold.dart';

/// Trang thêm/sửa tài liệu
/// Nhận documentId để phân biệt mode thêm mới / chỉnh sửa
class DocumentFormPage extends StatefulWidget {
  final String? documentId; // null = thêm mới, có giá trị = sửa

  const DocumentFormPage({super.key, this.documentId});

  bool get isEditing => documentId != null;

  @override
  State<DocumentFormPage> createState() => _DocumentFormPageState();
}

class _DocumentFormPageState extends State<DocumentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subjectController = TextEditingController();
  final _filePathController = TextEditingController();

  DocumentType _selectedType = DocumentType.lecture;
  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    _filePathController.dispose();
    super.dispose();
  }

  /// Load dữ liệu khi ở mode sửa
  Future<void> _loadDocument() async {
    if (!widget.isEditing || _isInitialized) return;

    final doc = await context.read<DocumentStruct>().getById(
      widget.documentId!,
    );
    if (doc != null && mounted) {
      setState(() {
        _titleController.text = doc.title;
        _descriptionController.text = doc.description;
        _subjectController.text = doc.subject;
        _filePathController.text = doc.filePath;
        _selectedType = doc.type;
        _selectedCategoryId = doc.categoryId;
        _isInitialized = true;
      });
    }
  }

  /// Chọn file từ bộ nhớ thiết bị (Android / iOS / Desktop / Web)
  Future<void> _pickFileFromDevice() async {
    try {
      final files = await FilePicker.pickFiles(type: FileType.any);

      if (files.isNotEmpty) {
        final pickedFile = files.first;
        // Trên Android: pickedFile.path chứa đường dẫn truy cập file
        final selectedPath = pickedFile.path ?? pickedFile.name;

        setState(() {
          _filePathController.text = selectedPath;
          // Tự động điền tiêu đề nếu chưa có
          if (_titleController.text.trim().isEmpty) {
            final fileNameWithoutExt = pickedFile.name.contains('.')
                ? pickedFile.name.substring(0, pickedFile.name.lastIndexOf('.'))
                : pickedFile.name;
            _titleController.text = fileNameWithoutExt;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã chọn: ${pickedFile.name}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở bộ chọn file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Dán đường dẫn từ Clipboard
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && mounted) {
      setState(() {
        _filePathController.text = data!.text!.trim();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã dán đường dẫn từ clipboard!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  /// Lưu tài liệu (thêm mới hoặc cập nhật)
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final docStruct = context.read<DocumentStruct>();

      if (widget.isEditing) {
        // Cập nhật tài liệu
        await docStruct.update(
          id: widget.documentId!,
          title: _titleController.text,
          description: _descriptionController.text,
          type: _selectedType,
          subject: _subjectController.text,
          filePath: _filePathController.text,
          categoryId: _selectedCategoryId,
        );
      } else {
        // Thêm mới
        await docStruct.create(
          title: _titleController.text,
          description: _descriptionController.text,
          type: _selectedType,
          subject: _subjectController.text,
          filePath: _filePathController.text,
          categoryId: _selectedCategoryId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Đã cập nhật tài liệu'
                  : 'Đã thêm tài liệu mới',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Load dữ liệu khi ở mode sửa
    if (widget.isEditing && !_isInitialized) {
      _loadDocument();
    }

    return AppScaffold(
      title: widget.isEditing ? 'Sửa tài liệu' : 'Thêm tài liệu',
      actions: [
        IconButton(
          onPressed: _isLoading ? null : _save,
          icon: const Icon(Icons.check),
          tooltip: 'Lưu',
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // === Tiêu đề ===
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề *',
                      hintText: 'Nhập tiêu đề tài liệu',
                      prefixIcon: Icon(Icons.title),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tiêu đề';
                      }
                      if (value.trim().length > 200) {
                        return 'Tiêu đề không được quá 200 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // === Mô tả ===
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      hintText: 'Nhập mô tả (tùy chọn)',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // === Loại tài liệu ===
                  DropdownButtonFormField<DocumentType>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Loại tài liệu *',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: DocumentType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // === Môn học ===
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Môn học *',
                      hintText: 'Nhập tên môn học',
                      prefixIcon: Icon(Icons.subject),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập môn học';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // === Nút chọn file từ thiết bị (Hỗ trợ Android Native File Picker) ===
                  Card(
                    elevation: 0,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.attach_file,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Tệp đính kèm (File tài liệu)',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Nút bấm mở File Picker của Android
                          FilledButton.tonalIcon(
                            onPressed: _pickFileFromDevice,
                            icon: const Icon(Icons.folder_open),
                            label: const Text(
                              'Chọn file từ bộ nhớ máy (Android)',
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Ô nhập/hiển thị đường dẫn file
                          TextFormField(
                            controller: _filePathController,
                            decoration: InputDecoration(
                              labelText: 'Đường dẫn file (Local hoặc Online)',
                              hintText:
                                  'VD: /storage/emulated/0/... hoặc link Drive',
                              prefixIcon: const Icon(Icons.link),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_filePathController.text.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      tooltip: 'Xóa đường dẫn',
                                      onPressed: () {
                                        setState(() {
                                          _filePathController.clear();
                                        });
                                      },
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.paste, size: 18),
                                    tooltip: 'Dán link từ clipboard',
                                    onPressed: _pasteFromClipboard,
                                  ),
                                ],
                              ),
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '💡 Mẹo: Bấm nút trên để chọn file PDF/Doc trong máy, hoặc dán link Google Drive nếu lưu trên đám mây.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // === Danh mục (dropdown từ stream) ===
                  StreamBuilder<List<CategoryModel>>(
                    stream: context.read<CategoryStruct>().watchAll(),
                    builder: (context, snapshot) {
                      final categories = snapshot.data ?? [];
                      return DropdownButtonFormField<String?>(
                        initialValue: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Danh mục',
                          prefixIcon: Icon(Icons.folder),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Không có danh mục'),
                          ),
                          ...categories.map(
                            (cat) => DropdownMenuItem(
                              value: cat.id,
                              child: Text(cat.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedCategoryId = value);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // === Nút lưu ===
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _save,
                    icon: Icon(widget.isEditing ? Icons.save : Icons.add),
                    label: Text(
                      widget.isEditing ? 'Cập nhật' : 'Thêm tài liệu',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
