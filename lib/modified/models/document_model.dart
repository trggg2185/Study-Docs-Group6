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
    );
  }

  @override
  String toString() => 'DocumentModel(id: $id, title: $title, type: $type)';
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
