import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/kpi_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../exams/presentation/student_exam_review_screen.dart';
import '../data/students_repository.dart';
import '../domain/student_model.dart';
import 'students_cubit.dart';

class StudentDetailsScreen extends StatefulWidget {
  final String groupId;
  final String studentId;

  const StudentDetailsScreen({
    super.key,
    required this.groupId,
    required this.studentId,
  });

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  StudentModel? _student;
  List<Map<String, dynamic>> _attendanceHistory = [];
  List<Map<String, dynamic>> _homeworkHistory = [];
  List<Map<String, dynamic>> _examAttempts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = StudentsRepositoryImpl();
    try {
      final student = await repo.getStudentDetails(widget.studentId);
      final att = await repo.getStudentAttendanceHistory(widget.studentId);
      final hw = await repo.getStudentHomeworkHistory(widget.studentId);
      final exams = await repo.getStudentExamAttempts(widget.studentId);

      if (mounted) {
        setState(() {
          _student = student;
          _attendanceHistory = att;
          _homeworkHistory = hw;
          _examAttempts = exams;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _removeStudent() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: AppStrings.removeStudent,
      message: 'هل أنت متأكد من استبعاد الطالب من المجموعة؟',
      isDangerous: true,
      confirmText: 'استبعاد',
    );
    if (confirmed == true && mounted) {
      await context.read<StudentsCubit>().removeStudent(widget.studentId);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (_student == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('الملف التعريفي للطالب')),
        body: const Center(child: Text('تعذر العثور على بيانات الطالب')),
      );
    }

    final s = _student!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(s.name, style: AppTextStyles.titleLarge),
          actions: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.green),
              tooltip: 'مشاركة التقرير عبر واتساب',
              onPressed: () => WhatsAppHelper.shareStudentReport(
                context: context,
                student: s,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.person_remove_outlined, color: AppColors.red),
              tooltip: AppStrings.removeStudent,
              onPressed: _removeStudent,
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'سجل الحضور'),
              Tab(text: 'سجل الواجبات'),
              Tab(text: 'نتائج الاختبارات'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Student Overview Profile Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryDim,
                        child: Text(
                          s.name.isNotEmpty ? s.name.substring(0, 1) : 'ط',
                          style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'كود الطالب: ${s.studentCode}',
                              style: AppTextStyles.monoNumber.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        label: s.status == 'active' ? AppStrings.statusActive : AppStrings.statusInactive,
                        color: s.status == 'active' ? AppColors.green : AppColors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 12),
                  // Contact Details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 16, color: AppColors.cyan),
                          const SizedBox(width: 6),
                          Text(s.phone ?? 'بدون هاتف', style: AppTextStyles.monoNumber.copyWith(fontSize: 12)),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.contact_phone_outlined, size: 16, color: AppColors.yellow),
                          const SizedBox(width: 6),
                          Text(s.parentPhone ?? 'بدون هاتف ولي أمر', style: AppTextStyles.monoNumber.copyWith(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      label: const Text('مشاركة تقرير المتابعة عبر واتساب لولي الأمر', style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () => WhatsAppHelper.shareStudentReport(
                        context: context,
                        student: s,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Performance KPI Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: KpiCard(
                      title: 'نسبة الحضور',
                      value: '${s.attendanceRate.toStringAsFixed(0)}%',
                      icon: Icons.how_to_reg_outlined,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: KpiCard(
                      title: 'إنجاز الواجبات',
                      value: '${s.homeworkRate.toStringAsFixed(0)}%',
                      icon: Icons.assignment_turned_in_outlined,
                      color: AppColors.yellow,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: KpiCard(
                      title: 'متوسط الاختبارات',
                      value: s.examAverage.toStringAsFixed(1),
                      icon: Icons.grade_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  _buildAttendanceTab(),
                  _buildHomeworkTab(),
                  _buildExamsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTab() {
    if (_attendanceHistory.isEmpty) {
      return Center(
        child: Text('لا توجد سجلات حضور مسجلة لهذا الطالب', style: AppTextStyles.bodyMedium),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _attendanceHistory.length,
      separatorBuilder: (c, i) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final item = _attendanceHistory[i];
        final status = item['status'] as String? ?? 'present';

        final badge = switch (status) {
          'present' => const StatusBadge(label: 'حاضر', color: AppColors.green),
          'late' => const StatusBadge(label: 'متأخر', color: AppColors.yellow),
          _ => const StatusBadge(label: 'غائب', color: AppColors.red),
        };

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['lesson_title'] as String? ?? 'حصة بدون عنوان',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item['date'] as String? ?? '',
                    style: AppTextStyles.monoNumber.copyWith(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
              badge,
            ],
          ),
        );
      },
    );
  }

  Widget _buildHomeworkTab() {
    if (_homeworkHistory.isEmpty) {
      return Center(
        child: Text('لا توجد واجبات مسجلة لهذا الطالب', style: AppTextStyles.bodyMedium),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _homeworkHistory.length,
      separatorBuilder: (c, i) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final item = _homeworkHistory[i];
        final done = item['done'] == true;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String? ?? 'واجب بدون عنوان',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'تاريخ التسليم: ${item['due_date'] ?? '—'}',
                    style: AppTextStyles.monoNumber.copyWith(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
              StatusBadge(
                label: done ? 'تم الإنجاز' : 'لم ينجز',
                color: done ? AppColors.green : AppColors.red,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExamsTab() {
    if (_examAttempts.isEmpty) {
      return Center(
        child: Text('لا توجد نتائج اختبارات مسجلة لهذا الطالب', style: AppTextStyles.bodyMedium),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _examAttempts.length,
      separatorBuilder: (c, i) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final item = _examAttempts[i];
        final score = (item['score'] as num?)?.toDouble() ?? 0.0;
        final total = (item['total'] as num?)?.toDouble() ?? (item['total_score'] as num?)?.toDouble() ?? 100.0;
        final pct = (item['percentage'] as num?)?.toDouble() ?? (total > 0 ? (score / total) * 100 : 0);
        final scoreColor = pct >= 80 ? AppColors.green : (pct >= 60 ? AppColors.yellow : AppColors.red);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentExamReviewScreen(
                      attemptMap: {
                        ...item,
                        'student_name': _student?.name ?? 'طالب',
                        'student_code': _student?.studentCode ?? 'STU-000',
                      },
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String? ?? 'اختبار',
                            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'الدرجة: ${score.toInt()}/${total.toInt()}',
                            style: AppTextStyles.monoNumber.copyWith(color: scoreColor, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        StatusBadge(
                          label: '${pct.toInt()}%',
                          color: scoreColor,
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_left_rounded, size: 20, color: AppColors.textSecondary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
