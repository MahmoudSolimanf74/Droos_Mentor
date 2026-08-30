import 'package:flutter/foundation.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/errors/exceptions.dart';
import '../domain/homework_model.dart';
import '../domain/homework_record_model.dart';

abstract class HomeworkRepository {
  Future<List<HomeworkModel>> getHomeworks({String? groupId});
  Future<HomeworkModel> saveHomeworkWithRecords({
    String? homeworkId,
    required String groupId,
    String? lessonId,
    required String title,
    DateTime? dueDate,
    required List<Map<String, dynamic>> records,
  });
  Future<HomeworkModel> createHomeworkWithRecords({
    required String groupId,
    String? lessonId,
    required String title,
    DateTime? dueDate,
    required List<Map<String, dynamic>> records,
  });
  Future<List<HomeworkRecordModel>> getHomeworkRecords(String homeworkId);
  Future<void> updateRecordStatus(String recordId, String status);
  Future<void> deleteHomework(String homeworkId);
}

class HomeworkRepositoryImpl implements HomeworkRepository {
  @override
  Future<List<HomeworkModel>> getHomeworks({String? groupId}) async {
    final client = SupabaseConfig.client;
    if (client == null) return [];

    try {
      final teacherId = client.auth.currentUser?.id;
      var query = client.from('homeworks').select('*, homework_records(status)');
      if (groupId != null && groupId.isNotEmpty) {
        query = query.eq('grade_id', groupId);
      } else if (teacherId != null && teacherId.isNotEmpty) {
        try {
          final teacherGrades = await client.from('grades').select('id').eq('teacher_id', teacherId);
          final gIds = (teacherGrades as List).map((g) => g['id'].toString()).toList();
          if (gIds.isNotEmpty) {
            query = query.inFilter('grade_id', gIds);
          } else {
            return [];
          }
        } catch (_) {
          query = query.eq('teacher_id', teacherId);
        }
      }
      final response = await query.order('due_date', ascending: false);

      final list = (response as List<dynamic>).map((a) {
        final records = a['homework_records'] as List<dynamic>? ?? [];
        final done = records.where((r) => r['status'] == 'done').length;

        return HomeworkModel(
          id: a['id'].toString(),
          groupId: a['grade_id']?.toString() ?? '',
          groupName: 'المجموعة',
          title: a['title'] as String,
          dueDate: DateTime.tryParse(a['due_date']?.toString() ?? '') ?? DateTime.now(),
          completedCount: done,
          totalStudents: records.length,
          createdAt: DateTime.now(),
        );
      }).toList();

      return list;
    } catch (e) {
      debugPrint('[Supabase] getHomeworks error: $e');
      rethrow;
    }
  }

  @override
  Future<HomeworkModel> saveHomeworkWithRecords({
    String? homeworkId,
    required String groupId,
    String? lessonId,
    required String title,
    DateTime? dueDate,
    required List<Map<String, dynamic>> records,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) throw const ServerException('Supabase client not initialized');

    try {
      final teacherId = client.auth.currentUser?.id;
      final formattedDueDate = (dueDate ?? DateTime.now()).toIso8601String().substring(0, 10);
      String hwId;

      if (homeworkId != null && homeworkId.isNotEmpty) {
        // UPDATE EXISTING HOMEWORK (Prevents duplicate entities!)
        hwId = homeworkId;
        final updatePayload = <String, dynamic>{
          'title': title,
          'due_date': formattedDueDate,
          'grade_id': groupId,
        };
        if (lessonId != null && lessonId.isNotEmpty) {
          updatePayload['lesson_id'] = lessonId;
        }
        await client.from('homeworks').update(updatePayload).eq('id', hwId);

        // Replace records for this homework
        await client.from('homework_records').delete().eq('homework_id', hwId);
      } else {
        // CREATE NEW HOMEWORK
        final payload = <String, dynamic>{
          'grade_id': groupId,
          'title': title,
          'due_date': formattedDueDate,
        };
        if (lessonId != null && lessonId.isNotEmpty) {
          payload['lesson_id'] = lessonId;
        }
        if (teacherId != null && teacherId.isNotEmpty) {
          payload['teacher_id'] = teacherId;
        }

        final inserted = await client.from('homeworks').insert(payload).select().single();
        hwId = inserted['id'].toString();
      }

      var recordsToInsert = records.map((r) => {
        'homework_id': hwId,
        'student_id': r['student_id'],
        'status': r['status'] ?? 'done',
      }).toList();

      if (recordsToInsert.isEmpty) {
        try {
          final students = await client.from('students').select('id').eq('grade_id', groupId);
          recordsToInsert = (students as List<dynamic>).map((s) => {
            'homework_id': hwId,
            'student_id': s['id'].toString(),
            'status': 'not_done',
          }).toList();
        } catch (_) {}
      }

      if (recordsToInsert.isNotEmpty) {
        await client.from('homework_records').insert(recordsToInsert);
      }

      return HomeworkModel(
        id: hwId,
        groupId: groupId,
        title: title,
        dueDate: dueDate,
        totalStudents: recordsToInsert.length,
        completedCount: recordsToInsert.where((r) => r['status'] == 'done').length,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[Supabase] saveHomeworkWithRecords error: $e');
      rethrow;
    }
  }

  @override
  Future<HomeworkModel> createHomeworkWithRecords({
    required String groupId,
    String? lessonId,
    required String title,
    DateTime? dueDate,
    required List<Map<String, dynamic>> records,
  }) => saveHomeworkWithRecords(
    groupId: groupId,
    lessonId: lessonId,
    title: title,
    dueDate: dueDate,
    records: records,
  );

  @override
  Future<List<HomeworkRecordModel>> getHomeworkRecords(String homeworkId) async {
    final client = SupabaseConfig.client;
    if (client == null) return [];

    try {
      final records = await client
          .from('homework_records')
          .select('*, students(name, student_code)')
          .eq('homework_id', homeworkId);

      return (records as List<dynamic>).map((r) {
        final student = r['students'] as Map<String, dynamic>?;
        return HomeworkRecordModel(
          id: r['id'].toString(),
          homeworkId: homeworkId,
          studentId: r['student_id'].toString(),
          studentName: student?['name'] ?? 'طالب',
          studentCode: student?['student_code'] ?? 'STU-000',
          status: r['status'] ?? 'done',
          createdAt: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('[Supabase] getHomeworkRecords error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateRecordStatus(String recordId, String status) async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      await client.from('homework_records').update({'status': status}).eq('id', recordId);
    } catch (e) {
      debugPrint('[Supabase] updateRecordStatus error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteHomework(String homeworkId) async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      await client.from('homeworks').delete().eq('id', homeworkId);
    } catch (e) {
      debugPrint('[Supabase] deleteHomework error: $e');
      rethrow;
    }
  }
}
