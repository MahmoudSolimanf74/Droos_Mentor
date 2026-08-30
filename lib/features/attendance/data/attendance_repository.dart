import 'package:flutter/foundation.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/errors/exceptions.dart';
import '../domain/attendance_record_model.dart';
import '../domain/attendance_session_model.dart';

abstract class AttendanceRepository {
  Future<List<AttendanceSessionModel>> getSessions({String? groupId});
  Future<AttendanceSessionModel> saveSessionWithRecords({
    String? sessionId,
    required String groupId,
    required String title,
    required DateTime sessionDate,
    required List<Map<String, dynamic>> records,
  });
  Future<AttendanceSessionModel> createSessionWithRecords({
    required String groupId,
    required String title,
    required DateTime sessionDate,
    required List<Map<String, dynamic>> records,
  });
  Future<List<AttendanceRecordModel>> getSessionRecords(String sessionId);
  Future<void> updateRecordStatus(String recordId, String status);
  Future<void> deleteSession(String sessionId);
}

class AttendanceRepositoryImpl implements AttendanceRepository {
  @override
  Future<List<AttendanceSessionModel>> getSessions({String? groupId}) async {
    final client = SupabaseConfig.client;
    if (client == null) return [];

    try {
      final teacherId = client.auth.currentUser?.id;
      var query = client.from('attendance_sessions').select('*, attendance_records(status)');
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
      final response = await query.order('session_date', ascending: false);

      final list = (response as List<dynamic>).map((s) {
        final records = s['attendance_records'] as List<dynamic>? ?? [];
        final present = records.where((r) => r['status'] == 'present').length;
        final absent = records.where((r) => r['status'] == 'absent').length;
        final late = records.where((r) => r['status'] == 'late').length;

        return AttendanceSessionModel(
          id: s['id'].toString(),
          groupId: s['grade_id']?.toString() ?? '',
          groupName: 'المجموعة',
          title: s['lesson_title'] as String? ?? 'حصة عامة',
          sessionDate: DateTime.tryParse(s['session_date']?.toString() ?? '') ?? DateTime.now(),
          presentCount: present,
          absentCount: absent,
          lateCount: late,
          totalStudents: records.length,
          createdAt: DateTime.now(),
        );
      }).toList();

      return list;
    } catch (e) {
      debugPrint('[Supabase] getSessions error: $e');
      rethrow;
    }
  }

  @override
  Future<AttendanceSessionModel> saveSessionWithRecords({
    String? sessionId,
    required String groupId,
    required String title,
    required DateTime sessionDate,
    required List<Map<String, dynamic>> records,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) throw const ServerException('Supabase client not initialized');

    try {
      final teacherId = client.auth.currentUser?.id;
      final formattedDate = sessionDate.toIso8601String().substring(0, 10);
      String sId;

      if (sessionId != null && sessionId.isNotEmpty) {
        // UPDATE EXISTING SESSION (Prevents duplication!)
        sId = sessionId;
        await client.from('attendance_sessions').update({
          'lesson_title': title,
          'session_date': formattedDate,
          'grade_id': groupId,
        }).eq('id', sId);

        await client.from('attendance_records').delete().eq('session_id', sId);
      } else {
        // CREATE NEW SESSION
        final payload = <String, dynamic>{
          'grade_id': groupId,
          'lesson_title': title,
          'session_date': formattedDate,
        };
        if (teacherId != null && teacherId.isNotEmpty) {
          payload['teacher_id'] = teacherId;
        }

        final inserted = await client.from('attendance_sessions').insert(payload).select().single();
        sId = inserted['id'].toString();
      }

      var recordsToInsert = records.map((r) => {
        'session_id': sId,
        'student_id': r['student_id'],
        'status': r['status'] ?? 'present',
        'notes': r['notes'],
      }).toList();

      if (recordsToInsert.isEmpty) {
        try {
          final students = await client.from('students').select('id').eq('grade_id', groupId);
          recordsToInsert = (students as List<dynamic>).map((s) => {
            'session_id': sId,
            'student_id': s['id'].toString(),
            'status': 'present',
          }).toList();
        } catch (_) {}
      }

      if (recordsToInsert.isNotEmpty) {
        await client.from('attendance_records').insert(recordsToInsert);
      }

      return AttendanceSessionModel(
        id: sId,
        groupId: groupId,
        title: title,
        sessionDate: sessionDate,
        presentCount: recordsToInsert.where((r) => r['status'] == 'present').length,
        absentCount: recordsToInsert.where((r) => r['status'] == 'absent').length,
        lateCount: recordsToInsert.where((r) => r['status'] == 'late').length,
        totalStudents: recordsToInsert.length,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[Supabase] saveSessionWithRecords error: $e');
      rethrow;
    }
  }

  @override
  Future<AttendanceSessionModel> createSessionWithRecords({
    required String groupId,
    required String title,
    required DateTime sessionDate,
    required List<Map<String, dynamic>> records,
  }) => saveSessionWithRecords(
    groupId: groupId,
    title: title,
    sessionDate: sessionDate,
    records: records,
  );

  @override
  Future<List<AttendanceRecordModel>> getSessionRecords(String sessionId) async {
    final client = SupabaseConfig.client;
    if (client == null) return [];

    try {
      final records = await client
          .from('attendance_records')
          .select('*, students(name, student_code)')
          .eq('session_id', sessionId);

      return (records as List<dynamic>).map((r) {
        final student = r['students'] as Map<String, dynamic>?;
        return AttendanceRecordModel(
          id: r['id'].toString(),
          sessionId: sessionId,
          studentId: r['student_id'].toString(),
          studentName: student?['name'] ?? 'طالب',
          studentCode: student?['student_code'] ?? 'STU-000',
          status: r['status'] ?? 'present',
          notes: r['notes'],
          createdAt: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('[Supabase] getSessionRecords error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateRecordStatus(String recordId, String status) async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      await client.from('attendance_records').update({'status': status}).eq('id', recordId);
    } catch (e) {
      debugPrint('[Supabase] updateRecordStatus error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      await client.from('attendance_sessions').delete().eq('id', sessionId);
    } catch (e) {
      debugPrint('[Supabase] deleteSession error: $e');
      rethrow;
    }
  }
}
