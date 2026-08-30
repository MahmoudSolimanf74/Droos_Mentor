import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../grades/domain/grade_model.dart';
import '../../grades/presentation/grades_cubit.dart';
import '../domain/exam_model.dart';
import 'exams_cubit.dart';

class CreateExamManualScreen extends StatefulWidget {
  final String? initialGradeId;
  final ExamModel? examToEdit;

  const CreateExamManualScreen({
    super.key,
    this.initialGradeId,
    this.examToEdit,
  });

  @override
  State<CreateExamManualScreen> createState() => _CreateExamManualScreenState();
}

class _CreateExamManualScreenState extends State<CreateExamManualScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController(text: '30');

  String? _selectedGradeId;
  final List<Map<String, dynamic>> _questions = [];

  // Current Question draft fields
  final _questionTextController = TextEditingController();
  final _option1Controller = TextEditingController();
  final _option2Controller = TextEditingController();
  final _option3Controller = TextEditingController();
  final _option4Controller = TextEditingController();
  int _correctOptionIndex = 0; // 0, 1, 2, or 3
  bool _isSaving = false;
  bool _isLoadingQuestions = false;

  bool get isEditMode => widget.examToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      final exam = widget.examToEdit!;
      _titleController.text = exam.title;
      _durationController.text = exam.durationMinutes.toString();
      _selectedGradeId = exam.gradeId;
      _loadExistingQuestions(exam.id);
    } else {
      _selectedGradeId = widget.initialGradeId;
      final gradesState = context.read<GradesCubit>().state;
      if (_selectedGradeId == null && gradesState is GradesLoaded && gradesState.grades.isNotEmpty) {
        _selectedGradeId = gradesState.grades.first.id;
      }
    }
  }

  Future<void> _loadExistingQuestions(String examId) async {
    setState(() => _isLoadingQuestions = true);
    try {
      final qList = await context.read<ExamsCubit>().getExamQuestions(examId);
      if (mounted) {
        setState(() {
          _questions.clear();
          for (final q in qList) {
            _questions.add({
              'question': q.question,
              'options': q.options,
              'correct_answer': q.correctAnswer,
            });
          }
          _isLoadingQuestions = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingQuestions = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _questionTextController.dispose();
    _option1Controller.dispose();
    _option2Controller.dispose();
    _option3Controller.dispose();
    _option4Controller.dispose();
    super.dispose();
  }

  void _addQuestionToList() {
    final qText = _questionTextController.text.trim();
    final opt1 = _option1Controller.text.trim();
    final opt2 = _option2Controller.text.trim();
    final opt3 = _option3Controller.text.trim();
    final opt4 = _option4Controller.text.trim();

    if (qText.isEmpty || opt1.isEmpty || opt2.isEmpty || opt3.isEmpty || opt4.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء نص السؤال وكافة الخيارات الأربعة'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    final options = [opt1, opt2, opt3, opt4];
    final letters = ['A', 'B', 'C', 'D'];
    final correctLetter = letters[_correctOptionIndex];

    setState(() {
      _questions.add({
        'question': qText,
        'options': options,
        'correct_answer': correctLetter,
      });

      // Clear draft question form
      _questionTextController.clear();
      _option1Controller.clear();
      _option2Controller.clear();
      _option3Controller.clear();
      _option4Controller.clear();
      _correctOptionIndex = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تمت إضافة السؤال رقم ${_questions.length} إلى مسودة الامتحان'),
        backgroundColor: AppColors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _submitExam() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedGradeId == null || _selectedGradeId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار المجموعة المستهدفة'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إضافة سؤال واحد على الأقل قبل حفظ الامتحان'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final duration = int.tryParse(_durationController.text.trim()) ?? 30;

    try {
      if (isEditMode) {
        await context.read<ExamsCubit>().updateExam(
          examId: widget.examToEdit!.id,
          title: _titleController.text.trim(),
          durationMinutes: duration,
          gradeId: _selectedGradeId,
          questions: _questions,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث الامتحان بنجاح! ✅'),
              backgroundColor: AppColors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        await context.read<ExamsCubit>().createExam(
          gradeId: _selectedGradeId!,
          title: _titleController.text.trim(),
          durationMinutes: duration,
          questions: _questions,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم اعتماد وإنشاء الامتحان بنجاح!'),
              backgroundColor: AppColors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء حفظ الامتحان: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditMode ? 'تعديل بيانات وأسئلة الامتحان' : 'إنشاء امتحان خطوة بخطوة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoadingQuestions
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Exam Info Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'بيانات الامتحان الأساسية',
                              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              controller: _titleController,
                              label: 'عنوان أو اسم الامتحان',
                              hintText: 'مثال: اختبار الوحدة الأولى - الجبر',
                              prefixIcon: Icons.title_rounded,
                              validator: (val) => val == null || val.trim().isEmpty ? 'يرجى إدخال اسم الامتحان' : null,
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              controller: _durationController,
                              label: 'مدة الامتحان بالدقائق',
                              hintText: '30',
                              keyboardType: TextInputType.number,
                              prefixIcon: Icons.timer_outlined,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'يرجى إدخال المدة';
                                if (int.tryParse(val.trim()) == null) return 'أرقام فقط';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            // Group Selector
                            BlocBuilder<GradesCubit, GradesState>(
                              builder: (context, state) {
                                final grades = state is GradesLoaded ? state.grades : <GradeModel>[];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('المجموعة المستهدفة:', style: AppTextStyles.labelMedium),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: grades.map((g) {
                                        final isSel = _selectedGradeId == g.id;
                                        return ChoiceChip(
                                          label: Text(g.name),
                                          selected: isSel,
                                          selectedColor: g.color.withValues(alpha: 0.25),
                                          backgroundColor: AppColors.surface,
                                          side: BorderSide(color: isSel ? g.color : AppColors.border),
                                          labelStyle: TextStyle(
                                            color: isSel ? g.color : AppColors.textSecondary,
                                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                          ),
                                          onSelected: (_) => setState(() => _selectedGradeId = g.id),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 2. Added Questions List (Preview)
                      if (_questions.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'الأسئلة المعتمدة (${_questions.length}):',
                              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'مجموع الأسئلة: ${_questions.length}',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.cyan, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _questions.length,
                          separatorBuilder: (c, i) => const SizedBox(height: 8),
                          itemBuilder: (ctx, idx) {
                            final q = _questions[idx];
                            final opts = q['options'] as List<dynamic>;
                            final correctLetter = q['correct_answer'] as String;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'س ${idx + 1}',
                                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          q['question'] as String,
                                          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red, size: 20),
                                        onPressed: () => _removeQuestion(idx),
                                        tooltip: 'حذف هذا السؤال',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: List.generate(opts.length, (optIdx) {
                                      final letters = ['A', 'B', 'C', 'D'];
                                      final isCorrect = letters[optIdx] == correctLetter;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isCorrect ? AppColors.green.withValues(alpha: 0.15) : AppColors.surface,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: isCorrect ? AppColors.green : AppColors.border),
                                        ),
                                        child: Text(
                                          '${letters[optIdx]}) ${opts[optIdx]} ${isCorrect ? "✅" : ""}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                            color: isCorrect ? AppColors.green : AppColors.textSecondary,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],

                      // 3. New Question Builder Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'إضافة سؤال اختيار من متعدد (MCQ)',
                                  style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              controller: _questionTextController,
                              label: 'نص السؤال',
                              hintText: 'اكتب نص السؤال هنا...',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 12),
                            Text('الخيارات الأربعة وحدد الإجابة الصحيحة:', style: AppTextStyles.labelMedium),
                            const SizedBox(height: 8),
                            _buildOptionInput(0, 'الخيار (A)', _option1Controller),
                            const SizedBox(height: 8),
                            _buildOptionInput(1, 'الخيار (B)', _option2Controller),
                            const SizedBox(height: 8),
                            _buildOptionInput(2, 'الخيار (C)', _option3Controller),
                            const SizedBox(height: 8),
                            _buildOptionInput(3, 'الخيار (D)', _option4Controller),
                            const SizedBox(height: 14),
                            CustomButton(
                              text: '➕ إضافة السؤال للمسودة',
                              onPressed: _addQuestionToList,
                              variant: ButtonVariant.outline,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 4. Save Final Exam Button
                      CustomButton(
                        text: isEditMode ? '💾 حفظ تعديلات الامتحان' : '🚀 اعتماد ونشر الامتحان الآن',
                        isLoading: _isSaving,
                        onPressed: _submitExam,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildOptionInput(int index, String label, TextEditingController controller) {
    final isCorrect = _correctOptionIndex == index;

    return Row(
      children: [
        Radio<int>(
          value: index,
          groupValue: _correctOptionIndex,
          activeColor: AppColors.green,
          onChanged: (val) {
            if (val != null) setState(() => _correctOptionIndex = val);
          },
        ),
        Expanded(
          child: CustomTextField(
            controller: controller,
            label: label,
            hintText: 'اكتب نص الخيار...',
          ),
        ),
        if (isCorrect)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'الصحيحة',
              style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
      ],
    );
  }
}
