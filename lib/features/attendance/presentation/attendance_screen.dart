import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/status_badge.dart';
import '../../grades/domain/grade_model.dart';
import '../../grades/presentation/grades_cubit.dart';
import '../domain/attendance_session_model.dart';
import 'attendance_cubit.dart';
import 'attendance_session_detail_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _selectedGradeId;

  @override
  void initState() {
    super.initState();
    context.read<GradesCubit>().loadGrades();
    final gradesState = context.read<GradesCubit>().state;
    if (gradesState is GradesLoaded && gradesState.grades.isNotEmpty) {
      _selectedGradeId = gradesState.grades.first.id;
      context.read<AttendanceCubit>().loadSessions(groupId: _selectedGradeId);
    }
  }

  void _onGradeChanged(String gradeId) {
    setState(() {
      _selectedGradeId = gradeId;
    });
    context.read<AttendanceCubit>().loadSessions(groupId: gradeId);
  }

  void _openSessionDetail(AttendanceSessionModel? session, String gradeName) async {
    if (_selectedGradeId == null) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceSessionDetailScreen(
          session: session,
          gradeId: _selectedGradeId!,
          gradeName: gradeName,
        ),
      ),
    );

    if (result == true && mounted && _selectedGradeId != null) {
      context.read<AttendanceCubit>().loadSessions(groupId: _selectedGradeId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return BlocListener<GradesCubit, GradesState>(
      listener: (context, state) {
        if (state is GradesLoaded) {
          if (state.grades.isNotEmpty) {
            if (_selectedGradeId == null || !state.grades.any((g) => g.id == _selectedGradeId)) {
              _onGradeChanged(state.grades.first.id);
            }
          } else {
            setState(() => _selectedGradeId = null);
            context.read<AttendanceCubit>().loadSessions(groupId: null);
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
                              color: AppColors.green.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.how_to_reg_outlined, size: 54, color: AppColors.green),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد مجموعات دراسية بعد',
                            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'يرجى إنشاء مجموعة دراسية أولاً لتسجيل الحضور والغياب للطلاب',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final currentGrade = grades.firstWhere(
                  (g) => g.id == _selectedGradeId,
                  orElse: () => grades.first,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Page Header & Create Button
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.navAttendance,
                                style: AppTextStyles.displayMedium.copyWith(fontSize: isDesktop ? 24 : 18),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'اختر الحصة لتسجيل الحضور',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
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
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 12, vertical: isDesktop ? 12 : 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                          label: Text(isDesktop ? 'تسجيل حصة جديدة' : 'حصة جديدة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: _selectedGradeId == null
                              ? null
                              : () => _openSessionDetail(null, currentGrade.name),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Grade Selector Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: grades.map((g) {
                          final isSelected = _selectedGradeId == g.id;
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
                              onSelected: (_) => _onGradeChanged(g.id),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),

                // Sessions List Grid/List View
                Expanded(
                  child: BlocBuilder<AttendanceCubit, AttendanceState>(
                    builder: (context, state) {
                      if (state is AttendanceLoading) {
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                      } else if (state is AttendanceLoaded) {
                        final sessions = state.sessions;
                        final gradesState = context.read<GradesCubit>().state;
                        final grades = gradesState is GradesLoaded ? gradesState.grades : <GradeModel>[];
                        final currentGrade = grades.firstWhere(
                          (g) => g.id == _selectedGradeId,
                          orElse: () => GradeModel(id: '', name: 'المجموعة', code: '', createdAt: DateTime.now()),
                        );

                        if (sessions.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.event_available_rounded, size: 54, color: AppColors.primary),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'لا توجد حصص حضور مسجلة لهذه المجموعة',
                                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'اضغط على زر "تسجيل حصة جديدة" بالأعلى لتسجيل حضور الطلاب',
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.black,
                                  ),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('تسجيل أول حصة الآن', style: TextStyle(fontWeight: FontWeight.bold)),
                                  onPressed: _selectedGradeId == null
                                      ? null
                                      : () => _openSessionDetail(null, currentGrade.name),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: sessions.length,
                          separatorBuilder: (context, i) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final s = sessions[i];
                            return _buildSessionCard(s, currentGrade.name);
                          },
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

  Widget _buildSessionCard(AttendanceSessionModel session, String gradeName) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => _openSessionDetail(session, gradeName),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.how_to_reg_rounded, color: AppColors.green, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                session.title,
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            StatusBadge(
              label: 'حاضر: ${session.presentCount}',
              color: AppColors.green,
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${session.sessionDate.year}/${session.sessionDate.month}/${session.sessionDate.day}',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
              ),
              const Spacer(),
              Text(
                'تسجيل الحضور ⬅',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red, size: 20),
          tooltip: 'حذف الحصة',
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.card,
                title: const Text('حذف حصة الحضور'),
                content: Text('هل أنت متأكد من رغبتك في حذف حصة "${session.title}" وجميع سجلات الحضور الخاصة بها؟'),
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
              context.read<AttendanceCubit>().deleteSession(session.id, _selectedGradeId);
            }
          },
        ),
      ),
    );
  }
}
