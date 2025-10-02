// import 'package:freezed_annotation/freezed_annotation.dart';

// part 'category.freezed.dart';
// part 'category.g.dart';

enum CategoryStatus {
  active,
  inactive,
  archived,
}

// @freezed
class Category {
  // const factory Category({
  const Category({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.description,
    required this.status,
    this.image,
    this.color,
    this.icon,
    this.sortOrder,
    this.parentId,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int tenantId;
  final String name;
  final String description;
  final CategoryStatus status;
  final String? image;
  final String? color;
  final String? icon;
  final int? sortOrder;
  final int? parentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int,
      tenantId: map['tenant_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String,
      status: CategoryStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CategoryStatus.active,
      ),
      image: map['image'] as String?,
      color: map['color'] as String?,
      icon: map['icon'] as String?,
      sortOrder: map['sort_order'] as int?,
      parentId: map['parent_id'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'description': description,
      'status': status.name,
      'image': image,
      'color': color,
      'icon': icon,
      'sort_order': sortOrder,
      'parent_id': parentId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  Category copyWith({
    int? id,
    int? tenantId,
    String? name,
    String? description,
    CategoryStatus? status,
    String? image,
    String? color,
    String? icon,
    int? sortOrder,
    int? parentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      image: image ?? this.image,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
