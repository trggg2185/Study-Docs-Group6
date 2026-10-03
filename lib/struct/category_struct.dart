import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../modified/models/category_model.dart';
import '../modified/converters/document_converter.dart';

/// Business logic cho danh mục - tầng struct
class CategoryStruct {
  final AppDatabase _db;
  final _uuid = const Uuid();

  CategoryStruct(this._db);

  /// Lấy tất cả danh mục (reactive)
  Stream<List<CategoryModel>> watchAll() {
    return _db.watchAllCategories().map(DocumentConverter.categoriesFromEntries);
  }

  /// Lấy tất cả danh mục (one-shot)
  Future<List<CategoryModel>> getAll() async {
    final entries = await _db.getAllCategories();
    return DocumentConverter.categoriesFromEntries(entries);
  }

  /// Thêm danh mục mới
  Future<String> create({
    required String name,
    String description = '',
    String color = '#2196F3',
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Tên danh mục không được để trống');
    }

    final id = _uuid.v4();
    await _db.insertCategory(CategoriesCompanion.insert(
      id: id,
      name: name.trim(),
      description: Value(description.trim()),
      color: Value(color),
    ));

    return id;
  }

  /// Xóa danh mục
  Future<bool> deleteById(String id) async {
    final result = await _db.deleteCategory(id);
    return result > 0;
  }
}
