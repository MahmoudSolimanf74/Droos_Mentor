import 'dart:convert';
import 'package:equatable/equatable.dart';

class ExamQuestionModel extends Equatable {
  final String id;
  final String examId;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final int sortOrder;

  const ExamQuestionModel({
    required this.id,
    required this.examId,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.sortOrder = 0,
  });

  factory ExamQuestionModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedOptions = [];
    final opts = json['options'];
    if (opts is List) {
      parsedOptions = opts.map((e) => e.toString()).toList();
    } else if (opts is String) {
      try {
        final decoded = jsonDecode(opts);
        if (decoded is List) {
          parsedOptions = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return ExamQuestionModel(
      id: json['id'] as String,
      examId: json['exam_id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      options: parsedOptions,
      correctAnswer: json['correct_answer'] as String? ?? '',
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'exam_id': examId,
        'question': question,
        'options': options,
        'correct_answer': correctAnswer,
        'sort_order': sortOrder,
      };

  @override
  List<Object?> get props => [id, examId, question, options, correctAnswer, sortOrder];
}
