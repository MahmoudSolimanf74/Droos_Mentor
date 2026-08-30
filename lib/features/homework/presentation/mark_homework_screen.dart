import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/status_badge.dart';
import '../../students/data/students_repository.dart';
import '../../students/domain/student_model.dart';
import 'homework_cubit.dart';

class MarkHomeworkScreen extends StatefulWidget {
  final String groupId;
  final String homeworkId;

  const MarkHomeworkScreen({
    super.key,
    required this.groupId,
    required this.homeworkId,
  });

  @override
  State<MarkHomeworkScreen> createState() => _MarkHomeworkScreenState();
}

class _MarkHomeworkScreenState extends State<MarkHomeworkScreen> {
  final TextEditingController _titleController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  List<StudentModel> _students = [];
  final Map<String, String> _statuses = {}; // studentId -> 'done' | 'not_done'
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = 'واجب درس الأسبوع الحالي';
    _loadStudents();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    final repo = StudentsRepositoryImpl();
    try {
      final list = await repo.getStudents(groupId: widget.groupId);
      if (mounted) {
        setState(() {
          _students = list;
          for (final s in list) {
            _statuses[s.id] = 'done'; // Default to done
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _markAll(String status) {
    setState(() {
      for (final s in _students) {
        _statuses[s.id] = status;
      }
    });
  }

  Future<void> _saveHomework() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال عنوان الواجب')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final records = _students.map((s) => {
            'student_id': s.id,
            'status': _statuses[s.id] ?? 'done',
          }).toList();

      await context.read<HomeworkCubit>().saveHomework(
            groupId: widget.groupId,
            title: _titleController.text.trim(),
            dueDate: _dueDate,
            records: records,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.homeworkSaved),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حفظ الواجب: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.sage))),
      );
    }

    final doneCount = _statuses.values.where((v) => v == 'done').length;
    final total = _students.length;
    final completionPct = total > 0 ? (doneCount / total) * 100 : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.markHomework),
        actions: [
          CustomButton(
            text: AppStrings.save,
            icon: Icons.check,
            variant: ButtonVariant.primary,
            isLoading: _isSaving,
            onPressed: _saveHomework,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Header Card
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: CustomTextField(
                        controller: _titleController,
                        label: 'عنوان الواجب الدراسي',
                        hintText: 'مثال: واجب 2: تمارين الدوال والمصفوفات',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تاريخ الاستحقاق',
                            style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _dueDate,
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2027),
                              );
                              if (picked != null) {
                                setState(() => _dueDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.event, size: 16, color: AppColors.yellow),
                                  const SizedBox(width: 8),
                                  Text(DateFormatter.formatDate(_dueDate), style: AppTextStyles.bodyMedium),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Percentage Completion & Batch Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        StatusBadge(
                          label: 'تم الإنجاز: $doneCount / $total',
                          color: AppColors.green,
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(
                          label: 'نسبة الإنجاز: ${completionPct.toStringAsFixed(0)}%',
                          color: completionPct >= 80 ? AppColors.green : AppColors.yellow,
                        ),
                      ],
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.done_all, size: 18, color: AppColors.primary),
                      label: const Text(AppStrings.markAllDone, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      onPressed: () => _markAll('done'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),

          // Students Roster List
          Expanded(
            child: _students.isEmpty
                ? const Center(child: Text('لا يوجد طلاب في هذه المجموعة'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _students.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      final isDone = (_statuses[student.id] ?? 'done') == 'done';

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDone ? AppColors.success.withValues(alpha: 0.3) : AppColors.danger.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Student Name & Code
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    student.studentCode,
                                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),

                            // Done / Not Done Toggle
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => setState(() => _statuses[student.id] = 'done'),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isDone ? AppColors.successBg : AppColors.surfaceMuted,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDone ? AppColors.success : AppColors.border,
                                        width: isDone ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                                          size: 16,
                                          color: isDone ? AppColors.success : AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          AppStrings.statusDone,
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: isDone ? AppColors.success : AppColors.textSecondary,
                                            fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => setState(() => _statuses[student.id] = 'not_done'),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: !isDone ? AppColors.dangerBg : AppColors.surfaceMuted,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: !isDone ? AppColors.danger : AppColors.border,
                                        width: !isDone ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          !isDone ? Icons.cancel : Icons.radio_button_unchecked,
                                          size: 16,
                                          color: !isDone ? AppColors.danger : AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          AppStrings.statusNotDone,
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: !isDone ? AppColors.danger : AppColors.textSecondary,
                                            fontWeight: !isDone ? FontWeight.w700 : FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
