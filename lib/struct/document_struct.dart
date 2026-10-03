import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../modified/models/document_model.dart';
import '../modified/converters/document_converter.dart';

/// Business logic cho tài liệu - tầng struct theo kiến trúc Cashew
/// Chỉ expose Future/Stream, UI gọi qua Provider
/// KHÔNG import Flutter widgets
class DocumentStruct {
  final AppDatabase _db;
  final _uuid = const Uuid();

  DocumentStruct(this._db);

  // === REACTIVE STREAMS (UI dùng StreamBuilder) ===

  /// Lấy tất cả tài liệu dạng stream reactive
  Stream<List<DocumentModel>> watchAll() {
    return _db.watchAllDocuments().map(DocumentConverter.fromEntries);
  }

  /// Theo dõi một tài liệu cụ thể
  Stream<DocumentModel?> watchById(String id) {
    return _db.watchDocumentById(id).map(
      (entry) => entry != null ? DocumentConverter.fromEntry(entry) : null,
    );
  }

  /// Đếm số tài liệu theo loại (reactive)
  Stream<int> watchCountByType(DocumentType type) {
    return _db.watchDocumentCountByType(type.name);
  }

  /// Đếm tổng số tài liệu
  Stream<int> watchTotalCount() {
    return _db.watchTotalDocumentCount();
  }

  // === CRUD OPERATIONS ===

  /// Thêm tài liệu mới với validation
  Future<String> create({
    required String title,
    String description = '',
    required DocumentType type,
    required String subject,
    String filePath = '',
    String? categoryId,
  }) async {
    // Validation
    _validateTitle(title);
    _validateSubject(subject);

    final id = _uuid.v4();
    final now = DateTime.now();

    await _db.insertDocument(DocumentsCompanion.insert(
      id: id,
      title: title.trim(),
      description: Value(description.trim()),
      type: type.name,
      subject: subject.trim(),
      filePath: Value(filePath.trim()),
      categoryId: Value(categoryId),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));

    return id; // Trả về ID để UI có thể navigate
  }

  /// Cập nhật tài liệu
  Future<bool> update({
    required String id,
    required String title,
    String description = '',
    required DocumentType type,
    required String subject,
    String filePath = '',
    String? categoryId,
  }) async {
    // Validation
    _validateTitle(title);
    _validateSubject(subject);

    return _db.updateDocument(DocumentsCompanion(
      id: Value(id),
      title: Value(title.trim()),
      description: Value(description.trim()),
      type: Value(type.name),
      subject: Value(subject.trim()),
      filePath: Value(filePath.trim()),
      categoryId: Value(categoryId),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Xóa tài liệu theo ID
  Future<bool> deleteById(String id) async {
    final result = await _db.deleteDocument(id);
    return result > 0;
  }

  /// Lấy một tài liệu (one-shot, không reactive)
  Future<DocumentModel?> getById(String id) async {
    final entry = await _db.getDocumentById(id);
    return entry != null ? DocumentConverter.fromEntry(entry) : null;
  }

  // === VALIDATION ===

  void _validateTitle(String title) {
    if (title.trim().isEmpty) {
      throw ArgumentError('Tiêu đề không được để trống');
    }
    if (title.trim().length > 200) {
      throw ArgumentError('Tiêu đề không được quá 200 ký tự');
    }
  }

  void _validateSubject(String subject) {
    if (subject.trim().isEmpty) {
      throw ArgumentError('Môn học không được để trống');
    }
  }
}
