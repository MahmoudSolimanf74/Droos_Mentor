import 'package:equatable/equatable.dart';

class UnitModel extends Equatable {
  final String id;
  final String curriculumId;
  final String title;
  final String? description;
  final int sortOrder;
  final DateTime createdAt;
  final int lessonsCount;

  const UnitModel({
    required this.id,
    required this.curriculumId,
    required this.title,
    this.description,
    this.sortOrder = 0,
    required this.createdAt,
    this.lessonsCount = 0,
  });

  UnitModel copyWith({
    String? id,
    String? curriculumId,
    String? title,
    String? description,
    int? sortOrder,
    DateTime? createdAt,
    int? lessonsCount,
  }) {
    return UnitModel(
      id: id ?? this.id,
      curriculumId: curriculumId ?? this.curriculumId,
      title: title ?? this.title,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      lessonsCount: lessonsCount ?? this.lessonsCount,
    );
  }

  factory UnitModel.fromJson(Map<String, dynamic> json, [int lessonsCount = 0]) {
    return UnitModel(
      id: json['id'] as String,
      curriculumId: json['curriculum_id'] as String? ?? json['group_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lessonsCount: json['lessons_count'] as int? ?? lessonsCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'curriculum_id': curriculumId,
        'title': title,
        'description': description,
        'sort_order': sortOrder,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, curriculumId, title, description, sortOrder, createdAt, lessonsCount];
}
