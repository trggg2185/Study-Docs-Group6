/// Model thuần Dart cho tài liệu - không phụ thuộc vào Drift hay Flutter
/// Đây là DTO dùng để truyền dữ liệu giữa các tầng
class DocumentModel {
  final String id;
  final String title;
  final String description;
  final DocumentType type;
  final String subject;
  final String filePath;
  final String? categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String fileUrl;
  final String ownerId;
  final int? fileSize;

  const DocumentModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.type,
    required this.subject,
    this.filePath = '',
    this.categoryId,
    required this.createdAt,
    required this.updatedAt,
    this.fileUrl = '',
    this.ownerId = '',
    this.fileSize,
  });

  /// Copy với các trường được thay đổi
  DocumentModel copyWith({
    String? id,
    String? title,
    String? description,
    DocumentType? type,
    String? subject,
    String? filePath,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fileUrl,
    String? ownerId,
    int? fileSize,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      filePath: filePath ?? this.filePath,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fileUrl: fileUrl ?? this.fileUrl,
      ownerId: ownerId ?? this.ownerId,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  /// Chuyển model thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'subject': subject,
      'filePath': filePath,
      'fileUrl': fileUrl,
      'ownerId': ownerId,
      'fileSize': fileSize,
      'categoryId': categoryId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Tạo model từ Map (Firestore data)
  factory DocumentModel.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      // Nếu là Firestore Timestamp: gọi toDate() thông qua reflection/dynamic
      try {
        final dynamic ts = value;
        if (ts.toDate != null) return ts.toDate() as DateTime;
      } catch (_) {}
      return DateTime.now();
    }

    return DocumentModel(
      id: id ?? (map['id'] as String? ?? ''),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      type: DocumentType.fromString(map['type'] as String? ?? 'reference'),
      subject: map['subject'] as String? ?? '',
      filePath: map['filePath'] as String? ?? '',
      fileUrl: map['fileUrl'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      fileSize: map['fileSize'] as int?,
      categoryId: map['categoryId'] as String?,
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
    );
  }

  @override
  String toString() => 'DocumentModel(id: $id, title: $title, type: $type, fileUrl: $fileUrl)';
}

/// Enum loại tài liệu
enum DocumentType {
  lecture,   // Bài giảng
  exercise,  // Bài tập
  reference; // Tài liệu tham khảo

  /// Tên hiển thị tiếng Việt
  String get displayName {
    switch (this) {
      case DocumentType.lecture:
        return 'Bài giảng';
      case DocumentType.exercise:
        return 'Bài tập';
      case DocumentType.reference:
        return 'Tham khảo';
    }
  }

  /// Icon tương ứng (trả về tên icon dạng string)
  String get iconName {
    switch (this) {
      case DocumentType.lecture:
        return 'school';
      case DocumentType.exercise:
        return 'assignment';
      case DocumentType.reference:
        return 'menu_book';
    }
  }

  /// Parse từ string
  static DocumentType fromString(String value) {
    return DocumentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DocumentType.reference,
    );
  }
}
