import 'package:equatable/equatable.dart';

class CurriculumModel extends Equatable {
  final String id;
  final String teacherId;
  final String gradeId;
  final String gradeName;
  final String title;
  final String subject;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final int unitsCount;

  const CurriculumModel({
    required this.id,
    required this.teacherId,
    required this.gradeId,
    this.gradeName = '',
    required this.title,
    this.subject = 'برمجة الحاسب',
    this.description,
    this.isActive = true,
    required this.createdAt,
    this.unitsCount = 0,
  });

  CurriculumModel copyWith({
    String? id,
    String? teacherId,
    String? gradeId,
    String? gradeName,
    String? title,
    String? subject,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    int? unitsCount,
  }) {
    return CurriculumModel(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      gradeId: gradeId ?? this.gradeId,
      gradeName: gradeName ?? this.gradeName,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      unitsCount: unitsCount ?? this.unitsCount,
    );
  }

  factory CurriculumModel.fromJson(Map<String, dynamic> json, [int unitsCount = 0]) {
    String gName = '';
    if (json['grades'] != null && json['grades'] is Map) {
      gName = json['grades']['name'] as String? ?? '';
    } else if (json['grade_name'] != null) {
      gName = json['grade_name'] as String? ?? '';
    }

    return CurriculumModel(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String? ?? '',
      gradeId: json['grade_id'] as String? ?? '',
      gradeName: gName.isNotEmpty ? gName : 'المرحلة الدراسية',
      title: json['title'] as String? ?? '',
      subject: json['subject'] as String? ?? 'برمجة الحاسب',
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      unitsCount: json['units_count'] as int? ?? unitsCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'teacher_id': teacherId,
        'grade_id': gradeId,
        'title': title,
        'subject': subject,
        'description': description,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        teacherId,
        gradeId,
        gradeName,
        title,
        subject,
        description,
        isActive,
        createdAt,
        unitsCount,
      ];
}
