import 'package:flutter/foundation.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/token_generator.dart';
import '../domain/student_model.dart';

abstract class StudentsRepository {
  Future<List<StudentModel>> getStudents({String? groupId, String? gradeId});
  Future<StudentModel?> getStudentDetails(String studentId);
  Future<StudentModel> addStudent({
    required String groupId,
    required String name,
    String? email,
    String? phone,
    String? parentPhone,
    String? studentCode,
  });
  Future<StudentModel> createStudent({
    required String name,
    required String gradeId,
    String? groupId,
    String? phone,
    String? parentPhone,
    String? email,
  });
  Future<StudentModel> updateStudent({
    required String studentId,
    String? name,
    String? gradeId,
    String? groupId,
    String? phone,
    String? parentPhone,
    String? email,
    String? status,
  });
  Future<void> removeStudent(String studentId);
  Future<void> removeStudentFromGroup({required String groupId, required String studentId});
  Future<void> deleteStudent(String studentId);
  Future<List<Map<String, dynamic>>> getStudentAttendanceHistory(String studentId);
  Future<List<Map<String, dynamic>>> getStudentHomeworkHistory(String studentId);
  Future<List<Map<String, dynamic>>> getStudentExamAttempts(String studentId);
}

class StudentsRepositoryImpl implements StudentsRepository {
  @override
  Future<List<StudentModel>> getStudents({String? groupId, String? gradeId}) async {
    final targetId = groupId ?? gradeId;
    final client = SupabaseConfig.client;
    if (client == null) return [];

    try {
      final teacherId = client.auth.currentUser?.id;
      var query = client.from('students').select('*');

      if (targetId != null && targetId.isNotEmpty) {
        query = query.eq('grade_id', targetId);
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

      final response = await query.order('created_at', ascending: true);
      final rawStudents = response as List<dynamic>;

      // 1. Fetch attendance records
      final Map<String, List<String>> studentAttendance = {};
      try {
        final attRes = await client.from('attendance_records').select('student_id, status');
        for (final r in (attRes as List<dynamic>)) {
          final sId = r['student_id']?.toString();
          final st = r['status']?.toString();
          if (sId != null && st != null) {
            studentAttendance.putIfAbsent(sId, () => []).add(st);
          }
        }
      } catch (_) {}

      // 2. Fetch homework records
      final Map<String, List<String>> studentHomework = {};
      try {
        final hwRes = await client.from('homework_records').select('student_id, status');
        for (final r in (hwRes as List<dynamic>)) {
          final sId = r['student_id']?.toString();
          final st = r['status']?.toString();
          if (sId != null && st != null) {
            studentHomework.putIfAbsent(sId, () => []).add(st);
          }
        }
      } catch (_) {}

      // 3. Fetch exam attempts
      final Map<String, List<double>> studentExams = {};
      try {
        final exRes = await client.from('exam_attempts').select('*');
        for (final r in (exRes as List<dynamic>)) {
          final sId = r['student_id']?.toString();
          final score = (r['score'] as num?)?.toDouble() ?? (r['earned_points'] as num?)?.toDouble() ?? 0.0;
          final total = (r['total_score'] as num?)?.toDouble() ?? (r['total_points'] as num?)?.toDouble() ?? 100.0;
          final pct = total > 0 ? (score / total) * 100 : score;

          if (sId != null && sId.isNotEmpty) {
            studentExams.putIfAbsent(sId, () => []).add(pct);
          }
          final uId = r['user_id']?.toString() ?? r['profile_id']?.toString();
          if (uId != null && uId.isNotEmpty) {
            studentExams.putIfAbsent(uId, () => []).add(pct);
          }
        }
      } catch (e) {
        debugPrint('[getStudents] exam_attempts fetch error: $e');
      }

      String cleanPhoneHelper(String? phone) {
        if (phone == null) return '';
        var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.startsWith('0020')) {
          digits = digits.substring(4);
        } else if (digits.startsWith('20') && digits.length > 10) {
          digits = digits.substring(2);
        }
        if (digits.startsWith('0') && digits.length > 9) {
          digits = digits.substring(1);
        }
        return digits;
      }

      final List<StudentModel> uniqueList = [];
      final Set<String> seenKeys = {};

      for (final s in rawStudents) {
        final sId = s['id'].toString();
        final uId = s['user_id']?.toString() ?? s['profile_id']?.toString() ?? '';
        final sPhone = s['phone']?.toString() ?? '';
        final sEmail = (s['email']?.toString() ?? '').trim().toLowerCase();
        final sName = (s['name']?.toString() ?? '').trim().toLowerCase();
        final cleanPhone = cleanPhoneHelper(sPhone);

        // Determine unique key
        String uniqueKey = '';
        if (uId.isNotEmpty) {
          uniqueKey = 'uid_$uId';
        } else if (sEmail.isNotEmpty) {
          uniqueKey = 'email_$sEmail';
        } else if (cleanPhone.isNotEmpty) {
          uniqueKey = 'phone_$cleanPhone';
        } else if (sName.isNotEmpty) {
          uniqueKey = 'name_$sName';
        } else {
          uniqueKey = 'id_$sId';
        }

        if (seenKeys.contains(uniqueKey)) {
          continue; // Skip duplicate row
        }
        seenKeys.add(uniqueKey);

        // Attendance Rate
        final attList = studentAttendance[sId] ?? [];
        double attRate = 0.0;
        if (attList.isNotEmpty) {
          final presentCount = attList.where((st) => st == 'present' || st == 'late').length;
          attRate = ((presentCount / attList.length) * 100).roundToDouble();
        }

        // Homework Rate
        final hwList = studentHomework[sId] ?? [];
        double hwRate = 0.0;
        if (hwList.isNotEmpty) {
          final doneCount = hwList.where((st) => st == 'done' || st == 'submitted').length;
          hwRate = ((doneCount / hwList.length) * 100).roundToDouble();
        }

        // Exam Average
        final examList = [
          ...?studentExams[sId],
          if (uId.isNotEmpty && uId != sId) ...?studentExams[uId],
        ];

        double examAvg = 0.0;
        if (examList.isNotEmpty) {
          final totalPct = examList.reduce((a, b) => a + b);
          examAvg = (totalPct / examList.length).roundToDouble();
        }

        uniqueList.add(StudentModel.fromJson({
          'id': sId,
          'grade_id': s['grade_id']?.toString() ?? '',
          'name': s['name'] as String,
          'email': s['email'] as String?,
          'phone': s['phone'] as String?,
          'parent_phone': s['parent_phone'] as String?,
          'student_code': s['student_code'] as String? ?? 'STU-000',
          'status': s['status'] as String? ?? 'active',
          'joined_at': s['created_at']?.toString() ?? DateTime.now().toIso8601String(),
          'attendance_rate': attRate,
          'homework_rate': hwRate,
          'exam_average': examAvg,
        }));
      }

      return uniqueList;
    } catch (e) {
      debugPrint('[Supabase] getStudents error: $e');
      rethrow;
    }
  }

