import 'package:equatable/equatable.dart';

class ExamModel extends Equatable {
  final String id;
  final String teacherId;
  final String gradeId;
  final String gradeName;
  final String? lessonId;
  final String? lessonTitle;
  final String title;
  final int durationMinutes;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool isActive;
  final DateTime createdAt;
  final int questionsCount;
  final int attemptsCount;

  const ExamModel({
    required this.id,
    this.teacherId = '',
    required this.gradeId,
    this.gradeName = '',
    this.lessonId,
    this.lessonTitle,
    required this.title,
    this.durationMinutes = 30,
    this.startAt,
    this.endAt,
    this.isActive = true,
    required this.createdAt,
    this.questionsCount = 0,
    this.attemptsCount = 0,
  });

  bool get isOngoing {
    final now = DateTime.now();
    if (startAt != null && now.isBefore(startAt!)) return false;
    if (endAt != null && now.isAfter(endAt!)) return false;
    return isActive;
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return startAt != null && now.isBefore(startAt!);
  }

  bool get isEnded {
    final now = DateTime.now();
    return endAt != null && now.isAfter(endAt!);
  }

  ExamModel copyWith({
    String? id,
    String? teacherId,
    String? gradeId,
    String? gradeName,
    String? lessonId,
    String? lessonTitle,
    String? title,
    int? durationMinutes,
    DateTime? startAt,
    DateTime? endAt,
    bool? isActive,
    DateTime? createdAt,
    int? questionsCount,
    int? attemptsCount,
  }) {
    return ExamModel(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      gradeId: gradeId ?? this.gradeId,
      gradeName: gradeName ?? this.gradeName,
      lessonId: lessonId ?? this.lessonId,
      lessonTitle: lessonTitle ?? this.lessonTitle,
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      questionsCount: questionsCount ?? this.questionsCount,
      attemptsCount: attemptsCount ?? this.attemptsCount,
    );
  }

  factory ExamModel.fromJson(
    Map<String, dynamic> json, {
    int questionsCount = 0,
    int attemptsCount = 0,
  }) {
    String gName = '';
    if (json['grades'] != null && json['grades'] is Map) {
      gName = json['grades']['name'] as String? ?? '';
    } else if (json['grade_name'] != null) {
      gName = json['grade_name'] as String? ?? '';
    }

    String? lTitle;
    if (json['lessons'] != null && json['lessons'] is Map) {
      lTitle = json['lessons']['title'] as String?;
    } else if (json['lesson_title'] != null) {
      lTitle = json['lesson_title'] as String?;
    }

    return ExamModel(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String? ?? '',
      gradeId: json['grade_id'] as String? ?? '',
      gradeName: gName.isNotEmpty ? gName : 'الصف الأول الثانوي',
      lessonId: json['lesson_id'] as String?,
      lessonTitle: lTitle,
      title: json['title'] as String? ?? '',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
      startAt: json['start_at'] != null ? DateTime.tryParse(json['start_at'].toString()) : null,
      endAt: json['end_at'] != null ? DateTime.tryParse(json['end_at'].toString()) : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      questionsCount: json['questions_count'] as int? ?? questionsCount,
      attemptsCount: json['attempts_count'] as int? ?? attemptsCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'teacher_id': teacherId,
        'grade_id': gradeId,
        if (lessonId != null) 'lesson_id': lessonId,
        'title': title,
        'duration_minutes': durationMinutes,
        'start_at': startAt?.toIso8601String(),
        'end_at': endAt?.toIso8601String(),
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        teacherId,
        gradeId,
        gradeName,
        lessonId,
        lessonTitle,
        title,
        durationMinutes,
        startAt,
        endAt,
        isActive,
        createdAt,
        questionsCount,
        attemptsCount,
      ];
}
