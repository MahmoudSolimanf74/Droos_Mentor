import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/status_badge.dart';
import '../../students/domain/student_model.dart';
import '../../students/presentation/student_details_screen.dart';
import '../../students/presentation/students_cubit.dart';
import '../../students/presentation/widgets/add_student_dialog.dart';
import '../domain/grade_model.dart';
import 'grades_cubit.dart';
import 'widgets/create_grade_dialog.dart';

class GradesAndStudentsScreen extends StatefulWidget {
  final String? initialGradeId;

  const GradesAndStudentsScreen({super.key, this.initialGradeId});

  @override
  State<GradesAndStudentsScreen> createState() => _GradesAndStudentsScreenState();
}

class _GradesAndStudentsScreenState extends State<GradesAndStudentsScreen> {
  String? _selectedGradeId;
  int _detailTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedGradeId = widget.initialGradeId;
    context.read<GradesCubit>().loadGrades();
    if (_selectedGradeId != null) {
      context.read<StudentsCubit>().loadStudents(null, _selectedGradeId);
    }
  }

  void _selectGrade(GradeModel grade) {
    setState(() {
      _selectedGradeId = grade.id;
      _detailTabIndex = 0;
    });
    context.read<StudentsCubit>().loadStudents(null, grade.id);
  }

  void _showCreateGradeDialog() {
    CreateGradeDialog.show(
      context,
      onSubmit: ({required name, required code, required schedule, required colorHex}) async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          await context.read<GradesCubit>().createGrade(
            name: name,
            code: code,
            schedule: schedule,
            colorHex: colorHex,
          );
          messenger.showSnackBar(
            const SnackBar(
              content: Text('تم إنشاء المجموعة بنجاح!'),
              backgroundColor: AppColors.green,
            ),
          );
        } catch (e) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('فشل إنشاء المجموعة: $e'),
              backgroundColor: AppColors.red,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<GradesCubit, GradesState>(
          listener: (context, state) {
            if (state is GradesError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is GradesLoading) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            }

            final grades = state is GradesLoaded ? state.grades : <GradeModel>[];
            final selectedGrade = _selectedGradeId != null
                ? grades.firstWhere((g) => g.id == _selectedGradeId, orElse: () => grades.isNotEmpty ? grades.first : GradeModel(id: '', name: '', code: '', createdAt: DateTime.now()))
                : null;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 16,
                vertical: isDesktop ? 20 : 12,
              ),
              child: _selectedGradeId == null || selectedGrade == null || selectedGrade.id.isEmpty
                  ? _buildGradesGridView(grades, isDesktop)
                  : _buildGradeDetailView(selectedGrade, isDesktop),
            );
          },
        ),
      ),
    );
  }

  // 1. ALL GROUPS / GRADES LIST VIEW
  Widget _buildGradesGridView(List<GradeModel> grades, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page Header
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المجموعات',
                    style: AppTextStyles.displayMedium.copyWith(fontSize: isDesktop ? 24 : 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'إدارة مجموعاتك الدراسية ومتابعة الطلاب',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('مجموعة جديدة'),
              onPressed: _showCreateGradeDialog,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Grid / List or Empty State
        Expanded(
          child: grades.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.groups_outlined, size: 54, color: AppColors.textFaint),
                      const SizedBox(height: 12),
                      Text('لا توجد مجموعات دراسية بعد', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Text('أنشئ مجموعتك الأولى لتوليد كود ورمز QR لانضمام الطلاب', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textFaint)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('إنشاء مجموعة جديدة'),
                        onPressed: _showCreateGradeDialog,
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 700;
                    if (isWide) {
                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 155,
                        ),
                        itemCount: grades.length,
                        itemBuilder: (context, i) => _buildGradeCard(grades[i]),
                      );
                    }
                    return ListView.separated(
                      itemCount: grades.length,
                      separatorBuilder: (context, i) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _buildGradeCard(grades[i]),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildGradeCard(GradeModel g) {
    return InkWell(
      onTap: () => _selectGrade(g),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Right Color Indicator Bar
            Container(
              width: 5,
              height: 70,
              decoration: BoxDecoration(
                color: g.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 14),

            // Middle: Name, Schedule, and Code
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          g.name,
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      StatusBadge(
                        label: g.joinCode,
                        color: g.color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          g.schedule,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: g.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_outline_rounded, size: 13, color: g.color),
                            const SizedBox(width: 4),
                            Text(
                              '${g.studentCount} طلاب',
                              style: TextStyle(color: g.color, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Left Arrow
            const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }

  // 2. GRADE DETAIL VIEW
  Widget _buildGradeDetailView(GradeModel group, bool isDesktop) {
    return BlocBuilder<StudentsCubit, StudentsState>(
      builder: (context, state) {
        final students = state is StudentsLoaded ? state.students : <StudentModel>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            InkWell(
              onTap: () => setState(() => _selectedGradeId = null),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'العودة لكافة المجموعات',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Grade Header Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 44,
                    decoration: BoxDecoration(
                      color: group.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          group.schedule,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 15),
                    label: const Text('إضافة طالب'),
                    onPressed: () {
                      final messenger = ScaffoldMessenger.of(context);
                      AddStudentDialog.show(
                        context,
                        onSubmit: ({required name, email, parentPhone, phone}) async {
                          try {
                            await context.read<StudentsCubit>().addStudent(
                              name: name,
                              groupId: group.id,
                              gradeId: group.id,
                              phone: phone,
                              parentPhone: parentPhone,
                              email: email,
                            );
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('تمت إضافة الطالب بنجاح!'),
                                backgroundColor: AppColors.green,
                              ),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('فشل إضافة الطالب: $e'),
                                backgroundColor: AppColors.red,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Tabs Header
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabButton('الطلاب (${students.length})', 0),
                  const SizedBox(width: 8),
                  _buildTabButton('كود الانضمام و QR', 1),
                  const SizedBox(width: 8),
                  _buildTabButton('إحصائيات', 2),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 14),

            // Tab Content
            Expanded(
              child: switch (_detailTabIndex) {
                0 => _buildStudentsTableTab(students, group),
                1 => _buildQrCodeTab(group),
                2 => _buildStatsTab(students, group),
                _ => const SizedBox.shrink(),
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _detailTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _detailTabIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDim : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent),
        ),
        child: Text(
          title,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // TAB 1: STUDENTS LIST
  Widget _buildStudentsTableTab(List<StudentModel> students, GradeModel group) {
    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textFaint),
            const SizedBox(height: 12),
            Text('لا يوجد طلاب مسجلين في هذه المجموعة بعد', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
              label: const Text('إضافة أول طالب'),
              onPressed: () {
                final messenger = ScaffoldMessenger.of(context);
                AddStudentDialog.show(
                  context,
                  onSubmit: ({required name, email, parentPhone, phone}) async {
                    try {
                      await context.read<StudentsCubit>().addStudent(
                        name: name,
                        groupId: group.id,
                        gradeId: group.id,
                        phone: phone,
                        parentPhone: parentPhone,
                        email: email,
                      );
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('تمت إضافة الطالب بنجاح!'),
                          backgroundColor: AppColors.green,
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('فشل إضافة الطالب: $e'),
                          backgroundColor: AppColors.red,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: students.length,
      separatorBuilder: (context, i) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final s = students[i];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentDetailsScreen(
                      groupId: group.id,
                      studentId: s.id,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryDim,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name,
                            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (s.phone != null && s.phone!.isNotEmpty) ? s.phone! : 'لا يوجد رقم هاتف',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.green),
                      tooltip: 'مشاركة التقرير عبر واتساب لولي الأمر',
                      onPressed: () {
                        WhatsAppHelper.shareStudentReport(
                          context: context,
                          student: s,
                          groupName: group.name,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.red),
                      tooltip: 'حذف الطالب',
                      onPressed: () {
                        context.read<StudentsCubit>().deleteStudent(s.id);
                      },
                    ),
                    const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary, size: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // TAB 2: QR CODE & JOIN CODE
  Widget _buildQrCodeTab(GradeModel group) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'رمز الانضمام لمجموعة ${group.name}',
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'يقوم الطالب بمسح رمز الـ QR أو كتابة الكود للانضمام الفوري للمجموعة',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              // QR Code in White Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: QrImageView(
                  data: group.joinCode,
                  version: QrVersions.auto,
                  size: 180,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 18),

              // Join Code Display Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: group.color.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('كود المجموعة:', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11)),
                        Text(
                          group.joinCode,
                          style: AppTextStyles.titleMedium.copyWith(color: group.color, fontWeight: FontWeight.w800, letterSpacing: 1),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                      tooltip: 'نسخ الكود',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: group.joinCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم نسخ كود المجموعة بنجاح!'),
                            backgroundColor: AppColors.green,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TAB 3: STATS
  Widget _buildStatsTab(List<StudentModel> students, GradeModel group) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  title: 'إجمالي الطلاب',
                  value: '${students.length}',
                  icon: Icons.people_alt_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  title: 'معدل الحضور',
                  value: '${group.averageAttendance.toInt()}%',
                  icon: Icons.how_to_reg_outlined,
                  color: AppColors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value, style: AppTextStyles.displayMedium.copyWith(color: color, fontSize: 22)),
          const SizedBox(height: 2),
          Text(title, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
