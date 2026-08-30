import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/kpi_card.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../grades/presentation/grades_cubit.dart';
import 'dashboard_cubit.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadDashboard();
    context.read<GradesCubit>().loadGrades();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState is Authenticated ? authState.user : null;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 36 : 16,
            vertical: isDesktop ? 28 : 16,
          ),
          child: Column(
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
                        AppStrings.teacherDashboard,
                        style: AppTextStyles.displayMedium.copyWith(fontSize: isDesktop ? 24 : 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'مرحباً ${user?.name ?? "أستاذ"} — اليوم ${DateTime.now().year}/${DateTime.now().month}/${DateTime.now().day}',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                    onPressed: () {
                      context.read<DashboardCubit>().loadDashboard();
                      context.read<GradesCubit>().loadGrades();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Top Stat Cards (4 Cards)
              BlocBuilder<DashboardCubit, DashboardState>(
                builder: (context, state) {
                  final kpis = state is DashboardLoaded ? state.kpis : null;
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      return GridView.count(
                        crossAxisCount: isWide ? 4 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: isWide ? 1.6 : 1.4,
                        children: [
                          KpiCard(
                            title: 'إجمالي الطلاب',
                            value: '${kpis?.totalStudents ?? 0}',
                            subtitle: 'عبر جميع المجموعات',
                            color: AppColors.primary,
                            icon: Icons.people_alt_outlined,
                          ),
                          KpiCard(
                            title: 'عدد المجموعات',
                            value: '${kpis?.totalGroups ?? 0}',
                            subtitle: 'المجموعات النشطة',
                            color: AppColors.cyan,
                            icon: Icons.school_outlined,
                          ),
                          KpiCard(
                            title: 'امتحانات مجدولة',
                            value: '${kpis?.upcomingExamsCount ?? 0}',
                            subtitle: 'نشطة أو قادمة',
                            color: AppColors.purple,
                            icon: Icons.timer_outlined,
                          ),
                          KpiCard(
                            title: 'دروس مكتملة',
                            value: '0',
                            subtitle: 'المنهج الدراسي',
                            color: AppColors.green,
                            icon: Icons.check_circle_outline_rounded,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              // Quick Actions Vertical List Section
              Text(
                'الإجراءات السريعة',
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildQuickActionTile(
                      icon: Icons.group_add_outlined,
                      title: 'إضافة مجموعة أو صف دراسي',
                      subtitle: 'إنشاء مجموعة جديدة وتوليد كود ورمز QR للانضمام',
                      color: AppColors.primary,
                      onTap: () => context.go('/groups'),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _buildQuickActionTile(
                      icon: Icons.person_add_alt_1_outlined,
                      title: 'إضافة طالب جديد',
                      subtitle: 'تسجيل طالب في إحدى المجموعات الدراسية',
                      color: AppColors.cyan,
                      onTap: () => context.go('/groups'),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _buildQuickActionTile(
                      icon: Icons.menu_book_outlined,
                      title: 'إضافة وحدة أو درس جديد',
                      subtitle: 'تنظيم المنهج الدراسي ورفع ملفات الـ PDF',
                      color: AppColors.green,
                      onTap: () => context.go('/academic?tab=0'),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _buildQuickActionTile(
                      icon: Icons.quiz_outlined,
                      title: 'إنشاء امتحان أو اختبار',
                      subtitle: 'إنشاء يدوي خطوة بخطوة أو استيراد من ملف JSON',
                      color: AppColors.purple,
                      onTap: () => context.go('/academic?tab=1'),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _buildQuickActionTile(
                      icon: Icons.how_to_reg_outlined,
                      title: 'تسجيل حضور وغياب حصة',
                      subtitle: 'رصد الحضور السريع لحصة اليوم بضغطة زر واحدة',
                      color: AppColors.yellow,
                      onTap: () => context.go('/academic?tab=2'),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _buildQuickActionTile(
                      icon: Icons.assignment_outlined,
                      title: 'رصد واجبات الطلاب',
                      subtitle: 'إنشاء واجب جديد وتحديد تسليمات الطلاب',
                      color: AppColors.red,
                      onTap: () => context.go('/academic?tab=3'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textFaint),
    );
  }
}