  @override
  Future<StudentModel?> getStudentDetails(String studentId) async {
    final client = SupabaseConfig.client;
    if (client == null) return null;

    try {
      final s = await client.from('students').select('*').eq('id', studentId).maybeSingle();
      if (s == null) return null;

      final sId = s['id'].toString();
      final uId = s['user_id']?.toString() ?? s['profile_id']?.toString() ?? '';

      // Attendance Rate
      double attRate = 0.0;
      try {
        final attRes = await client.from('attendance_records').select('status').eq('student_id', sId);
        final attList = (attRes as List<dynamic>).map((r) => r['status']?.toString() ?? '').toList();
        if (attList.isNotEmpty) {
          final presentCount = attList.where((st) => st == 'present' || st == 'late').length;
          attRate = ((presentCount / attList.length) * 100).roundToDouble();
        }
      } catch (_) {}

      // Homework Rate
      double hwRate = 0.0;
      try {
        final hwRes = await client.from('homework_records').select('status').eq('student_id', sId);
        final hwList = (hwRes as List<dynamic>).map((r) => r['status']?.toString() ?? '').toList();
        if (hwList.isNotEmpty) {
          final doneCount = hwList.where((st) => st == 'done' || st == 'submitted').length;
          hwRate = ((doneCount / hwList.length) * 100).roundToDouble();
        }
      } catch (_) {}

      // Exam Average
      double examAvg = 0.0;
      try {
        final exRes = await client.from('exam_attempts').select('*');
        final matchingAttempts = (exRes as List<dynamic>).where((r) {
          final attemptStudentId = r['student_id']?.toString() ?? '';
          final attemptUserId = r['user_id']?.toString() ?? '';
          return attemptStudentId == sId || (uId.isNotEmpty && (attemptStudentId == uId || attemptUserId == uId));
        }).toList();

        if (matchingAttempts.isNotEmpty) {
          double sumPct = 0.0;
          for (final r in matchingAttempts) {
            final score = (r['score'] as num?)?.toDouble() ?? 0.0;
            final total = (r['total_score'] as num?)?.toDouble() ?? 100.0;
            final pct = total > 0 ? (score / total) * 100 : score;
            sumPct += pct;
          }
          examAvg = (sumPct / matchingAttempts.length).roundToDouble();
        }
      } catch (e) {
        debugPrint('[getStudentDetails] exam_attempts fetch error: $e');
      }

      return StudentModel.fromJson({
        'id': sId,
        'grade_id': s['grade_id']?.toString() ?? '',
        'name': s['name'] as String,
        'email': s['email'] as String?,
        'phone': s['phone'] as String?,
        'parent_phone': s['parent_phone'] as String?,
        'student_code': s['student_code'] as String? ?? 'STU-000',
        'status': s['status'] as String? ?? 'active',
        'joined_at': s['created_at']?.toString() ?? DateTime.now().toIso8601String(),
        'attendance_rate': attRate,
        'homework_rate': hwRate,
        'exam_average': examAvg,
      });
    } catch (e) {
      debugPrint('[Supabase] getStudentDetails error: $e');
      rethrow;
    }
  }

