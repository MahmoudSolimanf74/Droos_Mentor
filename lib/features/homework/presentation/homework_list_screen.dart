import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/status_badge.dart';
import '../../grades/domain/grade_model.dart';
import '../../grades/presentation/grades_cubit.dart';
import '../domain/homework_model.dart';
import 'homework_cubit.dart';
import 'homework_detail_screen.dart';

class HomeworkListScreen extends StatefulWidget {
  const HomeworkListScreen({super.key});

  @override
  State<HomeworkListScreen> createState() => _HomeworkListScreenState();
}

class _HomeworkListScreenState extends State<HomeworkListScreen> {
  String? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    context.read<GradesCubit>().loadGrades();
    final gradesState = context.read<GradesCubit>().state;
    if (gradesState is GradesLoaded && gradesState.grades.isNotEmpty) {
      _selectedGroupId = gradesState.grades.first.id;
      context.read<HomeworkCubit>().loadHomeworks(groupId: _selectedGroupId);
    }
  }

  void _onGroupChanged(String groupId) {
    setState(() {
      _selectedGroupId = groupId;
    });
    context.read<HomeworkCubit>().loadHomeworks(groupId: groupId);
  }

  void _openHomeworkDetail(HomeworkModel? homework, String gradeName) async {
    if (_selectedGroupId == null) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => HomeworkDetailScreen(
          homework: homework,
          gradeId: _selectedGroupId!,
          gradeName: gradeName,
        ),
      ),
    );

    if (result == true && mounted && _selectedGroupId != null) {
      context.read<HomeworkCubit>().loadHomeworks(groupId: _selectedGroupId);
    }
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
            context.read<HomeworkCubit>().loadHomeworks(groupId: null);
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
                              color: AppColors.yellow.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.assignment_outlined, size: 54, color: AppColors.yellow),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد مجموعات دراسية بعد',
                            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'يرجى إنشاء مجموعة دراسية أولاً لإضافة وتكليف الواجبات للطلاب',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final currentGrade = grades.firstWhere(
                  (g) => g.id == _selectedGroupId,
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
                                AppStrings.navAssignments,
                                style: AppTextStyles.displayMedium.copyWith(fontSize: isDesktop ? 24 : 18),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'متابعة تسليم الواجبات والتكليفات',
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
                            backgroundColor: AppColors.yellow,
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 12, vertical: isDesktop ? 12 : 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                          label: Text(isDesktop ? 'إضافة واجب جديد' : 'واجب جديد', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: _selectedGroupId == null
                              ? null
                              : () => _openHomeworkDetail(null, currentGrade.name),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Grade Selector Chips
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
                    const SizedBox(height: 18),

                // Homeworks List
                Expanded(
                  child: BlocBuilder<HomeworkCubit, HomeworkState>(
                    builder: (context, state) {
                      if (state is HomeworkLoading) {
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                      } else if (state is HomeworkLoaded) {
                        final homeworks = state.homeworks;
                        final gradesState = context.read<GradesCubit>().state;
                        final grades = gradesState is GradesLoaded ? gradesState.grades : <GradeModel>[];
                        final currentGrade = grades.firstWhere(
                          (g) => g.id == _selectedGroupId,
                          orElse: () => GradeModel(id: '', name: 'المجموعة', code: '', createdAt: DateTime.now()),
                        );

                        if (homeworks.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.yellow.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.assignment_outlined, size: 54, color: AppColors.yellow),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'لا توجد واجبات مسجلة لهذه المجموعة',
                                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'اضغط على زر "إضافة واجب جديد" بالأعلى لتعيين واجب ومتابعة تسليمه',
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.yellow,
                                    foregroundColor: Colors.black,
                                  ),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('إضافة أول واجب الآن', style: TextStyle(fontWeight: FontWeight.bold)),
                                  onPressed: _selectedGroupId == null
                                      ? null
                                      : () => _openHomeworkDetail(null, currentGrade.name),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: homeworks.length,
                          separatorBuilder: (context, i) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final hw = homeworks[i];
                            return _buildHomeworkCard(hw, currentGrade.name);
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

  Widget _buildHomeworkCard(HomeworkModel hw, String gradeName) {
    final hasDue = hw.dueDate != null;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => _openHomeworkDetail(hw, gradeName),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.yellow.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.assignment_turned_in_rounded, color: AppColors.yellow, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                hw.title,
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            StatusBadge(
              label: 'تم التسليم: ${hw.completedCount}',
              color: AppColors.green,
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              if (hasDue) ...[
                const Icon(Icons.alarm_rounded, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 3),
                Text(
                  '${hw.dueDate!.month}/${hw.dueDate!.day}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                ),
              ] else
                Text('بدون موعد', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textFaint, fontSize: 11)),
              const Spacer(),
              Text(
                'متابعة ⬅',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red, size: 20),
          tooltip: 'حذف الواجب',
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.card,
                title: const Text('حذف الواجب'),
                content: Text('هل أنت متأكد من رغبتك في حذف واجب "${hw.title}" وجميع سجلات التسليم الخاصة به؟'),
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
              context.read<HomeworkCubit>().deleteHomework(hw.id, _selectedGroupId);
            }
          },
        ),
      ),
    );
  }
}
