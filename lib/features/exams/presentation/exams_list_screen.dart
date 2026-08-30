import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/status_badge.dart';
import '../../grades/domain/grade_model.dart';
import '../../grades/presentation/grades_cubit.dart';
import '../domain/exam_model.dart';
import 'create_exam_manual_screen.dart';
import 'exam_import_json_screen.dart';
import 'exam_results_screen.dart';
import 'exams_cubit.dart';

class ExamsListScreen extends StatefulWidget {
  const ExamsListScreen({super.key});

  @override
  State<ExamsListScreen> createState() => _ExamsListScreenState();
}

class _ExamsListScreenState extends State<ExamsListScreen> {
  String? _selectedGradeId;

  @override
  void initState() {
    super.initState();
    context.read<GradesCubit>().loadGrades();
    context.read<ExamsCubit>().loadExams();
  }

  void _onGradeChanged(String? gradeId) {
    setState(() => _selectedGradeId = gradeId);
    context.read<ExamsCubit>().loadExams(gradeId: gradeId);
  }

  void _openExamResults(ExamModel exam, String gradeName) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ExamResultsScreen(
          examId: exam.id,
          exam: exam,
          gradeName: gradeName,
        ),
      ),
    );

    if (result == true && mounted) {
      context.read<ExamsCubit>().loadExams(gradeId: _selectedGradeId);
    }
  }

  void _showCreateExamOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إنشاء امتحان جديد', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('اختر طريقة إنشاء وتعبئة أسئلة الامتحان:', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
              ),
              title: const Text('إنشاء يدوي سؤال بسؤال', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('أضف الأسئلة والخيارات والإجابات الصحيحة يدوياً', style: TextStyle(fontSize: 12)),
              onTap: () async {
                Navigator.pop(ctx);
                final res = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateExamManualScreen(initialGradeId: _selectedGradeId),
                  ),
                );
                if (res == true && mounted) {
                  context.read<ExamsCubit>().loadExams(gradeId: _selectedGradeId);
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.cyan.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.cyan),
              ),
              title: const Text('استيراد بالذكاء الاصطناعي / JSON', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('الصق نص الأسئلة أو ملف JSON ليتم بناؤه تلقائياً', style: TextStyle(fontSize: 12)),
              onTap: () async {
                Navigator.pop(ctx);
                final res = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExamImportJsonScreen(),
                  ),
                );
                if (res == true && mounted) {
                  context.read<ExamsCubit>().loadExams(gradeId: _selectedGradeId);
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 36 : 16,
            vertical: isDesktop ? 24 : 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              BlocBuilder<GradesCubit, GradesState>(
                builder: (context, gradesState) {
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.navExams,
                              style: AppTextStyles.displayMedium.copyWith(fontSize: isDesktop ? 24 : 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'إدارة الاختبارات والتقييمات ومتابعة درجات الطلاب',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 12, vertical: isDesktop ? 12 : 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('امتحان جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: _showCreateExamOptions,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),

              // Group Filter Bar
              BlocBuilder<GradesCubit, GradesState>(
                builder: (context, gradesState) {
                  final grades = gradesState is GradesLoaded ? gradesState.grades : <GradeModel>[];
                  if (grades.isEmpty) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('جميع المجموعات'),
                            selected: _selectedGradeId == null,
                            selectedColor: AppColors.primary.withValues(alpha: 0.25),
                            backgroundColor: AppColors.card,
                            side: BorderSide(
                              color: _selectedGradeId == null ? AppColors.primary : AppColors.border,
                            ),
                            labelStyle: TextStyle(
                              color: _selectedGradeId == null ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: _selectedGradeId == null ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (_) => _onGradeChanged(null),
                          ),
                          const SizedBox(width: 8),
                          ...grades.map((grade) {
                            final isSel = _selectedGradeId == grade.id;
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ChoiceChip(
                                label: Text(grade.name),
                                selected: isSel,
                                selectedColor: grade.color.withValues(alpha: 0.25),
                                backgroundColor: AppColors.card,
                                side: BorderSide(
                                  color: isSel ? grade.color : AppColors.border,
                                ),
                                labelStyle: TextStyle(
                                  color: isSel ? grade.color : AppColors.textSecondary,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                                onSelected: (_) => _onGradeChanged(grade.id),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Exams List
              Expanded(
                child: BlocBuilder<ExamsCubit, ExamsState>(
                  builder: (context, state) {
                    if (state is ExamsLoading) {
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                    }

                    if (state is ExamsError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 48),
                            const SizedBox(height: 12),
                            Text(state.message, style: AppTextStyles.bodyMedium),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: () => context.read<ExamsCubit>().loadExams(gradeId: _selectedGradeId),
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is ExamsLoaded) {
                      final exams = state.exams;
                      final gradesState = context.read<GradesCubit>().state;
                      final grades = gradesState is GradesLoaded ? gradesState.grades : <GradeModel>[];

                      if (exams.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.quiz_outlined, color: AppColors.textFaint, size: 54),
                              const SizedBox(height: 14),
                              Text('لا توجد امتحانات مضافة لهذه المجموعة بعد', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              Text(
                                'اضغط على زر "امتحان جديد" لإنشاء أول امتحان ومتابعته',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textFaint),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                                icon: const Icon(Icons.add),
                                label: const Text('إنشاء امتحان الآن', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: _showCreateExamOptions,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: exams.length,
                        separatorBuilder: (context, i) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final exam = exams[i];
                          final grade = grades.firstWhere(
                            (g) => g.id == exam.gradeId,
                            orElse: () => GradeModel(id: '', name: 'المجموعة', code: '', createdAt: DateTime.now()),
                          );

                          return _buildExamCard(exam, grade.name);
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamCard(ExamModel exam, String gradeName) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openExamResults(exam, gradeName),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title + Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.quiz_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exam.title,
                            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'المجموعة: $gradeName',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                      color: AppColors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      onSelected: (val) async {
                        if (val == 'edit') {
                          final updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateExamManualScreen(examToEdit: exam),
                            ),
                          );
                          if (updated == true && mounted) {
                            context.read<ExamsCubit>().loadExams(gradeId: _selectedGradeId);
                          }
                        } else if (val == 'toggle') {
                          await context.read<ExamsCubit>().toggleActive(exam.id, !exam.isActive);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(exam.isActive ? 'تم إخفاء الامتحان عن الطلاب 🟡' : 'تم نشر الامتحان للطلاب بنجاح 🟢'),
                                backgroundColor: exam.isActive ? AppColors.yellow : AppColors.green,
                              ),
                            );
                          }
                        } else if (val == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.card,
                              title: const Text('حذف الامتحان'),
                              content: Text('هل أنت متأكد من رغبتك في حذف امتحان "${exam.title}" وجميع محاولات ونتائج الطلاب المسجلة؟'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && mounted) {
                            context.read<ExamsCubit>().deleteExam(exam.id);
                          }
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text('تعديل الامتحان والأسئلة'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                exam.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 18,
                                color: exam.isActive ? AppColors.yellow : AppColors.green,
                              ),
                              SizedBox(width: 8),
                              Text(exam.isActive ? 'إخفاء عن الطلاب' : 'إظهار ونشر للطلاب'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.red),
                              SizedBox(width: 8),
                              Text('حذف الامتحان', style: TextStyle(color: AppColors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Badges Info Wrap
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusBadge(
                      label: exam.isActive ? 'منشور للطلاب 🟢' : 'مخفي عن الطلاب 🟡',
                      color: exam.isActive ? AppColors.green : AppColors.yellow,
                    ),
                    StatusBadge(
                      label: '${exam.questionsCount} أسئلة',
                      color: AppColors.cyan,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${exam.durationMinutes} دقيقة',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),

                // Bottom Action & Submissions Bar
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_alt_rounded, size: 14, color: AppColors.green),
                          const SizedBox(width: 6),
                          Text(
                            '${exam.attemptsCount} طالب سلّم الاختبار',
                            style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          'عرض النتائج',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
