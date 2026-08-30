import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../students/domain/student_model.dart';

class SpreadsheetTableWidget extends StatelessWidget {
  final String groupId;
  final List<StudentModel> students;

  const SpreadsheetTableWidget({
    super.key,
    required this.groupId,
    required this.students,
  });

  Color _getScoreColor(double v) {
    if (v >= 80) return AppColors.green;
    if (v >= 60) return AppColors.yellow;
    return AppColors.red;
  }

  double _getAverage(StudentModel s) {
    final total = (s.attendanceRate * 0.3) + (s.homeworkRate * 0.2) + (s.examAverage * 0.5);
    return total.roundToDouble();
  }

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline_rounded, size: 54, color: AppColors.textFaint),
            const SizedBox(height: 12),
            Text(
              'لا يوجد طلاب مسجلون في هذه المجموعة بعد',
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table Container with horizontal and vertical scrolling
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.tableHeaderBg),
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 52,
                  horizontalMargin: 16,
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(
                      label: Text('اسم الطالب', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    DataColumn(
                      label: Text('كود الطالب', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    DataColumn(
                      label: Text('نسبة الحضور', style: TextStyle(fontWeight: FontWeight.w700)),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text('تسليم الواجبات', style: TextStyle(fontWeight: FontWeight.w700)),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text('متوسط الاختبارات', style: TextStyle(fontWeight: FontWeight.w700)),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text('المتوسط الموزون', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                      numeric: true,
                    ),
                  ],
                  rows: students.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final s = entry.value;
                    final isEven = idx % 2 == 0;
                    final avg = _getAverage(s);
                    final avgColor = _getScoreColor(avg);

                    return DataRow(
                      color: WidgetStateProperty.all(isEven ? AppColors.card : AppColors.tableRowAlt),
                      cells: [
                        // 1. Student Identity
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                child: Text(
                                  s.name.isNotEmpty ? s.name.substring(0, 1) : 'ط',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                s.name,
                                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        // 2. Student Code
                        DataCell(
                          Text(
                            s.studentCode,
                            style: AppTextStyles.monoNumber.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        // 3. Attendance %
                        DataCell(
                          Text(
                            '${s.attendanceRate.toInt()}%',
                            style: AppTextStyles.monoNumber.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _getScoreColor(s.attendanceRate),
                            ),
                          ),
                        ),
                        // 4. Homework %
                        DataCell(
                          Text(
                            '${s.homeworkRate.toInt()}%',
                            style: AppTextStyles.monoNumber.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _getScoreColor(s.homeworkRate),
                            ),
                          ),
                        ),
                        // 5. Exam Average %
                        DataCell(
                          Text(
                            '${s.examAverage.toInt()}%',
                            style: AppTextStyles.monoNumber.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _getScoreColor(s.examAverage),
                            ),
                          ),
                        ),
                        // 6. Total Weighted Average %
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: avgColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${avg.toInt()}%',
                              style: AppTextStyles.monoNumber.copyWith(
                                fontWeight: FontWeight.w800,
                                color: avgColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Color Legend
        Row(
          children: [
            _buildLegendItem(AppColors.green, 'ممتاز (80%+)'),
            const SizedBox(width: 16),
            _buildLegendItem(AppColors.yellow, 'متوسط (60-79%)'),
            const SizedBox(width: 16),
            _buildLegendItem(AppColors.red, 'ضعيف (أقل من 60%)'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
