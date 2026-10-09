import 'package:cloud_firestore/cloud_firestore.dart';
import '../../modified/models/document_model.dart';

/// Dịch vụ quản lý dữ liệu Metadata tài liệu trên Cloud Firestore
/// Phụ trách: Nguyễn Đăng Đại
class FirestoreService {
  final FirebaseFirestore? _customDb;
  static const String collectionName = 'documents';

  FirestoreService({FirebaseFirestore? firestore}) : _customDb = firestore;

  FirebaseFirestore get _db => _customDb ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(collectionName);

  /// Thêm tài liệu mới vào Firestore
  /// Trả về ID của tài liệu mới được tạo
  Future<String> addDocument(DocumentModel doc) async {
    try {
      final docMap = doc.toMap();
      // Sử dụng FieldValue.serverTimestamp() để đảm bảo tính đồng bộ thời gian tuyệt đối từ máy chủ Google
      docMap['createdAt'] = FieldValue.serverTimestamp();
      docMap['updatedAt'] = FieldValue.serverTimestamp();

      if (doc.id.isNotEmpty) {
        await _collection.doc(doc.id).set(docMap);
        return doc.id;
      } else {
        final docRef = await _collection.add(docMap);
        return docRef.id;
      }
    } on FirebaseException catch (e) {
      throw Exception('Lỗi Firestore khi tạo tài liệu [${e.code}]: ${e.message}');
    } catch (e) {
      throw Exception('Không thể thêm tài liệu vào Firestore: $e');
    }
  }

  /// Cập nhật thông tin tài liệu
  Future<void> updateDocument(String docId, Map<String, dynamic> updates) async {
    try {
      final dataToUpdate = Map<String, dynamic>.from(updates);
      dataToUpdate['updatedAt'] = FieldValue.serverTimestamp();
      await _collection.doc(docId).update(dataToUpdate);
    } on FirebaseException catch (e) {
      throw Exception('Lỗi Firestore khi cập nhật [${e.code}]: ${e.message}');
    } catch (e) {
      throw Exception('Không thể cập nhật tài liệu: $e');
    }
  }

  /// Xóa tài liệu khỏi Firestore theo ID
  Future<void> deleteDocument(String docId) async {
    try {
      await _collection.doc(docId).delete();
    } on FirebaseException catch (e) {
      throw Exception('Lỗi Firestore khi xóa [${e.code}]: ${e.message}');
    } catch (e) {
      throw Exception('Không thể xóa tài liệu trên Firestore: $e');
    }
  }

  /// Lấy thông tin một tài liệu theo ID (Future một lần)
  Future<DocumentModel?> getDocument(String docId) async {
    try {
      final snapshot = await _collection.doc(docId).get();
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return _mapSnapshotToModel(snapshot);
    } on FirebaseException catch (e) {
      throw Exception('Lỗi Firestore khi tải tài liệu [${e.code}]: ${e.message}');
    } catch (e) {
      throw Exception('Không thể lấy tài liệu: $e');
    }
  }

  /// Lắng nghe danh sách tài liệu của người dùng theo thời gian thực (Real-time Stream)
  /// - [ownerId]: UID của người dùng đăng nhập hiện tại
  Stream<List<DocumentModel>> watchDocumentsByOwner(String ownerId) {
    return _collection
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(_mapSnapshotToModel).toList();
    });
  }

  /// Lắng nghe danh sách tài liệu có bộ lọc (Loại tài liệu hoặc Môn học)
  Stream<List<DocumentModel>> watchDocumentsFiltered({
    required String ownerId,
    DocumentType? type,
    String? subject,
  }) {
    Query<Map<String, dynamic>> query = _collection.where('ownerId', isEqualTo: ownerId);

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }
    if (subject != null && subject.trim().isNotEmpty) {
      query = query.where('subject', isEqualTo: subject.trim());
    }

    query = query.orderBy('updatedAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map(_mapSnapshotToModel).toList();
    });
  }

  /// Đếm tổng số tài liệu của người dùng (tận dụng Count Query tiết kiệm chi phí đọc của Firestore)
  Future<int> countDocuments(String ownerId) async {
    try {
      final countQuery = _collection.where('ownerId', isEqualTo: ownerId).count();
      final aggregateSnapshot = await countQuery.get();
      return aggregateSnapshot.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Helper chuyển DocumentSnapshot thành DocumentModel
  DocumentModel _mapSnapshotToModel(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime createdAt = DateTime.now();
    DateTime updatedAt = DateTime.now();

    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    }
    if (data['updatedAt'] is Timestamp) {
      updatedAt = (data['updatedAt'] as Timestamp).toDate();
    }

    return DocumentModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: DocumentType.fromString(data['type'] as String? ?? 'reference'),
      subject: data['subject'] as String? ?? '',
      filePath: data['filePath'] as String? ?? '',
      fileUrl: data['fileUrl'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      fileSize: data['fileSize'] as int?,
      categoryId: data['categoryId'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
