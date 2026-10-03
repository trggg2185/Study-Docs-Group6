import '../database/app_database.dart';
import '../modified/models/document_model.dart';
import '../modified/converters/document_converter.dart';

/// Business logic cho tìm kiếm và lọc tài liệu
/// Gọi database layer, trả về Stream cho UI
class SearchStruct {
  final AppDatabase _db;

  SearchStruct(this._db);

  /// Tìm kiếm tài liệu với các bộ lọc
  /// - query: từ khóa tìm theo tiêu đề
  /// - type: lọc theo loại (lecture/exercise/reference)
  /// - subject: lọc theo môn học
  Stream<List<DocumentModel>> search({
    String? query,
    DocumentType? type,
    String? subject,
  }) {
    return _db
        .searchDocuments(
          query: query,
          type: type?.name,
          subject: subject,
        )
        .map(DocumentConverter.fromEntries);
  }

  /// Lấy danh sách các môn học duy nhất từ DB
  /// Dùng để hiển thị bộ lọc trong UI
  Stream<List<String>> watchDistinctSubjects() {
    // Lấy tất cả tài liệu rồi extract subjects duy nhất
    return _db.watchAllDocuments().map((entries) {
      final subjects = entries.map((e) => e.subject).toSet().toList();
      subjects.sort();
      return subjects;
    });
  }
}
