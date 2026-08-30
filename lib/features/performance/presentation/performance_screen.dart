import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../grades/domain/grade_model.dart';
import '../../grades/presentation/grades_cubit.dart';
import '../../students/presentation/students_cubit.dart';
import 'spreadsheet_table_widget.dart';

class PerformanceScreen extends StatefulWidget {
  final String? initialGroupId;

  const PerformanceScreen({super.key, this.initialGroupId});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  String? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.initialGroupId;
    context.read<GradesCubit>().loadGrades();
    final gradesState = context.read<GradesCubit>().state;
    if (_selectedGroupId == null && gradesState is GradesLoaded && gradesState.grades.isNotEmpty) {
      _selectedGroupId = gradesState.grades.first.id;
      context.read<StudentsCubit>().loadStudents(_selectedGroupId!, null);
    } else if (gradesState is GradesLoaded && gradesState.grades.isEmpty) {
      context.read<StudentsCubit>().loadStudents(null, null);
    }
  }

  void _onGroupChanged(String groupId) {
    setState(() => _selectedGroupId = groupId);
    context.read<StudentsCubit>().loadStudents(groupId, null);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return BlocListener<GradesCubit, GradesState>(
      listener: (context, state) {
        if (state is GradesLoaded) {
          if (state.grades.isNotEmpty) {
            if (_selectedGroupId == null || !state.grades.any((g) => g.id == _selectedGroupId)) {
              _onGroupChanged(state.grades.first.id);
            }
          } else {
            setState(() => _selectedGroupId = null);
            context.read<StudentsCubit>().loadStudents(null, null);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 36 : 16,
              vertical: isDesktop ? 24 : 14,
            ),
            child: BlocBuilder<GradesCubit, GradesState>(
              builder: (context, gradesState) {
                final grades = gradesState is GradesLoaded ? gradesState.grades : <GradeModel>[];

                if (grades.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.table_chart_outlined, size: 54, color: AppColors.primary),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد مجموعات أو طلاب بعد',
                            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'قم بإنشاء مجموعة وإضافة طلاب لعرض جدول الأداء والتقييم الشامل',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Page Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.performanceMatrix,
                              style: AppTextStyles.displayMedium.copyWith(fontSize: isDesktop ? 24 : 20),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'عرض تحليلي شامل لمستويات حضور واختبارات وواجبات الطلاب',
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Group Selector Bar
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: grades.map((g) {
                          final isSelected = _selectedGroupId == g.id;
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ChoiceChip(
                              label: Text(g.name),
                              selected: isSelected,
                              selectedColor: g.color.withValues(alpha: 0.25),
                              backgroundColor: AppColors.card,
                              side: BorderSide(color: isSelected ? g.color : AppColors.border),
                              labelStyle: TextStyle(
                                color: isSelected ? g.color : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 13,
                              ),
                              onSelected: (_) => _onGroupChanged(g.id),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Spreadsheet Table
                    Expanded(
                      child: BlocBuilder<StudentsCubit, StudentsState>(
                        builder: (context, state) {
                          if (state is StudentsLoading) {
                            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                          } else if (state is StudentsLoaded) {
                            final students = state.students;
                            if (students.isEmpty) {
                              return Center(
                                child: Text(
                                  'لا يوجد طلاب مسجلون في هذه المجموعة بعد',
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                ),
                              );
                            }
                            return SpreadsheetTableWidget(
                              groupId: _selectedGroupId ?? '',
                              students: students,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
