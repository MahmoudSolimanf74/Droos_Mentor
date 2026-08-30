import 'package:flutter/foundation.dart';
import '../../../core/config/supabase_config.dart';
import '../../exams/domain/exam_model.dart';
import '../../groups/domain/group_model.dart';
import '../domain/dashboard_kpis.dart';

abstract class DashboardRepository {
  Future<DashboardKpis> getKpis();
  Future<List<GroupModel>> getTopGroups();
  Future<List<ExamModel>> getUpcomingExams();
  Future<List<RecentActivityItem>> getRecentActivities();
}

class DashboardRepositoryImpl implements DashboardRepository {
  @override
  Future<DashboardKpis> getKpis() async {
    final client = SupabaseConfig.client;
    if (client == null) {
      return const DashboardKpis(
        totalStudents: 0,
        totalGroups: 0,
        firstSecStudents: 0,
        secondSecStudents: 0,
        averageAttendanceRate: 0.0,
        homeworkCompletionRate: 0.0,
        upcomingExamsCount: 0,
        recentExamAverage: 0.0,
      );
    }

    try {
      final teacherId = client.auth.currentUser?.id;
      if (teacherId == null || teacherId.isEmpty) {
        return const DashboardKpis(
          totalStudents: 0,
          totalGroups: 0,
          firstSecStudents: 0,
          secondSecStudents: 0,
          averageAttendanceRate: 0.0,
          homeworkCompletionRate: 0.0,
          upcomingExamsCount: 0,
          recentExamAverage: 0.0,
        );
      }

      final gradesRes = await client.from('grades').select('id').eq('teacher_id', teacherId);
      final gList = gradesRes as List;
      final gIds = gList.map((g) => g['id'].toString()).toList();

      List<dynamic> sList = [];
      if (gIds.isNotEmpty) {
        try {
          final studentsRes = await client.from('students').select('id, grade_id').inFilter('grade_id', gIds);
          sList = studentsRes as List;
        } catch (_) {
          final studentsRes = await client.from('students').select('id, grade_id').eq('teacher_id', teacherId);
          sList = studentsRes as List;
        }
      }

      final examsRes = await client.from('exams').select('id').eq('teacher_id', teacherId);
      final eList = examsRes as List;

      return DashboardKpis(
        totalStudents: sList.length,
        totalGroups: gList.length,
        firstSecStudents: sList.isNotEmpty ? (sList.length / 2).ceil() : 0,
        secondSecStudents: sList.isNotEmpty ? (sList.length / 2).floor() : 0,
        averageAttendanceRate: 0.0,
        homeworkCompletionRate: 0.0,
        upcomingExamsCount: eList.length,
        recentExamAverage: 0.0,
      );
    } catch (e) {
      debugPrint('[Supabase] getKpis error: $e');
      return const DashboardKpis(
        totalStudents: 0,
        totalGroups: 0,
        firstSecStudents: 0,
        secondSecStudents: 0,
        averageAttendanceRate: 0.0,
        homeworkCompletionRate: 0.0,
        upcomingExamsCount: 0,
        recentExamAverage: 0.0,
      );
    }
  }

  @override
  Future<List<GroupModel>> getTopGroups() async {
    final client = SupabaseConfig.client;
    if (client == null) return [];

    try {
      final teacherId = client.auth.currentUser?.id;
      var query = client.from('grades').select('*, students(id)');
      if (teacherId != null && teacherId.isNotEmpty) {
        query = query.eq('teacher_id', teacherId);
      }
      final response = await query.order('sort_order', ascending: true);

      final list = (response as List<dynamic>).map((g) {
        final students = g['students'] as List<dynamic>? ?? [];
        return GroupModel.fromJson(g, students.length);
      }).toList();

      return list;
    } catch (e) {
      debugPrint('[Supabase] getTopGroups error: $e');
      return [];
    }
  }

  @override
  Future<List<ExamModel>> getUpcomingExams() async {
    final client = SupabaseConfig.client;
    if (client == null) return [];

    try {
      final teacherId = client.auth.currentUser?.id;
      var query = client.from('exams').select('*, exam_questions(id), exam_attempts(id)');
      if (teacherId != null && teacherId.isNotEmpty) {
        query = query.eq('teacher_id', teacherId);
      }
      final response = await query.order('created_at', ascending: false).limit(5);

      return (response as List<dynamic>).map((e) {
        final questions = e['exam_questions'] as List<dynamic>? ?? [];
        final attempts = e['exam_attempts'] as List<dynamic>? ?? [];

        return ExamModel(
          id: e['id'].toString(),
          gradeId: e['grade_id']?.toString() ?? '',
          gradeName: 'المجموعة',
          title: e['title'] as String,
          durationMinutes: e['duration_minutes'] as int? ?? 30,
          startAt: DateTime.tryParse(e['start_at']?.toString() ?? '') ?? DateTime.now(),
          isActive: e['is_active'] as bool? ?? true,
          questionsCount: questions.length,
          attemptsCount: attempts.length,
          createdAt: DateTime.tryParse(e['created_at']?.toString() ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('[Supabase] getUpcomingExams error: $e');
      return [];
    }
  }

  @override
  Future<List<RecentActivityItem>> getRecentActivities() async {
    // Return empty list if no recent activities
    return [];
  }
}
