import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../grades/domain/grade_model.dart';
import '../../grades/presentation/grades_cubit.dart';
import '../domain/lesson_model.dart';
import 'curriculum_cubit.dart';
import 'lesson_details_screen.dart';
import 'widgets/create_lesson_dialog.dart';
import 'widgets/create_unit_dialog.dart';

class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});

  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  final Set<String> _expandedUnitIds = {};
  String? _selectedGradeId;

  @override
  void initState() {
    super.initState();
    context.read<GradesCubit>().loadGrades();
    final gradesState = context.read<GradesCubit>().state;
    if (gradesState is GradesLoaded && gradesState.grades.isNotEmpty) {
      _selectedGradeId = gradesState.grades.first.id;
      context.read<CurriculumCubit>().loadCurriculumForGrade(_selectedGradeId!);
    } else {
      context.read<CurriculumCubit>().loadCurriculumForGrade('');
    }
  }

  void _onGradeChanged(String gradeId) {
    setState(() {
      _selectedGradeId = gradeId;
      _expandedUnitIds.clear();
    });
    context.read<CurriculumCubit>().loadCurriculumForGrade(gradeId);
  }

  void _toggleUnit(String unitId) {
    setState(() {
      if (_expandedUnitIds.contains(unitId)) {
        _expandedUnitIds.remove(unitId);
      } else {
        _expandedUnitIds.add(unitId);
      }
    });
  }

  void _openLessonDetails(LessonModel lesson, String unitTitle) {
    if (_selectedGradeId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonDetailsScreen(
          lesson: lesson,
          unitTitle: unitTitle,
          gradeId: _selectedGradeId!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GradesCubit, GradesState>(
      listener: (context, state) {
        if (state is GradesLoaded) {
          if (state.grades.isNotEmpty) {
            if (_selectedGradeId == null || !state.grades.any((g) => g.id == _selectedGradeId)) {
              _onGradeChanged(state.grades.first.id);
            }
          } else {
            setState(() => _selectedGradeId = null);
            context.read<CurriculumCubit>().loadCurriculumForGrade('');
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
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
                            color: AppColors.cyan.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.menu_book_rounded, size: 54, color: AppColors.cyan),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد مجموعات دراسية بعد',
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'يرجى إنشاء مجموعة دراسية أولاً لإضافة وإدارة المناهج والدروس الخاصة بها',
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
                  // 1. Top Grade / Group Selector Chips
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: const BoxDecoration(
                      color: AppColors.card,
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Text('المجموعة: ', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          ...grades.map((g) {
                            final isSelected = _selectedGradeId == g.id;
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ChoiceChip(
                                label: Text(g.name),
                                selected: isSelected,
                                selectedColor: g.color.withValues(alpha: 0.25),
                                backgroundColor: AppColors.surface,
                                side: BorderSide(color: isSelected ? g.color : AppColors.border),
                                labelStyle: TextStyle(
                                  color: isSelected ? g.color : AppColors.textSecondary,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 13,
                                ),
                                onSelected: (_) => _onGradeChanged(g.id),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  // 2. Units Header & Add Unit Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الوحدات والدروس الدراسية',
                                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'اختر الدرس لرفع المذكرات وعرض ملفات الـ PDF في صفحة كاملة',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cyan,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('وحدة جديدة', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            CreateUnitDialog.show(context, onSubmit: (title, desc) {
                              context.read<CurriculumCubit>().createUnit(title, desc);
                            });
                          },
                        ),
                      ],
                    ),
                  ),

              // 3. Units List & Lessons
              Expanded(
                child: BlocBuilder<CurriculumCubit, CurriculumState>(
                  builder: (context, state) {
                    if (state is CurriculumLoading) {
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                    } else if (state is CurriculumLoaded) {
                      final units = state.units;
                      if (units.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.cyan.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.menu_book_rounded, size: 54, color: AppColors.cyan),
                              ),
                              const SizedBox(height: 14),
                              Text('لا توجد وحدات دراسية مسجلة لهذه المجموعة', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.cyan, foregroundColor: Colors.black),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('إضافة أول وحدة دراسية', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  CreateUnitDialog.show(context, onSubmit: (title, desc) {
                                    context.read<CurriculumCubit>().createUnit(title, desc);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: units.length,
                        separatorBuilder: (context, i) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final unit = units[i];
                          final isExpanded = _expandedUnitIds.contains(unit.id);
                          final unitLessons = state.lessons.where((l) => l.unitId == unit.id).toList();

                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                // Unit Header
                                InkWell(
                                  onTap: () {
                                    _toggleUnit(unit.id);
                                    context.read<CurriculumCubit>().selectUnit(unit.id);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: isExpanded ? AppColors.surface : Colors.transparent,
                                      border: isExpanded ? const Border(bottom: BorderSide(color: AppColors.border)) : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.cyan.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.folder_open_rounded, color: AppColors.cyan, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(unit.title, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 15)),
                                              if (unit.description != null && unit.description!.isNotEmpty)
                                                Text(unit.description!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: AppColors.cyan),
                                          tooltip: 'إضافة درس لهذه الوحدة',
                                          onPressed: () {
                                            CreateLessonDialog.show(context, onSubmit: (title, desc) {
                                              context.read<CurriculumCubit>().selectUnit(unit.id).then((_) {
                                                if (context.mounted) {
                                                  context.read<CurriculumCubit>().createLesson(title, desc);
                                                }
                                              });
                                            });
                                          },
                                        ),
                                        Icon(
                                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                          color: AppColors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Unit Lessons
                                if (isExpanded)
                                  if (unitLessons.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      child: Center(
                                        child: Wrap(
                                          alignment: WrapAlignment.center,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 10,
                                          runSpacing: 4,
                                          children: [
                                            const Text(
                                              'لا توجد دروس في هذه الوحدة بعد',
                                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                              textAlign: TextAlign.center,
                                            ),
                                            TextButton.icon(
                                              onPressed: () {
                                                CreateLessonDialog.show(context, onSubmit: (title, desc) {
                                                  context.read<CurriculumCubit>().selectUnit(unit.id).then((_) {
                                                    if (context.mounted) {
                                                      context.read<CurriculumCubit>().createLesson(title, desc);
                                                    }
                                                  });
                                                });
                                              },
                                              icon: const Icon(Icons.add, size: 14),
                                              label: const Text('إضافة درس الآن'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      padding: const EdgeInsets.all(12),
                                      itemCount: unitLessons.length,
                                      separatorBuilder: (context, idx) => const SizedBox(height: 8),
                                      itemBuilder: (context, idx) {
                                        final lesson = unitLessons[idx];
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          child: ListTile(
                                            onTap: () => _openLessonDetails(lesson, unit.title),
                                            leading: Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: AppColors.cyan.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              alignment: Alignment.center,
                                              child: const Icon(Icons.menu_book_rounded, color: AppColors.cyan, size: 18),
                                            ),
                                            title: Text(lesson.title, style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                                            subtitle: Text('انقر لفتح الملفات والمذكرات ⬅', style: AppTextStyles.bodySmall.copyWith(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.bold)),
                                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                                          ),
                                        );
                                      },
                                    ),
                              ],
                            ),
                          );
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
  );
}
}
