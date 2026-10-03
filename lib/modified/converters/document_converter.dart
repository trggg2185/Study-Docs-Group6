import '../../database/app_database.dart';
import '../models/document_model.dart';
import '../models/category_model.dart';

/// Converter (mapper) giữa Drift row và Model
/// Tầng này đảm bảo tầng struct không cần biết chi tiết Drift
class DocumentConverter {
  /// Chuyển từ Drift DocumentEntry → DocumentModel
  static DocumentModel fromEntry(DocumentEntry entry) {
    return DocumentModel(
      id: entry.id,
      title: entry.title,
      description: entry.description,
      type: DocumentType.fromString(entry.type),
      subject: entry.subject,
      filePath: entry.filePath,
      categoryId: entry.categoryId,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  /// Chuyển danh sách Drift rows → danh sách Models
  static List<DocumentModel> fromEntries(List<DocumentEntry> entries) {
    return entries.map(fromEntry).toList();
  }

  /// Chuyển từ Drift CategoryEntry → CategoryModel
  static CategoryModel categoryFromEntry(CategoryEntry entry) {
    return CategoryModel(
      id: entry.id,
      name: entry.name,
      description: entry.description,
      color: entry.color,
      createdAt: entry.createdAt,
    );
  }

  /// Chuyển danh sách Category entries → models
  static List<CategoryModel> categoriesFromEntries(List<CategoryEntry> entries) {
    return entries.map(categoryFromEntry).toList();
  }
}