  @override
  Future<StudentModel> addStudent({
    required String groupId,
    required String name,
    String? email,
    String? phone,
    String? parentPhone,
    String? studentCode,
  }) async {
    final genCode = studentCode ?? TokenGenerator.generateStudentCode();

    final client = SupabaseConfig.client;
    if (client == null) throw const ServerException('Supabase client not initialized');

    try {
      final teacherId = client.auth.currentUser?.id;
      final payload = <String, dynamic>{
        'grade_id': groupId,
        'name': name,
        'email': email,
        'phone': phone,
        'parent_phone': parentPhone,
        'student_code': genCode,
      };
      if (teacherId != null && teacherId.isNotEmpty) {
        payload['teacher_id'] = teacherId;
      }

      dynamic inserted;
      try {
        inserted = await client.from('students').insert(payload).select().single();
      } catch (insertErr) {
        if (payload.containsKey('teacher_id')) {
          payload.remove('teacher_id');
          inserted = await client.from('students').insert(payload).select().single();
        } else {
          rethrow;
        }
      }

      return StudentModel.fromJson({
        'id': inserted['id'].toString(),
        'grade_id': inserted['grade_id']?.toString() ?? groupId,
        'name': inserted['name'] as String,
        'email': inserted['email'] as String?,
        'phone': inserted['phone'] as String?,
        'parent_phone': inserted['parent_phone'] as String?,
        'student_code': inserted['student_code'] as String,
        'status': 'active',
        'attendance_rate': 100.0,
        'homework_rate': 100.0,
        'exam_average': 100.0,
      });
    } catch (e) {
      debugPrint('[Supabase] addStudent error: $e');
      rethrow;
    }
  }

  @override
  Future<StudentModel> createStudent({
    required String name,
    required String gradeId,
    String? groupId,
    String? phone,
    String? parentPhone,
    String? email,
  }) async {
    return addStudent(
      groupId: groupId ?? gradeId,
      name: name,
      phone: phone,
      parentPhone: parentPhone,
      email: email,
    );
  }

