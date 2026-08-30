import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../domain/student_model.dart';
import 'students_cubit.dart';
import 'widgets/add_student_dialog.dart';

class StudentsTabView extends StatefulWidget {
  final String groupId;

  const StudentsTabView({super.key, required this.groupId});

  @override
  State<StudentsTabView> createState() => _StudentsTabViewState();
}

class _StudentsTabViewState extends State<StudentsTabView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<StudentsCubit>().loadStudents(widget.groupId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmRemoveStudent(StudentModel student) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: AppStrings.removeStudent,
      message: 'هل أنت متأكد من استبعاد الطالب (${student.name}) من هذه المجموعة؟',
      isDangerous: true,
      confirmText: 'استبعاد',
    );
    if (confirmed == true && mounted) {
      context.read<StudentsCubit>().removeStudent(student.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudentsCubit, StudentsState>(
      builder: (context, state) {
        if (state is StudentsLoading) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.sage),
            ),
          );
        } else if (state is StudentsError) {
          return ErrorView(
            message: state.message,
            onRetry: () => context.read<StudentsCubit>().loadStudents(widget.groupId),
          );
        } else if (state is StudentsLoaded) {
          final students = state.displayedStudents;

          return Column(
            children: [
              // Search, Filter & Add Header
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _searchController,
                        hintText: 'بحث باسم الطالب أو الكود...',
                        prefixIcon: Icons.search,
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  context.read<StudentsCubit>().search('');
                                },
                              )
                            : null,
                        onChanged: (val) => context.read<StudentsCubit>().search(val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CustomButton(
                      text: AppStrings.addStudent,
                      icon: Icons.person_add_alt_1,
                      onPressed: () {
                        AddStudentDialog.show(
                          context,
                          onSubmit: ({required name, email, parentPhone, phone}) {
                            context.read<StudentsCubit>().addStudent(
                                  name: name,
                                  phone: phone,
                                  parentPhone: parentPhone,
                                  email: email,
                                );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.border, height: 1),

              // Spreadsheet Header / Sort Bar
              Container(
                color: AppColors.tableHeaderBg,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: InkWell(
                        onTap: () => context.read<StudentsCubit>().sort(StudentSortColumn.name),
                        child: Row(
                          children: [
                            Text(
                              AppStrings.studentName,
                              style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              state.sortColumn == StudentSortColumn.name
                                  ? (state.isAscending ? Icons.arrow_upward : Icons.arrow_downward)
                                  : Icons.unfold_more,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () => context.read<StudentsCubit>().sort(StudentSortColumn.attendance),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'الحضور',
                              style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              state.sortColumn == StudentSortColumn.attendance
                                  ? (state.isAscending ? Icons.arrow_upward : Icons.arrow_downward)
                                  : Icons.unfold_more,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () => context.read<StudentsCubit>().sort(StudentSortColumn.homework),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'الواجبات',
                              style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              state.sortColumn == StudentSortColumn.homework
                                  ? (state.isAscending ? Icons.arrow_upward : Icons.arrow_downward)
                                  : Icons.unfold_more,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () => context.read<StudentsCubit>().sort(StudentSortColumn.examAverage),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'الاختبارات',
                              style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              state.sortColumn == StudentSortColumn.examAverage
                                  ? (state.isAscending ? Icons.arrow_upward : Icons.arrow_downward)
                                  : Icons.unfold_more,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              const Divider(color: AppColors.border, height: 1),

              // Student Rows List
              Expanded(
                child: students.isEmpty
                    ? EmptyStateView(
                        title: 'لا يوجد طلاب في هذه المجموعة بعد',
                        subtitle: 'أضف أول طالب أو شارك رمز الانضمام مع طلابك',
                        icon: Icons.people_outline,
                      )
                    : ListView.separated(
                        itemCount: students.length,
                        separatorBuilder: (ctx, idx) => const Divider(color: AppColors.border, height: 1),
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final isEven = index % 2 == 0;

                          return Container(
                            color: isEven ? AppColors.surface : AppColors.tableRowAlt,
                            child: InkWell(
                              onTap: () => context.goNamed(
                                RouteNames.studentDetails,
                                pathParameters: {
                                  'groupId': widget.groupId,
                                  'studentId': student.id,
                                },
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    // Student Name & Code
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student.name,
                                            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Text(
                                                student.studentCode,
                                                style: AppTextStyles.labelSmall.copyWith(
                                                  color: AppColors.textMuted,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if (student.phone != null) ...[
                                                const SizedBox(width: 8),
                                                Text(
                                                  '•  ${student.phone}',
                                                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Attendance Rate
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: StatusBadge(
                                          label: '${student.attendanceRate.toStringAsFixed(0)}%',
                                          variant: student.attendanceRate >= 85
                                              ? BadgeVariant.success
                                              : (student.attendanceRate >= 70 ? BadgeVariant.warning : BadgeVariant.danger),
                                        ),
                                      ),
                                    ),

                                    // Homework Rate
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: StatusBadge(
                                          label: '${student.homeworkRate.toStringAsFixed(0)}%',
                                          variant: student.homeworkRate >= 85
                                              ? BadgeVariant.success
                                              : (student.homeworkRate >= 60 ? BadgeVariant.warning : BadgeVariant.danger),
                                        ),
                                      ),
                                    ),

                                    // Exam Average
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: Text(
                                          student.examAverage.toStringAsFixed(1),
                                          style: AppTextStyles.monoNumber.copyWith(
                                            color: student.examAverage >= 85
                                                ? AppColors.primary
                                                : (student.examAverage >= 70 ? AppColors.warning : AppColors.danger),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Action Menu
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                                      onSelected: (val) {
                                        if (val == 'view') {
                                          context.goNamed(
                                            RouteNames.studentDetails,
                                            pathParameters: {
                                              'groupId': widget.groupId,
                                              'studentId': student.id,
                                            },
                                          );
                                        } else if (val == 'remove') {
                                          _confirmRemoveStudent(student);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'view',
                                          child: Row(
                                            children: [
                                              Icon(Icons.visibility_outlined, size: 18),
                                              SizedBox(width: 8),
                                              Text(AppStrings.viewDetails),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'remove',
                                          child: Row(
                                            children: [
                                              Icon(Icons.person_remove_outlined, size: 18, color: AppColors.danger),
                                              SizedBox(width: 8),
                                              Text(AppStrings.removeStudent, style: TextStyle(color: AppColors.danger)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
