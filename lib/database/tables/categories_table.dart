import 'package:drift/drift.dart';

/// Bảng danh mục (categories) - lưu các môn học / nhóm tài liệu
@DataClassName('CategoryEntry')
class Categories extends Table {
  // ID dạng text (UUID)
  TextColumn get id => text()();

  // Tên danh mục (vd: "Toán cao cấp", "Lập trình Dart")
  TextColumn get name => text().withLength(min: 1, max: 100)();

  // Mô tả ngắn (tùy chọn)
  TextColumn get description => text().withDefault(const Constant(''))();

  // Màu sắc hiển thị (lưu dạng hex string, vd: "#FF5722")
  TextColumn get color => text().withDefault(const Constant('#2196F3'))();

  // Ngày tạo
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