  @override
  Future<StudentModel> updateStudent({
    required String studentId,
    String? name,
    String? gradeId,
    String? groupId,
    String? phone,
    String? parentPhone,
    String? email,
    String? status,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) throw const ServerException('Supabase client not initialized');

    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (gradeId != null || groupId != null) updateData['grade_id'] = groupId ?? gradeId;
      if (phone != null) updateData['phone'] = phone;
      if (parentPhone != null) updateData['parent_phone'] = parentPhone;
      if (email != null) updateData['email'] = email;
      if (status != null) updateData['status'] = status;

      final updated = await client.from('students').update(updateData).eq('id', studentId).select().single();
      return StudentModel.fromJson(updated);
    } catch (e) {
      debugPrint('[Supabase] updateStudent error: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeStudent(String studentId) async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      // 1. Delete associated child records safely (in case DB lacks CASCADE)
      try {
        await client.from('attendance_records').delete().eq('student_id', studentId);
      } catch (_) {}
      try {
        await client.from('homework_records').delete().eq('student_id', studentId);
      } catch (_) {}
      try {
        await client.from('exam_attempts').delete().eq('student_id', studentId);
      } catch (_) {}

      // 2. Delete the student record itself
      await client.from('students').delete().eq('id', studentId);
    } catch (e) {
      debugPrint('[Supabase] removeStudent error: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeStudentFromGroup({required String groupId, required String studentId}) async {
    await removeStudent(studentId);
  }

  @override
  Future<void> deleteStudent(String studentId) async {
    await removeStudent(studentId);
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentAttendanceHistory(String studentId) async {
    final client = SupabaseConfig.client;
    if (client == null) return [];

    try {
      final records = await client
          .from('attendance_records')
          .select('*, attendance_sessions(lesson_title, session_date)')
          .eq('student_id', studentId);

      return (records as List<dynamic>).map((r) {
        final session = r['attendance_sessions'] as Map<String, dynamic>?;
        return {
          'lesson_title': session?['lesson_title'] ?? 'حصة دراسية',
          'date': session?['session_date'] ?? '',
          'status': r['status'] ?? 'present',
        };
      }).toList();
    } catch (e) {
      debugPrint('[Supabase] getStudentAttendanceHistory error: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentHomeworkHistory(String studentId) async {
    final client = SupabaseConfig.client;
    if (client == null) return [];

    try {
      final records = await client
          .from('homework_records')
          .select('*, homeworks(title, due_date)')
          .eq('student_id', studentId);

      return (records as List<dynamic>).map((r) {
        final hw = r['homeworks'] as Map<String, dynamic>?;
        return {
          'title': hw?['title'] ?? 'واجب دراسي',
          'due_date': hw?['due_date'] ?? '',
          'done': r['status'] == 'done',
        };
      }).toList();
    } catch (e) {
      debugPrint('[Supabase] getStudentHomeworkHistory error: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentExamAttempts(String studentId) async {
    final client = SupabaseConfig.client;
    if (client == null) return [];

    try {
      final idsToSearch = <String>{studentId};
      try {
        final s = await client.from('students').select('id, user_id, profile_id').eq('id', studentId).maybeSingle();
        if (s != null) {
          if (s['user_id'] != null) idsToSearch.add(s['user_id'].toString());
          if (s['profile_id'] != null) idsToSearch.add(s['profile_id'].toString());
        }
      } catch (_) {}

      List<dynamic> records = [];
      try {
        final r = await client
            .from('exam_attempts')
            .select('*, exams(title, duration_minutes)')
            .inFilter('student_id', idsToSearch.toList())
            .order('submitted_at', ascending: false);
        records = r as List<dynamic>;
      } catch (_) {
        final r = await client
            .from('exam_attempts')
            .select('*')
            .inFilter('student_id', idsToSearch.toList())
            .order('submitted_at', ascending: false);
        records = r as List<dynamic>;
      }

      return records.map((r) {
        final exam = r['exams'] as Map<String, dynamic>?;
        final score = (r['score'] as num?)?.toDouble() ?? 0.0;
        final total = (r['total_score'] as num?)?.toDouble() ?? 100.0;
        return {
          'id': r['id']?.toString() ?? '',
          'exam_id': r['exam_id']?.toString() ?? '',
          'student_id': r['student_id']?.toString() ?? studentId,
          'title': exam?['title'] ?? 'اختبار',
          'score': score,
          'total': total,
          'total_score': total,
          'percentage': total > 0 ? (score / total) * 100 : 0,
          'answers': r['answers'] ?? r['breakdown'],
          'started_at': r['started_at'],
          'submitted_at': r['submitted_at'],
        };
      }).toList();
    } catch (e) {
      debugPrint('[Supabase] getStudentExamAttempts error: $e');
      return [];
    }
  }
}
