import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/kpi_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../attendance/presentation/attendance_cubit.dart';
import '../../exams/presentation/exams_cubit.dart';
import '../../homework/presentation/homework_cubit.dart';
import '../../performance/presentation/spreadsheet_table_widget.dart';
import '../../students/presentation/students_cubit.dart';
import '../../students/presentation/students_tab_view.dart';
import '../data/groups_repository.dart';
import '../domain/group_model.dart';
import 'groups_cubit.dart';
import 'widgets/create_group_dialog.dart';
import 'widgets/group_qr_dialog.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  GroupModel? _group;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroup();
    context.read<StudentsCubit>().loadStudents(widget.groupId);
    context.read<AttendanceCubit>().loadSessions(groupId: widget.groupId);
    context.read<HomeworkCubit>().loadHomeworks(groupId: widget.groupId);
    context.read<ExamsCubit>().loadExams(groupId: widget.groupId);
  }

  Future<void> _loadGroup() async {
    final repo = GroupsRepositoryImpl();
    try {
      final g = await repo.getGroupById(widget.groupId);
      if (mounted) {
        setState(() {
          _group = g;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.sage),
          ),
        ),
      );
    }

    if (_group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل المجموعة')),
        body: const Center(child: Text('المجموعة غير موجودة')),
      );
    }

    final group = _group!;

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(group.name, style: AppTextStyles.titleLarge),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code),
              tooltip: 'رمز QR',
              onPressed: () {
                GroupQrDialog.show(
                  context,
                  group: group,
                  onRegenerateToken: () async {
                    final token = await context.read<GroupsCubit>().regenerateQrToken(group.id);
                    _loadGroup();
                    return token;
                  },
                  onToggleActive: (isActive) async {
                    await context.read<GroupsCubit>().toggleActive(group.id, isActive);
                    _loadGroup();
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: AppStrings.editGroup,
              onPressed: () {
                CreateGroupDialog.show(
                  context,
                  initialGroup: group,
                  onSubmit: (name, gradeId) async {
                    await context.read<GroupsCubit>().updateGroup(
                          groupId: group.id,
                          name: name,
                          gradeId: gradeId,
                        );
                    _loadGroup();
                  },
                );
              },
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: AppStrings.tabOverview),
              Tab(text: AppStrings.tabStudents),
              Tab(text: AppStrings.tabAttendance),
              Tab(text: AppStrings.tabHomework),
              Tab(text: AppStrings.tabExams),
              Tab(text: AppStrings.tabPerformance),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. Overview Tab
            _buildOverviewTab(context, group),

            // 2. Students Tab
            StudentsTabView(groupId: widget.groupId),

            // 3. Attendance Tab
            _buildAttendanceTab(context),

            // 4. Homework Tab
            _buildHomeworkTab(context),

            // 5. Exams Tab
            _buildExamsTab(context),

            // 6. Performance Matrix Tab (Spreadsheet)
            _buildPerformanceTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, GroupModel group) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(group.gradeName, style: AppTextStyles.bodyMedium),
                  ],
                ),
                StatusBadge(
                  label: group.isActive ? AppStrings.statusActive : AppStrings.statusInactive,
                  variant: group.isActive ? BadgeVariant.success : BadgeVariant.danger,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // KPIs
          BlocBuilder<StudentsCubit, StudentsState>(
            builder: (context, stdState) {
              final count = stdState is StudentsLoaded ? stdState.allStudents.length : group.studentsCount;

              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  KpiCard(
                    title: 'عدد الطلاب',
                    value: '$count',
                    icon: Icons.people_outline,
                    iconColor: AppColors.primary,
                  ),
                  KpiCard(
                    title: 'كود الانضمام',
                    value: group.joinCode,
                    icon: Icons.key_outlined,
                    iconColor: AppColors.sage,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Quick Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.how_to_reg_outlined, size: 18),
                  label: const Text('تسجيل حضور اليوم'),
                  onPressed: () => context.goNamed(
                    RouteNames.takeAttendance,
                    pathParameters: {'groupId': widget.groupId},
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.qr_code, size: 18),
                  label: const Text('عرض رمز QR'),
                  onPressed: () {
                    GroupQrDialog.show(
                      context,
                      group: group,
                      onRegenerateToken: () async {
                        final token = await context.read<GroupsCubit>().regenerateQrToken(group.id);
                        _loadGroup();
                        return token;
                      },
                      onToggleActive: (isActive) async {
                        await context.read<GroupsCubit>().toggleActive(group.id, isActive);
                        _loadGroup();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab(BuildContext context) {
    return BlocBuilder<AttendanceCubit, AttendanceState>(
      builder: (context, state) {
        if (state is AttendanceLoading) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.sage)));
        } else if (state is AttendanceLoaded) {
          final sessions = state.displayedSessions;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('جلسات الحضور السابقة (${sessions.length})', style: AppTextStyles.titleSmall),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('جلسة جديدة'),
                      onPressed: () => context.goNamed(
                        RouteNames.takeAttendance,
                        pathParameters: {'groupId': widget.groupId},
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.border, height: 1),
              Expanded(
                child: sessions.isEmpty
                    ? const Center(child: Text('لا توجد جلسات حضور مسجلة بعد'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: sessions.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final sess = sessions[index];
                          return Card(
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.sageLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.how_to_reg, size: 20, color: AppColors.sageDark),
                              ),
                              title: Text(sess.title, style: AppTextStyles.titleSmall),
                              subtitle: Text(
                                'التاريخ: ${sess.sessionDate.toIso8601String().split('T').first}  •  حاضر: ${sess.presentCount}  •  غائب: ${sess.absentCount}',
                                style: AppTextStyles.bodySmall,
                              ),
                              trailing: StatusBadge(
                                label: '${sess.attendanceRate.toStringAsFixed(0)}%',
                                variant: sess.attendanceRate >= 80 ? BadgeVariant.success : BadgeVariant.warning,
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

  Widget _buildHomeworkTab(BuildContext context) {
    return BlocBuilder<HomeworkCubit, HomeworkState>(
      builder: (context, state) {
        if (state is HomeworkLoading) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.sage)));
        } else if (state is HomeworkLoaded) {
          final homeworks = state.displayedHomeworks;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('قائمة الواجبات (${homeworks.length})', style: AppTextStyles.titleSmall),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('رصد واجب جديد'),
                      onPressed: () => context.goNamed(
                        RouteNames.markHomework,
                        pathParameters: {'groupId': widget.groupId, 'homeworkId': 'new'},
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.border, height: 1),
              Expanded(
                child: homeworks.isEmpty
                    ? const Center(child: Text('لا توجد واجبات مرصودة بعد'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: homeworks.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final hw = homeworks[index];
                          return Card(
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.bronzeLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.assignment_turned_in_outlined, size: 20, color: AppColors.bronzeDark),
                              ),
                              title: Text(hw.title, style: AppTextStyles.titleSmall),
                              subtitle: Text(
                                'تاريخ الاستحقاق: ${hw.dueDate?.toIso8601String().split('T').first ?? '-'}  •  أنجز: ${hw.completedCount}/${hw.totalStudents}',
                                style: AppTextStyles.bodySmall,
                              ),
                              trailing: StatusBadge(
                                label: '${hw.completionRate.toStringAsFixed(0)}%',
                                variant: hw.completionRate >= 80 ? BadgeVariant.success : BadgeVariant.warning,
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

  Widget _buildExamsTab(BuildContext context) {
    return BlocBuilder<ExamsCubit, ExamsState>(
      builder: (context, state) {
        if (state is ExamsLoading) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.sage)));
        } else if (state is ExamsLoaded) {
          final exams = state.displayedExams;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الاختبارات (${exams.length})', style: AppTextStyles.titleSmall),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.file_upload_outlined, size: 18),
                      label: const Text('استيراد JSON'),
                      onPressed: () => context.goNamed(RouteNames.examImport),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.border, height: 1),
              Expanded(
                child: exams.isEmpty
                    ? const Center(child: Text('لا توجد اختبارات مسجلة'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: exams.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final exam = exams[index];
                          return Card(
                            child: ListTile(
                              onTap: () => context.goNamed(
                                RouteNames.examResults,
                                pathParameters: {'id': exam.id},
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.infoBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.assignment_outlined, size: 20, color: AppColors.info),
                              ),
                              title: Text(exam.title, style: AppTextStyles.titleSmall),
                              subtitle: Text(
                                'المدة: ${exam.durationMinutes} دقيقة  •  عدد الأسئلة: ${exam.questionsCount}',
                                style: AppTextStyles.bodySmall,
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
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

  Widget _buildPerformanceTab(BuildContext context) {
    return BlocBuilder<StudentsCubit, StudentsState>(
      builder: (context, state) {
        if (state is StudentsLoading) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.sage)));
        } else if (state is StudentsLoaded) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SpreadsheetTableWidget(
              groupId: widget.groupId,
              students: state.allStudents,
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
