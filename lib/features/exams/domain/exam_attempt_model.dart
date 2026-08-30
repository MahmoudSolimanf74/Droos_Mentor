import 'package:equatable/equatable.dart';

class ExamAttemptModel extends Equatable {
  final String id;
  final String examId;
  final String studentId;
  final String studentName;
  final String studentCode;
  final double score;
  final double totalScore;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final bool isOfficial;

  const ExamAttemptModel({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    required this.score,
    this.totalScore = 100.0,
    required this.startedAt,
    this.submittedAt,
    this.isOfficial = true,
  });

  double get percentage => totalScore > 0 ? (score / totalScore) * 100 : 0.0;

  factory ExamAttemptModel.fromJson(Map<String, dynamic> json, {String studentName = '', String studentCode = ''}) {
    return ExamAttemptModel(
      id: json['id'] as String,
      examId: json['exam_id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      studentName: json['student_name'] as String? ?? studentName,
      studentCode: json['student_code'] as String? ?? studentCode,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      totalScore: (json['total_score'] as num?)?.toDouble() ?? 100.0,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'].toString())
          : null,
      isOfficial: json['is_official'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'exam_id': examId,
        'student_id': studentId,
        'score': score,
        'total_score': totalScore,
        'started_at': startedAt.toIso8601String(),
        'submitted_at': submittedAt?.toIso8601String(),
        'is_official': isOfficial,
      };

  @override
  List<Object?> get props => [
        id,
        examId,
        studentId,
        studentName,
        studentCode,
        score,
        totalScore,
        startedAt,
        submittedAt,
        isOfficial,
      ];
}
