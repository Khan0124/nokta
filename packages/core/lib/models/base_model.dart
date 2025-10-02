// packages/core/lib/models/base_model.dart
abstract class BaseModel {
  final int id;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  BaseModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });
  
  Map<String, dynamic> toJson();
}

