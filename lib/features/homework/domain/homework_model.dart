import 'package:equatable/equatable.dart';

class HomeworkModel extends Equatable {
  final String id;
  final String groupId;
  final String? lessonId;
  final String title;
  final DateTime? dueDate;
  final DateTime createdAt;
  final int completedCount;
  final int totalStudents;
  final String? groupName;
  final String? lessonTitle;

  const HomeworkModel({
    required this.id,
    required this.groupId,
    this.lessonId,
    required this.title,
    this.dueDate,
    required this.createdAt,
    this.completedCount = 0,
    this.totalStudents = 0,
    this.groupName,
    this.lessonTitle,
  });

  double get completionRate => totalStudents > 0 ? (completedCount / totalStudents) * 100 : 0.0;

  factory HomeworkModel.fromJson(
    Map<String, dynamic> json, {
    int completedCount = 0,
    int totalStudents = 0,
    String? groupName,
    String? lessonTitle,
  }) {
    return HomeworkModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String? ?? '',
      lessonId: json['lesson_id'] as String?,
      title: json['title'] as String? ?? '',
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      completedCount: json['completed_count'] as int? ?? completedCount,
      totalStudents: json['total_students'] as int? ?? totalStudents,
      groupName: groupName,
      lessonTitle: lessonTitle,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'group_id': groupId,
        'lesson_id': lessonId,
        'title': title,
        'due_date': dueDate?.toIso8601String().split('T').first,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        groupId,
        lessonId,
        title,
        dueDate,
        createdAt,
        completedCount,
        totalStudents,
        groupName,
        lessonTitle,
      ];
}
