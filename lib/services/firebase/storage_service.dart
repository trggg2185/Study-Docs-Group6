import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

/// Dịch vụ quản lý lưu trữ tệp trên Firebase Cloud Storage
/// Phụ trách: Nguyễn Đăng Đại
class StorageService {
  final FirebaseStorage? _customStorage;

  StorageService({FirebaseStorage? storage}) : _customStorage = storage;

  FirebaseStorage get _storage => _customStorage ?? FirebaseStorage.instance;

  /// Upload tệp từ đường dẫn File cục bộ lên Firebase Cloud Storage
  /// - [file]: Đối tượng tệp tin cần tải lên
  /// - [userId]: ID của người dùng sở hữu (đảm bảo phân quyền thư mục)
  /// - [onProgress]: Callback nhận tỷ lệ tiến trình từ 0.0 đến 1.0 (cho UI ProgressBar)
  /// - [customFileName]: Tên file tuỳ chỉnh (nếu null sẽ lấy tên file gốc)
  /// Trả về: URL tải xuống công khai/xác thực của tệp
  Future<String> uploadFile({
    required File file,
    required String userId,
    void Function(double progress)? onProgress,
    String? customFileName,
  }) async {
    try {
      if (!await file.exists()) {
        throw ArgumentError('Tệp tin không tồn tại trên bộ nhớ máy: ${file.path}');
      }

      final originalName = customFileName ?? p.basename(file.path);
      final sanitizedName = originalName.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
      final storagePath = 'documents/$userId/$fileName';

      final ref = _storage.ref().child(storagePath);

      // Thiết lập metadata theo định dạng tệp
      final metadata = SettableMetadata(
        contentType: _resolveContentType(originalName),
        customMetadata: {
          'uploadedBy': userId,
          'originalName': originalName,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = ref.putFile(file, metadata);

      // Lắng nghe tiến trình upload
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (snapshot.totalBytes > 0) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(progress);
          }
        });
      }

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('Lỗi Firebase Storage khi tải tệp [${e.code}]: ${e.message}');
    } catch (e) {
      throw Exception('Không thể tải tệp lên Cloud Storage: $e');
    }
  }

  /// Upload dữ liệu nhị phân (Uint8List bytes) - Hỗ trợ Flutter Web
  Future<String> uploadBytes({
    required Uint8List bytes,
    required String fileName,
    required String userId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final sanitizedName = fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
      final storagePath = 'documents/$userId/$uniqueName';

      final ref = _storage.ref().child(storagePath);
      final metadata = SettableMetadata(
        contentType: _resolveContentType(fileName),
        customMetadata: {
          'uploadedBy': userId,
          'originalName': fileName,
        },
      );

      final uploadTask = ref.putData(bytes, metadata);

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          if (snapshot.totalBytes > 0) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(progress);
          }
        });
      }

      await uploadTask;
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception('Lỗi Firebase Storage (Bytes) [${e.code}]: ${e.message}');
    } catch (e) {
      throw Exception('Không thể tải dữ liệu lên Cloud Storage: $e');
    }
  }

  /// Xóa tệp trên Cloud Storage dựa vào downloadUrl
  Future<void> deleteFile(String downloadUrl) async {
    if (downloadUrl.trim().isEmpty) return;
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      // Bỏ qua nếu tệp đã bị xóa trước đó (object-not-found)
      if (e.code != 'object-not-found') {
        throw Exception('Lỗi khi xóa tệp trên Cloud Storage [${e.code}]: ${e.message}');
      }
    } catch (e) {
      throw Exception('Không thể xóa tệp Cloud Storage: $e');
    }
  }

  /// Xóa tệp dựa theo đường dẫn tương đối trong bucket (vd: 'documents/user123/file.pdf')
  Future<void> deleteFileByPath(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        throw Exception('Lỗi khi xóa tệp theo đường dẫn [${e.code}]: ${e.message}');
      }
    } catch (e) {
      throw Exception('Không thể xóa tệp Cloud Storage: $e');
    }
  }

  /// Tự động nhận diện MIME type từ phần mở rộng file
  String _resolveContentType(String filename) {
    final ext = p.extension(filename).toLowerCase();
    switch (ext) {
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.ppt':
        return 'application/vnd.ms-powerpoint';
      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
