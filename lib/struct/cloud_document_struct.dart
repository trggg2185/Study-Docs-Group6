import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../modified/models/document_model.dart';
import '../services/firebase/firestore_service.dart';
import '../services/firebase/storage_service.dart';

/// Business logic tích hợp Cloud cho tài liệu - tầng struct theo kiến trúc Cashew
/// Điều phối giữa Firebase Storage, Cloud Firestore và Firebase Auth
/// Phụ trách: Nguyễn Đăng Đại
class CloudDocumentStruct {
  final FirestoreService _firestoreService;
  final StorageService _storageService;
  final FirebaseAuth? _customAuth;

  CloudDocumentStruct({
    FirestoreService? firestoreService,
    StorageService? storageService,
    FirebaseAuth? auth,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _storageService = storageService ?? StorageService(),
        _customAuth = auth;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  String? get currentUserId => _auth.currentUser?.uid;

  /// Lắng nghe toàn bộ tài liệu của người dùng hiện tại theo thời gian thực
  Stream<List<DocumentModel>> watchAll() {
    final uid = currentUserId;
    if (uid == null) {
      return Stream.value([]);
    }
    return _firestoreService.watchDocumentsByOwner(uid);
  }

  /// Lắng nghe tài liệu có lọc theo môn hoặc loại tài liệu
  Stream<List<DocumentModel>> watchFiltered({
    DocumentType? type,
    String? subject,
  }) {
    final uid = currentUserId;
    if (uid == null) {
      return Stream.value([]);
    }
    return _firestoreService.watchDocumentsFiltered(
      ownerId: uid,
      type: type,
      subject: subject,
    );
  }

  /// Lấy chi tiết một tài liệu
  Future<DocumentModel?> getById(String id) {
    return _firestoreService.getDocument(id);
  }

  /// Thêm tài liệu mới kèm tệp tin lên Cloud
  /// Thực hiện quy trình 2 bước với cơ chế bù trừ Rollback để chống Orphaned Files
  Future<String> createWithFile({
    required String title,
    String description = '',
    required DocumentType type,
    required String subject,
    required File file,
    String? categoryId,
    void Function(double progress)? onProgress,
  }) async {
    _validateTitle(title);
    _validateSubject(subject);

    final uid = currentUserId;
    if (uid == null) {
      throw StateError('Người dùng chưa đăng nhập. Vui lòng đăng nhập trước khi tải lên.');
    }

    // Bước 1: Upload file lên Cloud Storage
    String downloadUrl = '';
    try {
      downloadUrl = await _storageService.uploadFile(
        file: file,
        userId: uid,
        onProgress: onProgress,
      );
    } catch (e) {
      throw Exception('Lỗi khi tải tệp lên Cloud Storage: $e');
    }

    // Bước 2: Lưu metadata vào Cloud Firestore
    try {
      final now = DateTime.now();
      final docModel = DocumentModel(
        id: '', // Firestore sẽ tự tạo ID
        title: title.trim(),
        description: description.trim(),
        type: type,
        subject: subject.trim(),
        filePath: file.path,
        fileUrl: downloadUrl,
        ownerId: uid,
        fileSize: await file.length(),
        categoryId: categoryId,
        createdAt: now,
        updatedAt: now,
      );

      final docId = await _firestoreService.addDocument(docModel);
      return docId;
    } catch (firestoreError) {
      // Rollback: Nếu lưu metadata vào Firestore thất bại, lập tức xóa file vừa upload trên Storage
      // nhằm tránh rác dữ liệu (Orphaned file) gây tốn dung lượng
      try {
        await _storageService.deleteFile(downloadUrl);
      } catch (_) {
        // Log rollback error
      }
      throw Exception('Lưu tài liệu vào Firestore thất bại (đã dọn dẹp file): $firestoreError');
    }
  }

  /// Cập nhật thông tin metadata của tài liệu
  Future<void> update({
    required String id,
    required String title,
    String description = '',
    required DocumentType type,
    required String subject,
    String? categoryId,
  }) async {
    _validateTitle(title);
    _validateSubject(subject);

    await _firestoreService.updateDocument(id, {
      'title': title.trim(),
      'description': description.trim(),
      'type': type.name,
      'subject': subject.trim(),
      'categoryId': categoryId,
    });
  }

  /// Xóa tài liệu đồng bộ cả Firestore và Cloud Storage
  Future<void> delete(String docId, {String? fileUrl}) async {
    // 1. Xóa metadata trên Firestore
    await _firestoreService.deleteDocument(docId);

    // 2. Xóa file tương ứng trên Cloud Storage nếu có URL
    if (fileUrl != null && fileUrl.trim().isNotEmpty) {
      await _storageService.deleteFile(fileUrl);
    }
  }

  // === VALIDATION PRIVATE HELPERS ===

  void _validateTitle(String title) {
    if (title.trim().isEmpty) {
      throw ArgumentError('Tiêu đề tài liệu không được để trống');
    }
    if (title.trim().length > 200) {
      throw ArgumentError('Tiêu đề không được vượt quá 200 ký tự');
    }
  }

  void _validateSubject(String subject) {
    if (subject.trim().isEmpty) {
      throw ArgumentError('Môn học không được để trống');
    }
    if (subject.trim().length > 100) {
      throw ArgumentError('Tên môn học không được vượt quá 100 ký tự');
    }
  }
}
