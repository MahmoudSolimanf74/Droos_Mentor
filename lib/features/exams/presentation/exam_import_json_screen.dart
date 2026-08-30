import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/json_validator.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/status_badge.dart';
import '../../grades/data/grades_repository.dart';
import '../../grades/domain/grade_model.dart';
import '../presentation/exams_cubit.dart';

class ExamImportJsonScreen extends StatefulWidget {
  const ExamImportJsonScreen({super.key});

  @override
  State<ExamImportJsonScreen> createState() => _ExamImportJsonScreenState();
}

class _ExamImportJsonScreenState extends State<ExamImportJsonScreen> {
  final TextEditingController _jsonController = TextEditingController();
  String? _selectedGradeId;
  List<GradeModel> _grades = [];
  bool _isLoadingGrades = true;
  JsonValidationResult? _validationResult;
  DateTime? _startAt;
  DateTime? _endAt;
  bool _isPublishing = false;

  static const String _sampleJson = '''{
  "title": "اختبار البرمجة الكائنية والأنواع (OOP)",
  "duration_minutes": 30,
  "questions": [
    {
      "question": "ما هو مفهوم التغليف (Encapsulation) في البرمجة الكائنية؟",
      "options": [
        "إخفاء تفاصيل التنفيذ وحماية البيانات الداخلية",
        "وراثة الخصائص من كائن لآخر",
        "تعدد الأشكال للدوال",
        "تحويل نوع البيانات"
      ],
      "correct_answer": "إخفاء تفاصيل التنفيذ وحماية البيانات الداخلية"
    },
    {
      "question": "أي من الكلمات المفتاحية تستخدم لإنشاء صنف فرعي يرث من صنف رئيسي؟",
      "options": [
        "implements",
        "extends",
        "with",
        "inherits"
      ],
      "correct_answer": "extends"
    },
    {
      "question": "ما هي القيمة الافتراضية للمتغير غير المعرف في Dart؟",
      "options": [
        "0",
        "false",
        "null",
        "undefined"
      ],
      "correct_answer": "null"
    }
  ]
}''';

  @override
  void initState() {
    super.initState();
    _jsonController.text = _sampleJson;
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    try {
      final grades = await context.read<GradesRepository>().getGrades();
      if (mounted) {
        setState(() {
          _grades = grades;
          if (grades.isNotEmpty) {
            _selectedGradeId = grades.first.id;
          }
          _isLoadingGrades = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingGrades = false);
    }
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  void _validateJson() {
    final res = JsonExamValidator.validate(_jsonController.text);
    setState(() {
      _validationResult = res;
    });
  }

  Future<void> _publishExam() async {
    if (_selectedGradeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار المرحلة الدراسية المستهدفة أولاً')),
      );
      return;
    }

    if (_validationResult == null || !_validationResult!.isValid || _validationResult!.parsedExam == null) {
      _validateJson();
      if (_validationResult == null || !_validationResult!.isValid) return;
    }

    final exam = _validationResult!.parsedExam!;
    setState(() => _isPublishing = true);

    try {
      final questionsData = exam.questions.map((q) => q.toJson()).toList();
      await context.read<ExamsCubit>().createExam(
            gradeId: _selectedGradeId!,
            title: exam.title,
            durationMinutes: exam.durationMinutes,
            startAt: _startAt ?? DateTime.now(),
            endAt: _endAt ?? DateTime.now().add(const Duration(days: 7)),
            questions: questionsData,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء الاختبار ونشره بنجاح!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حفظ الاختبار: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('استيراد اختبار من ملف JSON'),
      ),
      body: _isLoadingGrades
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.sage)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Target Grade Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '1. تحديد المرحلة الدراسية / المنهج المستهدف:',
                            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedGradeId ?? (_grades.isNotEmpty ? _grades.first.id : null),
                            isExpanded: true,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.school_outlined, size: 20),
                            ),
                            items: _grades.map((g) {
                              return DropdownMenuItem(
                                value: g.id,
                                child: Text(g.name),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedGradeId = val),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // JSON Input Box
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '2. الصق نص JSON أو عدّل النموذج أدناه:',
                                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.restart_alt, size: 16),
                                label: const Text('إعادة تعيين النموذج'),
                                onPressed: () {
                                  _jsonController.text = _sampleJson;
                                  _validateJson();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: _jsonController,
                            maxLines: 12,
                            textDirection: TextDirection.ltr,
                            hintText: '{\n  "title": "...",\n  "questions": [...]\n}',
                          ),
                          const SizedBox(height: 12),
                          CustomButton(
                            text: 'التحقق من صحة ملف JSON',
                            icon: Icons.check_circle_outline,
                            variant: ButtonVariant.primary,
                            onPressed: _validateJson,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Validation Status / Error / Preview Box
                  if (_validationResult != null) ...[
                    if (!_validationResult!.isValid) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'تم العثور على أخطاء في ملف JSON:',
                                  style: AppTextStyles.titleSmall.copyWith(color: AppColors.danger, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ..._validationResult!.errors.map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                                      Expanded(
                                        child: Text(e, style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger)),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ] else if (_validationResult!.parsedExam != null) ...[
                      // Valid preview
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'تم التحقق بنجاح (${_validationResult!.parsedExam!.questions.length} أسئلة)',
                                      style: AppTextStyles.titleSmall.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                StatusBadge(
                                  label: '${_validationResult!.parsedExam!.durationMinutes} دقيقة',
                                  variant: BadgeVariant.success,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'عنوان الاختبار: ${_validationResult!.parsedExam!.title}',
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Questions Preview Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'معاينة الأسئلة (${_validationResult!.parsedExam!.questions.length}):',
                                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 12),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _validationResult!.parsedExam!.questions.length,
                                separatorBuilder: (c, i) => const Divider(color: AppColors.border, height: 20),
                                itemBuilder: (ctx, qIdx) {
                                  final q = _validationResult!.parsedExam!.questions[qIdx];
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'س${qIdx + 1}: ${q.question}',
                                        style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 6),
                                      ...q.options.map((opt) {
                                        final isCorrect = opt == q.correctAnswer;
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isCorrect ? AppColors.sageLight : AppColors.surfaceMuted,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: isCorrect ? AppColors.sage : AppColors.border,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                                                size: 14,
                                                color: isCorrect ? AppColors.sageDark : AppColors.textMuted,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  opt,
                                                  style: AppTextStyles.bodySmall.copyWith(
                                                    fontWeight: isCorrect ? FontWeight.w700 : FontWeight.normal,
                                                    color: isCorrect ? AppColors.sageDark : AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              if (isCorrect)
                                                Text(
                                                  '(الإجابة الصحيحة)',
                                                  style: AppTextStyles.labelSmall.copyWith(
                                                    color: AppColors.sageDark,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Final Submit Button
                      CustomButton(
                        text: 'اعتماد الاستيراد وإنشاء الاختبار',
                        icon: Icons.publish_outlined,
                        variant: ButtonVariant.primary,
                        isLoading: _isPublishing,
                        isFullWidth: true,
                        onPressed: _publishExam,
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}
