/// Model thuần Dart cho danh mục - không phụ thuộc vào Drift hay Flutter
class CategoryModel {
  final String id;
  final String name;
  final String description;
  final String color;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    this.description = '',
    this.color = '#2196F3',
    required this.createdAt,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'CategoryModel(id: $id, name: $name)';
}
