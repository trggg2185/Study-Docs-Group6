import 'package:drift/drift.dart';

/// Bảng tài liệu (documents) - lưu bài giảng, bài tập, tài liệu tham khảo
@DataClassName('DocumentEntry')
class Documents extends Table {
  // ID dạng text (UUID)
  TextColumn get id => text()();

  // Tiêu đề tài liệu
  TextColumn get title => text().withLength(min: 1, max: 200)();

  // Mô tả chi tiết
  TextColumn get description => text().withDefault(const Constant(''))();

  // Loại tài liệu: lecture (bài giảng), exercise (bài tập), reference (tham khảo)
  TextColumn get type => text().withLength(min: 1, max: 20)();

  // Tên môn học
  TextColumn get subject => text().withLength(min: 1, max: 100)();

  // Đường dẫn file (string, không upload thật)
  TextColumn get filePath => text().withDefault(const Constant(''))();

  // FK tới bảng categories (tùy chọn)
  TextColumn get categoryId => text().nullable()();

  // Ngày tạo
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // Ngày cập nhật
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
