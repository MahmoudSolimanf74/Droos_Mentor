import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../attendance/presentation/attendance_screen.dart';
import '../../curriculum/presentation/curriculum_screen.dart';
import '../../exams/presentation/exams_list_screen.dart';
import '../../homework/presentation/homework_list_screen.dart';
import '../../performance/presentation/performance_screen.dart';

class AcademicHubScreen extends StatefulWidget {
  final int initialTabIndex;

  const AcademicHubScreen({super.key, this.initialTabIndex = 0});

  @override
  State<AcademicHubScreen> createState() => _AcademicHubScreenState();
}

class _AcademicHubScreenState extends State<AcademicHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<Map<String, dynamic>> _tabs = [
    {'title': 'المنهج والدروس', 'icon': Icons.menu_book_rounded, 'color': AppColors.cyan},
    {'title': 'الامتحانات', 'icon': Icons.quiz_outlined, 'color': AppColors.purple},
    {'title': 'تسجيل الحضور', 'icon': Icons.how_to_reg_outlined, 'color': AppColors.green},
    {'title': 'الواجبات', 'icon': Icons.assignment_outlined, 'color': AppColors.yellow},
    {'title': 'جدول الأداء الشامل', 'icon': Icons.table_chart_outlined, 'color': AppColors.primary},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, _tabs.length - 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('الدروس', style: AppTextStyles.displayMedium.copyWith(fontSize: 20)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
              tabs: _tabs.map((tab) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tab['icon'] as IconData, size: 16),
                      const SizedBox(width: 8),
                      Text(tab['title'] as String),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CurriculumScreen(),
          ExamsListScreen(),
          AttendanceScreen(),
          HomeworkListScreen(),
          PerformanceScreen(),
        ],
      ),
    );
  }
}
