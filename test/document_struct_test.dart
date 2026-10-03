import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:test_flutter/database/app_database.dart';
import 'package:test_flutter/struct/document_struct.dart';
import 'package:test_flutter/modified/models/document_model.dart';

void main() {
  late AppDatabase db;
  late DocumentStruct documentStruct;

  setUp(() {
    // Tạo DB in-memory cho testing
    db = AppDatabase.forTesting(NativeDatabase.memory());
    documentStruct = DocumentStruct(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DocumentStruct', () {
    test('create() - thêm tài liệu mới thành công', () async {
      final id = await documentStruct.create(
        title: 'Bài giảng Dart cơ bản',
        description: 'Giới thiệu về ngôn ngữ Dart',
        type: DocumentType.lecture,
        subject: 'Lập trình Dart',
        filePath: '/docs/dart_intro.pdf',
      );

      // Kiểm tra ID được trả về
      expect(id, isNotEmpty);

      // Kiểm tra tài liệu đã được lưu vào DB
      final doc = await documentStruct.getById(id);
      expect(doc, isNotNull);
      expect(doc!.title, 'Bài giảng Dart cơ bản');
      expect(doc.type, DocumentType.lecture);
      expect(doc.subject, 'Lập trình Dart');
    });

    test('create() - validation từ chối tiêu đề rỗng', () async {
      expect(
        () => documentStruct.create(
          title: '',
          type: DocumentType.exercise,
          subject: 'Toán',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('create() - validation từ chối môn học rỗng', () async {
      expect(
        () => documentStruct.create(
          title: 'Bài tập 1',
          type: DocumentType.exercise,
          subject: '   ', // chỉ có spaces
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('update() - cập nhật tài liệu', () async {
      // Tạo tài liệu trước
      final id = await documentStruct.create(
        title: 'Tài liệu gốc',
        type: DocumentType.reference,
        subject: 'Toán',
      );

      // Cập nhật
      final updated = await documentStruct.update(
        id: id,
        title: 'Tài liệu đã sửa',
        type: DocumentType.lecture,
        subject: 'Toán cao cấp',
      );

      expect(updated, isTrue);

      // Kiểm tra dữ liệu đã thay đổi
      final doc = await documentStruct.getById(id);
      expect(doc!.title, 'Tài liệu đã sửa');
      expect(doc.type, DocumentType.lecture);
      expect(doc.subject, 'Toán cao cấp');
    });

    test('deleteById() - xóa tài liệu', () async {
      final id = await documentStruct.create(
        title: 'Tài liệu sẽ bị xóa',
        type: DocumentType.exercise,
        subject: 'Vật lý',
      );

      // Xóa
      final deleted = await documentStruct.deleteById(id);
      expect(deleted, isTrue);

      // Kiểm tra đã bị xóa
      final doc = await documentStruct.getById(id);
      expect(doc, isNull);
    });

    test('watchAll() - stream phát dữ liệu reactive', () async {
      // Lắng nghe stream
      final stream = documentStruct.watchAll();

      // Ban đầu có thể có seed data, thêm 1 tài liệu
      await documentStruct.create(
        title: 'Tài liệu stream test',
        type: DocumentType.lecture,
        subject: 'CNTT',
      );

      // Stream phải phát ra danh sách chứa tài liệu vừa thêm
      final docs = await stream.first;
      expect(docs, isNotEmpty);
      expect(docs.any((d) => d.title == 'Tài liệu stream test'), isTrue);
    });
  });
}
