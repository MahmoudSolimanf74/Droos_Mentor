import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/exams_repository.dart';
import '../domain/exam_attempt_model.dart';
import '../domain/exam_model.dart';
import 'create_exam_manual_screen.dart';
import 'student_exam_review_screen.dart';

class ExamResultsScreen extends StatefulWidget {
  final String examId;
  final ExamModel? exam;
  final String? gradeName;

  const ExamResultsScreen({
    super.key,
    required this.examId,
    this.exam,
    this.gradeName,
  });

  @override
  State<ExamResultsScreen> createState() => _ExamResultsScreenState();
}

class _ExamResultsScreenState extends State<ExamResultsScreen> {
  ExamModel? _exam;
  List<ExamAttemptModel> _attempts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _exam = widget.exam;
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    final repo = ExamsRepositoryImpl();
    try {
      final exam = _exam ?? await repo.getExamById(widget.examId);
      final attempts = await repo.getExamAttempts(widget.examId);
      if (mounted) {
        setState(() {
          _exam = exam;
          _attempts = attempts;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToReview(ExamAttemptModel att) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentExamReviewScreen(
          attempt: att,
          exam: _exam,
        ),
      ),
    );
  }

  void _showAttemptDetails(ExamAttemptModel att) {
    final isPassed = att.percentage >= 50.0;
    final scoreColor = isPassed ? AppColors.green : AppColors.red;
    final subTime = att.submittedAt != null
        ? '${att.submittedAt!.year}/${att.submittedAt!.month}/${att.submittedAt!.day} • ${att.submittedAt!.hour}:${att.submittedAt!.minute.toString().padLeft(2, '0')}'
        : 'تم التسليم';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      att.studentName.isNotEmpty ? att.studentName.substring(0, 1) : 'ط',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(att.studentName, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                        Text('كود الطالب: ${att.studentCode}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: '${att.percentage.toInt()}%',
                    color: scoreColor,
                  ),
                ],
              ),
              const Divider(height: 24, color: AppColors.border),
              Text(
                'تفاصيل المحاولة:',
                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الدرجة المحرزة:', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  Text('${att.score.toInt()} من أصل ${att.totalScore.toInt()} درجة', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('النتيجة النهائية:', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  Text(
                    isPassed ? 'ناجح ✅' : 'راسب ❌',
                    style: TextStyle(fontWeight: FontWeight.bold, color: scoreColor),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('تاريخ التسليم:', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  Text(subTime, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: '📄 عرض ورقة إجابة الطالب وتصحيحها',
                onPressed: () {
                  Navigator.pop(ctx);
                  _navigateToReview(att);
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('إغلاق', style: TextStyle(color: AppColors.textSecondary)),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAttempts = _searchQuery.trim().isEmpty
        ? _attempts
        : _attempts.where((a) {
            final q = _searchQuery.trim().toLowerCase();
            return a.studentName.toLowerCase().contains(q) || a.studentCode.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_exam?.title ?? AppStrings.examResults, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            if (widget.gradeName != null)
              Text('المجموعة: ${widget.gradeName}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
        actions: [
          if (_exam != null)
            IconButton(
              icon: const Icon(Icons.edit_note_rounded),
              tooltip: 'تعديل الامتحان والأسئلة',
              onPressed: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateExamManualScreen(examToEdit: _exam),
                  ),
                );
                if (updated == true && mounted) {
                  _loadResults();
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث النتائج',
            onPressed: _loadResults,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : SafeArea(
              child: Column(
                children: [
                  // 1. KPI Summary Card
                  if (_attempts.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildMetricItem('إجمالي الطلاب المُسلّمين', '${_attempts.length}', AppColors.primary),
                            const SizedBox(width: 24),
                            _buildMetricItem(
                              'متوسط الدرجات',
                              '${(_attempts.fold<double>(0.0, (acc, curr) => acc + curr.percentage) / _attempts.length).toStringAsFixed(1)}%',
                              AppColors.cyan,
                            ),
                            const SizedBox(width: 24),
                            _buildMetricItem(
                              'ناجح 🟢',
                              '${_attempts.where((a) => a.percentage >= 50.0).length}',
                              AppColors.green,
                            ),
                            const SizedBox(width: 24),
                            _buildMetricItem(
                              'راسب 🔴',
                              '${_attempts.where((a) => a.percentage < 50.0).length}',
                              AppColors.red,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Search student bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'بحث باسم الطالب أو الكود...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          filled: true,
                          fillColor: AppColors.card,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                        ),
                      ),
                    ),
                  ],

                  // 2. Student Attempts List
                  Expanded(
                    child: _attempts.isEmpty
                        ? EmptyStateView(
                            title: 'لا توجد محاولات مسجلة بعد',
                            subtitle: 'لم يقم أي طالب بتقديم هذا الاختبار حتى الآن',
                            icon: Icons.assignment_turned_in_outlined,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            itemCount: filteredAttempts.length,
                            separatorBuilder: (c, i) => const SizedBox(height: 8),
                            itemBuilder: (ctx, i) {
                              final att = filteredAttempts[i];
                              final pct = att.percentage.toInt();
                              final isPassed = att.percentage >= 50.0;
                              final scoreColor = isPassed ? AppColors.green : AppColors.red;

                              return Container(
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                  onTap: () => _navigateToReview(att),
                                  onLongPress: () => _showAttemptDetails(att),
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: scoreColor.withValues(alpha: 0.15),
                                    child: Text(
                                      att.studentName.isNotEmpty ? att.studentName.substring(0, 1) : 'ط',
                                      style: TextStyle(color: scoreColor, fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          att.studentName,
                                          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Text(
                                        '${att.score.toInt()}/${att.totalScore.toInt()}',
                                        style: AppTextStyles.monoNumber.copyWith(
                                          color: scoreColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Text('كود: ${att.studentCode}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11)),
                                        const Spacer(),
                                        StatusBadge(
                                          label: '$pct% • ${isPassed ? "ناجح" : "راسب"}',
                                          color: scoreColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
                                ),
                              );
                            },
                          ),
                  ),

                  // 3. Bottom Save & Exit Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      border: const Border(top: BorderSide(color: AppColors.border)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -4)),
                      ],
                    ),
                    child: CustomButton(
                      text: '💾 إغلاق ورجوع',
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: AppTextStyles.monoStat.copyWith(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}
