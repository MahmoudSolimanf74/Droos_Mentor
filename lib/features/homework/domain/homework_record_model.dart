import 'package:equatable/equatable.dart';

class HomeworkRecordModel extends Equatable {
  final String id;
  final String homeworkId;
  final String studentId;
  final String studentName;
  final String studentCode;
  final String status; // 'done', 'not_done'
  final DateTime? createdAt;

  const HomeworkRecordModel({
    required this.id,
    required this.homeworkId,
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    required this.status,
    this.createdAt,
  });

  bool get isDone => status == 'done';
  bool get isCompleted => isDone;

  HomeworkRecordModel copyWith({
    String? id,
    String? homeworkId,
    String? studentId,
    String? studentName,
    String? studentCode,
    String? status,
    DateTime? createdAt,
  }) {
    return HomeworkRecordModel(
      id: id ?? this.id,
      homeworkId: homeworkId ?? this.homeworkId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentCode: studentCode ?? this.studentCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory HomeworkRecordModel.fromJson(Map<String, dynamic> json, {String studentName = '', String studentCode = ''}) {
    return HomeworkRecordModel(
      id: json['id'] as String,
      homeworkId: json['homework_id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      studentName: json['student_name'] as String? ?? studentName,
      studentCode: json['student_code'] as String? ?? studentCode,
      status: json['status'] as String? ?? 'not_done',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'homework_id': homeworkId,
        'student_id': studentId,
        'status': status,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, homeworkId, studentId, studentName, studentCode, status, createdAt];
}
