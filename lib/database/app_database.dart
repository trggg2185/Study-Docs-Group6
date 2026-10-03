import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/documents_table.dart';
import 'tables/categories_table.dart';

part 'app_database.g.dart';

/// Database chính của ứng dụng StudyDocs
/// Sử dụng Drift ORM với SQLite, offline-first theo kiến trúc Cashew
@DriftDatabase(tables: [Documents, Categories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Constructor cho testing - cho phép inject QueryExecutor
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Tạo dữ liệu mẫu khi khởi tạo DB lần đầu
        await _seedData();
      },
    );
  }

  /// Dữ liệu mẫu ban đầu
  Future<void> _seedData() async {
    // Tạo vài category mẫu
    await into(categories).insert(
      CategoriesCompanion.insert(
        id: 'cat-001',
        name: 'Lập trình',
        description: const Value('Các môn lập trình'),
        color: const Value('#4CAF50'),
      ),
    );
    await into(categories).insert(
      CategoriesCompanion.insert(
        id: 'cat-002',
        name: 'Toán học',
        description: const Value('Các môn toán'),
        color: const Value('#FF9800'),
      ),
    );
    await into(categories).insert(
      CategoriesCompanion.insert(
        id: 'cat-003',
        name: 'Ngoại ngữ',
        description: const Value('Các môn ngoại ngữ'),
        color: const Value('#2196F3'),
      ),
    );
  }

  // === DOCUMENT DAO METHODS ===

  /// Lấy tất cả tài liệu (reactive stream) - đọc foreground
  Stream<List<DocumentEntry>> watchAllDocuments() {
    return (select(documents)..orderBy([
          (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  /// Lấy một tài liệu theo ID
  Future<DocumentEntry?> getDocumentById(String id) {
    return (select(documents)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Stream theo dõi một tài liệu theo ID
  Stream<DocumentEntry?> watchDocumentById(String id) {
    return (select(
      documents,
    )..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  /// Thêm tài liệu mới - ghi background
  Future<int> insertDocument(DocumentsCompanion entry) {
    return into(documents).insert(entry);
  }

  /// Cập nhật tài liệu
  Future<bool> updateDocument(DocumentsCompanion entry) {
    return (update(documents)..where((t) => t.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  /// Xóa tài liệu theo ID
  Future<int> deleteDocument(String id) {
    return (delete(documents)..where((t) => t.id.equals(id))).go();
  }

  /// Tìm kiếm tài liệu theo tiêu đề
  Stream<List<DocumentEntry>> searchDocuments({
    String? query,
    String? type,
    String? subject,
  }) {
    return (select(documents)
          ..where((t) {
            Expression<bool> condition = const Constant(true);
            if (query != null && query.isNotEmpty) {
              condition =
                  condition & t.title.lower().like('%${query.toLowerCase()}%');
            }
            if (type != null && type.isNotEmpty) {
              condition = condition & t.type.equals(type);
            }
            if (subject != null && subject.isNotEmpty) {
              condition =
                  condition &
                  t.subject.lower().like('%${subject.toLowerCase()}%');
            }
            return condition;
          })
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Đếm số tài liệu theo loại (reactive)
  Stream<int> watchDocumentCountByType(String type) {
    final countExpr = documents.id.count();
    final query = selectOnly(documents)
      ..addColumns([countExpr])
      ..where(documents.type.equals(type));
    return query.map((row) => row.read(countExpr) ?? 0).watchSingle();
  }

  /// Đếm tổng số tài liệu
  Stream<int> watchTotalDocumentCount() {
    final countExpr = documents.id.count();
    final query = selectOnly(documents)..addColumns([countExpr]);
    return query.map((row) => row.read(countExpr) ?? 0).watchSingle();
  }

  // === CATEGORY DAO METHODS ===

  /// Lấy tất cả danh mục (reactive)
  Stream<List<CategoryEntry>> watchAllCategories() {
    return (select(
      categories,
    )..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  /// Lấy tất cả danh mục (one-shot)
  Future<List<CategoryEntry>> getAllCategories() {
    return (select(
      categories,
    )..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  }

  /// Thêm danh mục
  Future<int> insertCategory(CategoriesCompanion entry) {
    return into(categories).insert(entry);
  }

  /// Xóa danh mục
  Future<int> deleteCategory(String id) {
    return (delete(categories)..where((t) => t.id.equals(id))).go();
  }

  /// Mở kết nối DB - sử dụng drift_flutter hỗ trợ cả Native và Web
  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'studydocs_db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}
