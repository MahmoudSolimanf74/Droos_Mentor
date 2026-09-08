import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/exams_repository.dart';
import '../domain/exam_attempt_model.dart';
import '../domain/exam_model.dart';
import '../domain/exam_question_model.dart';

class ReviewOption {
  final String text;
  final String letter;
  final int index;

  const ReviewOption({
    required this.text,
    required this.letter,
    required this.index,
  });
}

class ReviewQuestionItem {
  final int index;
  final String questionId;
  final String questionText;
  final List<ReviewOption> options;
  final double points;
  final String studentLetter;
  final String studentText;
  final String correctLetter;
  final String correctText;
  final bool? isCorrect;
  final double pointsEarned;
  final bool answered;

  const ReviewQuestionItem({
    required this.index,
    required this.questionId,
    required this.questionText,
    required this.options,
    required this.points,
    required this.studentLetter,
    required this.studentText,
    required this.correctLetter,
    required this.correctText,
    required this.isCorrect,
    required this.pointsEarned,
    required this.answered,
  });
}

class StudentExamReviewScreen extends StatefulWidget {
  final ExamAttemptModel? attempt;
  final Map<String, dynamic>? attemptMap;
  final ExamModel? exam;

  const StudentExamReviewScreen({
    super.key,
    this.attempt,
    this.attemptMap,
    this.exam,
  });

  @override
  State<StudentExamReviewScreen> createState() => _StudentExamReviewScreenState();
}

class _StudentExamReviewScreenState extends State<StudentExamReviewScreen> {
  late Future<List<ReviewQuestionItem>> _reviewFuture;
  late String _studentName;
  late String _studentCode;
  late String _examTitle;
  late String _examId;
  late double _score;
  late double _totalScore;
  late double _percentage;
  late bool _isPassed;
  DateTime? _submittedDate;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    final att = widget.attempt;
    final map = widget.attemptMap;

    if (att != null) {
      _studentName = att.studentName.isNotEmpty ? att.studentName : 'طالب';
      _studentCode = att.studentCode.isNotEmpty ? att.studentCode : 'STU-000';
      _examId = att.examId;
      _score = att.score;
      _totalScore = att.totalScore;
      _percentage = att.percentage;
      _submittedDate = att.submittedAt ?? att.startedAt;
    } else if (map != null) {
      _studentName = map['student_name']?.toString() ?? 'طالب';
      _studentCode = map['student_code']?.toString() ?? 'STU-000';
      _examId = map['exam_id']?.toString() ?? '';
      _score = (map['score'] as num?)?.toDouble() ?? 0.0;
      _totalScore = (map['total_score'] as num?)?.toDouble() ?? (map['total'] as num?)?.toDouble() ?? 100.0;
      _percentage = _totalScore > 0 ? (_score / _totalScore) * 100 : 0.0;
      final dateStr = map['submitted_at']?.toString() ?? map['started_at']?.toString();
      _submittedDate = dateStr != null ? DateTime.tryParse(dateStr) : null;
    } else {
      _studentName = 'طالب';
      _studentCode = 'STU-000';
      _examId = '';
      _score = 0;
      _totalScore = 100;
      _percentage = 0;
    }

    if (widget.exam != null) {
      _examTitle = widget.exam!.title;
    } else if (map?['exams'] is Map) {
      _examTitle = (map!['exams'] as Map)['title']?.toString() ?? 'امتحان';
    } else if (map?['title'] != null) {
      _examTitle = map!['title'].toString();
    } else {
      _examTitle = 'اختبار';
    }

