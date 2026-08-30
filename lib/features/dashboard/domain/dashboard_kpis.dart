import 'package:equatable/equatable.dart';

class DashboardKpis extends Equatable {
  final int totalStudents;
  final int totalGroups;
  final int firstSecStudents;
  final int secondSecStudents;
  final double averageAttendanceRate;
  final double homeworkCompletionRate;
  final int upcomingExamsCount;
  final double recentExamAverage;

  const DashboardKpis({
    this.totalStudents = 0,
    this.totalGroups = 0,
    this.firstSecStudents = 0,
    this.secondSecStudents = 0,
    this.averageAttendanceRate = 0.0,
    this.homeworkCompletionRate = 0.0,
    this.upcomingExamsCount = 0,
    this.recentExamAverage = 0.0,
  });

  @override
  List<Object?> get props => [
        totalStudents,
        totalGroups,
        firstSecStudents,
        secondSecStudents,
        averageAttendanceRate,
        homeworkCompletionRate,
        upcomingExamsCount,
        recentExamAverage,
      ];
}

class RecentActivityItem extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String type; // 'attendance', 'exam', 'homework', 'student'
  final DateTime timestamp;

  const RecentActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, title, subtitle, type, timestamp];
}
