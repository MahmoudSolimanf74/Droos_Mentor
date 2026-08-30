import 'package:equatable/equatable.dart';

class LessonModel extends Equatable {
  final String id;
  final String unitId;
  final String title;
  final String? description;
  final int sortOrder;
  final DateTime createdAt;
  final int filesCount;

  const LessonModel({
    required this.id,
    required this.unitId,
    required this.title,
    this.description,
    this.sortOrder = 0,
    required this.createdAt,
    this.filesCount = 0,
  });

  LessonModel copyWith({
    String? id,
    String? unitId,
    String? title,
    String? description,
    int? sortOrder,
    DateTime? createdAt,
    int? filesCount,
  }) {
    return LessonModel(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      title: title ?? this.title,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      filesCount: filesCount ?? this.filesCount,
    );
  }

  factory LessonModel.fromJson(Map<String, dynamic> json, [int filesCount = 0]) {
    return LessonModel(
      id: json['id'] as String,
      unitId: json['unit_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      filesCount: json['files_count'] as int? ?? filesCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'unit_id': unitId,
        'title': title,
        'description': description,
        'sort_order': sortOrder,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, unitId, title, description, sortOrder, createdAt, filesCount];
}
