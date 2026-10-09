import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_flutter/modified/models/document_model.dart';
import 'package:test_flutter/struct/cloud_document_struct.dart';

void main() {
  group('DocumentModel Cloud Serialization Tests', () {
    test('toMap() and fromMap() serialize properly with cloud fields', () {
      final now = DateTime(2026, 10, 9, 12, 0, 0);
      final model = DocumentModel(
        id: 'doc-123',
        title: 'Lập trình Android với Flutter',
        description: 'Tài liệu môn học tổng hợp',
        type: DocumentType.lecture,
        subject: 'Lập trình Di Động',
        filePath: '/storage/emulated/0/Download/flutter.pdf',
        fileUrl: 'https://firebasestorage.googleapis.com/v0/b/app/o/flutter.pdf',
        ownerId: 'user_xyz_789',
        fileSize: 1048576,
        categoryId: 'cat-mobile',
        createdAt: now,
        updatedAt: now,
      );

      final map = model.toMap();
      expect(map['title'], 'Lập trình Android với Flutter');
      expect(map['type'], 'lecture');
      expect(map['fileUrl'], 'https://firebasestorage.googleapis.com/v0/b/app/o/flutter.pdf');
      expect(map['ownerId'], 'user_xyz_789');
      expect(map['fileSize'], 1048576);

      final restored = DocumentModel.fromMap(map, id: 'doc-123');
      expect(restored.id, 'doc-123');
      expect(restored.title, model.title);
      expect(restored.type, DocumentType.lecture);
      expect(restored.subject, model.subject);
      expect(restored.fileUrl, model.fileUrl);
      expect(restored.ownerId, model.ownerId);
      expect(restored.fileSize, model.fileSize);
    });

    test('fromMap() handles missing optional fields gracefully', () {
      final minimalMap = {
        'title': 'Đề cương ôn tập',
        'subject': 'Hệ điều hành',
      };

      final doc = DocumentModel.fromMap(minimalMap, id: 'doc-minimal');
      expect(doc.id, 'doc-minimal');
      expect(doc.title, 'Đề cương ôn tập');
      expect(doc.type, DocumentType.reference); // Default fallback
      expect(doc.fileUrl, '');
      expect(doc.ownerId, '');
      expect(doc.fileSize, isNull);
    });
  });

  group('CloudDocumentStruct Validation Tests', () {
    test('Validation rejects empty title', () async {
      final struct = CloudDocumentStruct();
      final tempFile = File('dummy.pdf');

      expect(
        () => struct.createWithFile(
          title: '',
          type: DocumentType.lecture,
          subject: 'Toán rời rạc',
          file: tempFile,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Validation rejects empty subject', () async {
      final struct = CloudDocumentStruct();
      final tempFile = File('dummy.pdf');

      expect(
        () => struct.createWithFile(
          title: 'Slide bài giảng',
          type: DocumentType.lecture,
          subject: '   ',
          file: tempFile,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