    _isPassed = _percentage >= 50.0;
    _reviewFuture = _resolveReviewQuestions();
  }

  String _normalize(dynamic val) {
    if (val == null) return '';
    var s = val.toString().trim().toLowerCase();
    s = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), ''); // Remove tashkeel
    s = s.replaceAll(RegExp(r'[إأآٱ]'), 'ا'); // Normalize alef
    s = s.replaceAll(RegExp(r'ة'), 'ه'); // Normalize taa marboota
    s = s.replaceAll(RegExp(r'[ىي]'), 'ي'); // Normalize yaa
    s = s.replaceAll(RegExp(r'\s+'), ' '); // Normalize spaces
    return s.trim();
  }

  String _resolveLetter(dynamic raw, List<String> options) {
    if (raw == null) return '';
    final str = raw.toString().trim();
    if (str.isEmpty) return '';

    const letters = ['A', 'B', 'C', 'D', 'E', 'F'];
    final upper = str.toUpperCase();
    if (letters.contains(upper)) return upper;

    const arLetters = ['أ', 'ا', 'ب', 'ج', 'د', 'هـ', 'ه'];
    if (arLetters.contains(str)) {
      if (str == 'أ' || str == 'ا') return 'A';
      if (str == 'ب') return 'B';
      if (str == 'ج') return 'C';
      if (str == 'د') return 'D';
      if (str == 'هـ' || str == 'ه') return 'E';
    }

    final numVal = int.tryParse(str);
    if (numVal != null) {
      if (numVal >= 0 && numVal < letters.length) return letters[numVal];
      if (numVal >= 1 && numVal <= letters.length) return letters[numVal - 1];
    }

    if (options.isNotEmpty) {
      final normOpts = options.map((o) => _normalize(o)).toList();
      final idx = normOpts.indexOf(_normalize(str));
      if (idx >= 0 && idx < letters.length) {
        return letters[idx];
      }
    }

    return upper;
  }

  Future<List<ReviewQuestionItem>> _resolveReviewQuestions() async {
    final rawAnswers = widget.attempt?.answers ?? widget.attemptMap?['answers'] ?? widget.attemptMap?['breakdown'];

    dynamic parsedAnswers = rawAnswers;
    if (parsedAnswers is String) {
      try {
        parsedAnswers = jsonDecode(parsedAnswers);
      } catch (_) {}
    }

    if (parsedAnswers is Map) {
      if (parsedAnswers['breakdown'] is List) {
        parsedAnswers = parsedAnswers['breakdown'];
      } else if (parsedAnswers['answers'] is List) {
        parsedAnswers = parsedAnswers['answers'];
      }
    }

    List<Map<String, dynamic>> breakdownList = [];
    if (parsedAnswers is List) {
      breakdownList = parsedAnswers.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    // 1. Fetch exam questions from DB
    List<ExamQuestionModel> questions = [];
    if (_examId.isNotEmpty) {
      try {
        final repo = ExamsRepositoryImpl();
        questions = await repo.getExamQuestions(_examId);
      } catch (_) {}
    }

    final List<ReviewQuestionItem> result = [];

    if (questions.isNotEmpty) {
      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        final rawOptionsList = q.options;

        const letters = ['A', 'B', 'C', 'D', 'E', 'F'];
        final List<ReviewOption> reviewOptions = [];
        for (int optIdx = 0; optIdx < rawOptionsList.length; optIdx++) {
          final l = optIdx < letters.length ? letters[optIdx] : '${optIdx + 1}';
          reviewOptions.add(ReviewOption(
            text: rawOptionsList[optIdx],
            letter: l,
            index: optIdx,
          ));
        }

        // Lookup matching student breakdown item with Multi-tier matching
        Map<String, dynamic>? match;

        // Tier 1: Exact ID / Key match
        for (final b in breakdownList) {
          final bId = b['question_id']?.toString() ?? '';
          final bKey = b['question_key']?.toString() ?? '';
          if ((bId.isNotEmpty && bId == q.id) || (bKey.isNotEmpty && bKey == q.id)) {
            match = b;
            break;
          }
        }

        // Tier 2: Normalized question text match
        if (match == null) {
          final normQText = _normalize(q.question);
          if (normQText.isNotEmpty) {
            for (final b in breakdownList) {
              final bText = _normalize(b['question_text']);
              if (bText.isNotEmpty && bText == normQText) {
                match = b;
                break;
              }
            }
          }
        }

        // Tier 3: Question index match
        if (match == null) {
          for (final b in breakdownList) {
            final bIdx = b['question_index'];
            if (bIdx is int && (bIdx == i || bIdx == i + 1)) {
              match = b;
              break;
            }
          }
        }

        // Tier 4: Positional fallback
        if (match == null && i < breakdownList.length) {
          match = breakdownList[i];
        }

        String studentText = match?['selected_option']?.toString() ?? '';
        String studentLetter = match?['selected_letter']?.toString() ?? '';
        if (studentLetter.isEmpty && studentText.isNotEmpty) {
          studentLetter = _resolveLetter(studentText, rawOptionsList);
        }

        final bool answered = studentText.isNotEmpty && studentText != 'لم تتم الإجابة' && studentText != '(لم تتم الإجابة)';
        final correctText = q.correctAnswer;
        final correctLetter = _resolveLetter(correctText, rawOptionsList);

        bool? isCorrect;
        if (match != null && match['is_correct'] != null) {
          isCorrect = match['is_correct'] == true;
        } else if (answered) {
          if (studentLetter.isNotEmpty && correctLetter.isNotEmpty) {
            isCorrect = studentLetter == correctLetter;
          } else {
            isCorrect = _normalize(studentText) == _normalize(correctText);
          }
        } else {
          isCorrect = false;
        }

        final pointsEarned = match?['points_earned'] != null
            ? (match!['points_earned'] as num).toDouble()
            : (isCorrect == true ? 1.0 : 0.0);

        result.add(ReviewQuestionItem(
          index: i + 1,
          questionId: q.id,
          questionText: q.question,
          options: reviewOptions,
          points: 1.0,
          studentLetter: studentLetter,
          studentText: studentText,
          correctLetter: correctLetter,
          correctText: correctText,
          isCorrect: isCorrect,
          pointsEarned: pointsEarned,
          answered: answered,
        ));
      }
      return result;
    }

    // Fallback: If questions list could not be loaded directly, construct from breakdown
    for (int i = 0; i < breakdownList.length; i++) {
      final b = breakdownList[i];
      final qId = b['question_id']?.toString() ?? 'q_$i';
      final qText = b['question_text']?.toString() ?? 'سؤال ${i + 1}';
      final studentText = b['selected_option']?.toString() ?? '';
      final studentLetter = b['selected_letter']?.toString() ?? '';
      final correctText = b['correct_answer']?.toString() ?? '';
      final correctLetter = b['correct_letter']?.toString() ?? '';
      final isCorrect = b['is_correct'] as bool?;
      final pointsEarned = (b['points_earned'] as num?)?.toDouble() ?? (isCorrect == true ? 1.0 : 0.0);
      final bool answered = studentText.isNotEmpty && studentText != 'لم تتم الإجابة' && studentText != '(لم تتم الإجابة)';

      List<ReviewOption> mappedOptions = [];
      if (b['options'] is List) {
        final rawOpts = (b['options'] as List).map((e) => e.toString()).toList();
        const letters = ['A', 'B', 'C', 'D', 'E', 'F'];
        for (int optIdx = 0; optIdx < rawOpts.length; optIdx++) {
          final l = optIdx < letters.length ? letters[optIdx] : '${optIdx + 1}';
          mappedOptions.add(ReviewOption(
            text: rawOpts[optIdx],
            letter: l,
            index: optIdx,
          ));
        }
      }

      result.add(ReviewQuestionItem(
        index: i + 1,
        questionId: qId,
        questionText: qText,
        options: mappedOptions,
        points: 1.0,
        studentLetter: studentLetter,
        studentText: studentText,
        correctLetter: correctLetter,
        correctText: correctText,
        isCorrect: isCorrect,
        pointsEarned: pointsEarned,
        answered: answered,
      ));
    }

    return result;
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    try {
      final local = dt.toLocal();
      return DateFormat('yyyy/MM/dd – hh:mm a', 'ar').format(local);
    } catch (_) {
      return dt.toString().split('.').first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _isPassed ? AppColors.green : AppColors.red;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مراجعة ورقة الإجابة', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            Text('الطالب: $_studentName', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Student & Exam Summary Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: scoreColor.withValues(alpha: 0.15),
                          child: Text(
                            _studentName.isNotEmpty ? _studentName.substring(0, 1) : 'ط',
                            style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_studentName, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('كود الطالب: $_studentCode', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        StatusBadge(
                          label: '${_percentage.toInt()}% • ${_isPassed ? "ناجح" : "راسب"}',
                          color: scoreColor,
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('عنوان الامتحان:', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                        Text(_examTitle, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الدرجة المحرزة:', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                        Text('${_score.toInt()} / ${_totalScore.toInt()}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: scoreColor)),
                      ],
                    ),
                    if (_submittedDate != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('تاريخ التسليم:', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                          Text(_formatDate(_submittedDate), style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 2. Questions Section Header
              Row(
                children: [
                  const Icon(Icons.fact_check_outlined, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'تفاصيل إجابات الطالب وتصحيح الأسئلة',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Questions List
              FutureBuilder<List<ReviewQuestionItem>>(
                future: _reviewFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(strokeWidth: 2),
                            SizedBox(height: 12),
                            Text('جاري تجهيز وتصحيح أسئلة الامتحان...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  }

                  final questions = snapshot.data ?? [];

                  if (questions.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text(
                          'لا تتوفر تفاصيل إضافية للأسئلة في سجل هذه المحاولة.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final correctCount = questions.where((q) => q.isCorrect == true).length;
                  final wrongCount = questions.where((q) => q.answered && q.isCorrect == false).length;
                  final unansweredCount = questions.where((q) => !q.answered).length;

                  return Column(
                    children: [
                      // Overview KPI Bar
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatMini('إجمالي الأسئلة', '${questions.length}', AppColors.primary),
                            _buildStatMini('صحيحة 🟢', '$correctCount', AppColors.green),
                            _buildStatMini('خاطئة 🔴', '$wrongCount', AppColors.red),
                            if (unansweredCount > 0)
                              _buildStatMini('لم يجب ⚪', '$unansweredCount', AppColors.textSecondary),
                          ],
                        ),
                      ),

                      // List of Questions
                      ...questions.map((item) => _buildReviewQuestionCard(item)),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),
              CustomButton(
                text: 'إغلاق والرجوع',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatMini(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildReviewQuestionCard(ReviewQuestionItem item) {
    final bool isCorrect = item.isCorrect == true;
    final bool hasAnswered = item.answered;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isCorrect != null
              ? (isCorrect ? AppColors.green.withValues(alpha: 0.4) : AppColors.red.withValues(alpha: 0.4))
              : AppColors.border,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Question number & Result/Points Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'السؤال ${item.index}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const Spacer(),
              if (item.isCorrect != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isCorrect ? AppColors.green : AppColors.red).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (isCorrect ? AppColors.green : AppColors.red).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        size: 13,
                        color: isCorrect ? AppColors.green : AppColors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCorrect ? 'إجابة صحيحة (+${item.pointsEarned.toInt()} درجة)' : 'إجابة خاطئة (0 درجة)',
                        style: TextStyle(
                          color: isCorrect ? AppColors.green : AppColors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${item.points.toInt()} درجات',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Question Text Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: Text(
              item.questionText,
              style: AppTextStyles.titleSmall.copyWith(
                height: 1.5,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Options List (A, B, C, D) with Color Coding
          if (item.options.isNotEmpty)
            ...item.options.map((opt) {
              final optLetter = opt.letter.toUpperCase();
              final optTextNorm = _normalize(opt.text);

              // 1. Is this option the student's chosen answer?
              final bool isStudentChoice = hasAnswered &&
                  (optLetter == item.studentLetter.toUpperCase() ||
                      optTextNorm == _normalize(item.studentText) ||
                      _normalize(item.studentText).startsWith(optTextNorm));

              // 2. Is this option the correct answer?
              final bool isCorrectOption = optLetter == item.correctLetter.toUpperCase() ||
                  optTextNorm == _normalize(item.correctText) ||
                  _normalize(item.correctText).startsWith(optTextNorm) ||
                  _normalize(item.correctText).endsWith(optTextNorm);

              // Styling states
              Color bgColor = AppColors.surface;
              Color borderColor = AppColors.border;
              double borderWidth = 1.0;
              Color textColor = AppColors.textPrimary;
              FontWeight textWeight = FontWeight.normal;
              Widget? statusBadge;
              Color circleBg = AppColors.card;
              Color circleBorder = AppColors.border;
              Widget circleContent = Text(
                opt.letter,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              );

              if (isStudentChoice) {
                if (isCorrect) {
                  // Student choice is correct -> Green
                  bgColor = AppColors.green.withValues(alpha: 0.15);
                  borderColor = AppColors.green;
                  borderWidth = 2.0;
                  textColor = AppColors.green;
                  textWeight = FontWeight.bold;
                  circleBg = AppColors.green;
                  circleBorder = AppColors.green;
                  circleContent = const Icon(Icons.check_rounded, color: Colors.black, size: 16);
                  statusBadge = Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.green.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'إجابة الطالب (صحيحة) ✓',
                      style: TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  );
                } else {
                  // Student choice is WRONG -> Red
                  bgColor = AppColors.red.withValues(alpha: 0.15);
                  borderColor = AppColors.red;
                  borderWidth = 2.0;
                  textColor = AppColors.red;
                  textWeight = FontWeight.bold;
                  circleBg = AppColors.red;
                  circleBorder = AppColors.red;
                  circleContent = const Icon(Icons.close_rounded, color: Colors.white, size: 16);
                  statusBadge = Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.red.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'إجابة الطالب (خاطئة) ✗',
                      style: TextStyle(color: AppColors.red, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  );
                }
              } else if (isCorrectOption) {
                // Correct answer marked in Green (when student didn't choose it or got it wrong)
                bgColor = AppColors.green.withValues(alpha: 0.15);
                borderColor = AppColors.green;
                borderWidth = 2.0;
                textColor = AppColors.green;
                textWeight = FontWeight.bold;
                circleBg = AppColors.green;
                circleBorder = AppColors.green;
                circleContent = const Icon(Icons.check_rounded, color: Colors.black, size: 16);
                statusBadge = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.green.withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    'الإجابة الصحيحة ✓',
                    style: TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                );
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: borderWidth),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: circleBg,
                        border: Border.all(color: circleBorder),
                      ),
                      child: Center(child: circleContent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        opt.text,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: textColor,
                          fontWeight: textWeight,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (statusBadge != null) ...[
                      const SizedBox(width: 8),
                      statusBadge,
                    ],
                  ],
                ),
              );
            })
          else ...[
            // Fallback if options list is not present
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCorrect ? AppColors.green.withValues(alpha: 0.1) : AppColors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isCorrect ? AppColors.green : AppColors.red),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          size: 16, color: isCorrect ? AppColors.green : AppColors.red),
                      const SizedBox(width: 6),
                      Text('إجابة الطالب: ${hasAnswered ? item.studentText : "(لم يُجب الطالب)"}',
                          style: TextStyle(color: isCorrect ? AppColors.green : AppColors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (!isCorrect && item.correctText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.green),
                        const SizedBox(width: 6),
                        Text('الإجابة الصحيحة: ${item.correctText}',
                            style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Unanswered notice
          if (!hasAnswered)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded, size: 13, color: AppColors.textSecondary),
                  SizedBox(width: 5),
                  Text(
                    'لم يقم الطالب باختيار إجابة لهذا السؤال أثناء الامتحان',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
