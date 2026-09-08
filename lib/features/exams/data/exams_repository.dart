import 'package:flutter/foundation.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/errors/exceptions.dart';
import '../domain/exam_attempt_model.dart';
import '../domain/exam_model.dart';
import '../domain/exam_question_model.dart';

abstract class ExamsRepository {
  Future<List<ExamModel>> getExams({String? gradeId, String? groupId});
  Future<ExamModel?> getExamById(String id);
  Future<List<ExamQuestionModel>> getExamQuestions(String examId);
  Future<List<ExamAttemptModel>> getExamAttempts(String examId);
  Future<ExamModel> createExamWithQuestions({
    required String gradeId,
    String? lessonId,
    required String title,
    required int durationMinutes,
    DateTime? startAt,
    DateTime? endAt,
    required List<Map<String, dynamic>> questions,
  });
  Future<ExamModel> createExamFromJson(String groupId, Map<String, dynamic> examJson);
  Future<void> toggleExamActive(String examId, bool isActive);
  Future<void> deleteExam(String id);
  Future<ExamModel> updateExam({
    required String examId,
    String? title,
    int? durationMinutes,
    bool? isActive,
    String? gradeId,
    List<Map<String, dynamic>>? questions,
  });
}

class ExamsRepositoryImpl implements ExamsRepository {
  @override
  Future<List<ExamModel>> getExams({String? gradeId, String? groupId}) async {
    final gId = gradeId ?? groupId;
    final client = SupabaseConfig.client;
    if (client == null) return [];

    try {
      final teacherId = client.auth.currentUser?.id;
      List<dynamic> response;
      try {
        var query = client.from('exams').select('*, exam_questions(id), exam_attempts(id)');
        if (teacherId != null && teacherId.isNotEmpty) {
          query = query.eq('teacher_id', teacherId);
        }
        if (gId != null && gId.isNotEmpty) {
          query = query.eq('grade_id', gId);
        }
        response = await query.order('created_at', ascending: false);
      } catch (_) {
        var query = client.from('exams').select('*');
        if (teacherId != null && teacherId.isNotEmpty) {
          query = query.eq('teacher_id', teacherId);
        }
        if (gId != null && gId.isNotEmpty) {
          query = query.eq('grade_id', gId);
        }
        response = await query.order('created_at', ascending: false);
      }

      final list = response.map((e) {
        final questions = e['exam_questions'] as List<dynamic>? ?? [];
        final attempts = e['exam_attempts'] as List<dynamic>? ?? [];

        return ExamModel(
          id: e['id'].toString(),
          gradeId: e['grade_id']?.toString() ?? '',
          gradeName: 'المجموعة',
          title: e['title'] as String? ?? 'امتحان',
          durationMinutes: e['duration_minutes'] as int? ?? 30,
          startAt: DateTime.tryParse(e['start_at']?.toString() ?? '') ?? DateTime.now(),
          isActive: e['is_active'] as bool? ?? true,
          questionsCount: questions.length,
          attemptsCount: attempts.length,
          createdAt: DateTime.tryParse(e['created_at']?.toString() ?? '') ?? DateTime.now(),
        );
      }).toList();

      return list;
    } catch (e) {
      debugPrint('[Supabase] getExams error: $e');
      return [];
    }
  }

  @override
  Future<ExamModel?> getExamById(String id) async {
    final client = SupabaseConfig.client;
    if (client == null) return null;

    try {
      final e = await client.from('exams').select('*').eq('id', id).maybeSingle();
      if (e == null) return null;

      return ExamModel(
        id: e['id'].toString(),
        gradeId: e['grade_id']?.toString() ?? '',
        gradeName: 'المجموعة',
        title: e['title'] as String,
        durationMinutes: e['duration_minutes'] as int? ?? 30,
        startAt: DateTime.tryParse(e['start_at']?.toString() ?? '') ?? DateTime.now(),
        isActive: e['is_active'] as bool? ?? true,
        questionsCount: 0,
        attemptsCount: 0,
        createdAt: DateTime.tryParse(e['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('[Supabase] getExamById error: $e');
      rethrow;
    }
  }

  @override
  Future<List<ExamQuestionModel>> getExamQuestions(String examId) async {
    final client = SupabaseConfig.client;
    if (client == null) return [];

    try {
      final response = await client
          .from('exam_questions')
          .select('*')
          .eq('exam_id', examId)
          .order('sort_order', ascending: true);

      return (response as List<dynamic>).map((q) => ExamQuestionModel.fromJson({
        'id': q['id'].toString(),
        'exam_id': examId,
        'question': q['question'] as String,
        'options': q['options'] as List<dynamic>? ?? [],
        'correct_answer': q['correct_answer'] as String,
        'sort_order': q['sort_order'] as int? ?? 0,
      })).toList();
    } catch (e) {
      debugPrint('[Supabase] getExamQuestions error: $e');
      rethrow;
    }
  }

  @override
  Future<List<ExamAttemptModel>> getExamAttempts(String examId) async {
    final client = SupabaseConfig.client;
    if (client == null) return [];

    try {
      List<dynamic> response = [];
      Map<String, Map<String, dynamic>> studentDetails = {};

      // 1. Try fetching attempts
      try {
        final res = await client
            .from('exam_attempts')
            .select('*, students(id, name, student_code)')
            .eq('exam_id', examId)
            .order('score', ascending: false);
        response = res as List<dynamic>;
      } catch (relErr) {
        debugPrint('[getExamAttempts] Relational query note: $relErr. Falling back to direct query...');
        final res = await client
            .from('exam_attempts')
            .select('*')
            .eq('exam_id', examId)
            .order('score', ascending: false);
        response = res as List<dynamic>;
      }

      // 2. Always resolve student details from both students and profiles tables
      final allStudentIds = response
          .map((a) => a['student_id']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .toSet()
          .toList();

      if (allStudentIds.isNotEmpty) {
        // A. Lookup in students table by id
        try {
          final sRes = await client.from('students').select('*').inFilter('id', allStudentIds);
          for (final s in (sRes as List<dynamic>)) {
            final sMap = s as Map<String, dynamic>;
            final sName = sMap['name']?.toString().trim() ?? '';
            final sCode = sMap['student_code']?.toString() ?? 'STU-000';
            if (sName.isNotEmpty && sName != 'طالب') {
              studentDetails[sMap['id'].toString()] = {'name': sName, 'student_code': sCode};
              if (sMap['profile_id'] != null) {
                studentDetails[sMap['profile_id'].toString()] = {'name': sName, 'student_code': sCode};
              }
            }
          }
        } catch (e) {
          debugPrint('[getExamAttempts] students query error: $e');
        }

        // B. Lookup in students table by user_id
        try {
          final pRes = await client.from('students').select('*').inFilter('user_id', allStudentIds);
          for (final s in (pRes as List<dynamic>)) {
            final sMap = s as Map<String, dynamic>;
            final sName = sMap['name']?.toString().trim() ?? '';
            final sCode = sMap['student_code']?.toString() ?? 'STU-000';
            if (sName.isNotEmpty && sName != 'طالب') {
              if (sMap['user_id'] != null) {
                studentDetails[sMap['user_id'].toString()] = {'name': sName, 'student_code': sCode};
              }
              studentDetails[sMap['id'].toString()] = {'name': sName, 'student_code': sCode};
            }
          }
        } catch (_) {}

        // C. Lookup in profiles table by id (Auth Users Profile)
        try {
          final profRes = await client.from('profiles').select('*').inFilter('id', allStudentIds);
          for (final p in (profRes as List<dynamic>)) {
            final pMap = p as Map<String, dynamic>;
            final pId = pMap['id'].toString();
            final pName = (pMap['name'] ?? pMap['full_name'] ?? pMap['display_name'] ?? pMap['email']?.toString().split('@').first ?? '')?.toString().trim();
            if (pName != null && pName.isNotEmpty && pName != 'طالب') {
              studentDetails[pId] = {
                'name': pName,
                'student_code': studentDetails[pId]?['student_code'] ?? 'STU-${pId.length >= 6 ? pId.substring(0, 6).toUpperCase() : pId}',
              };
            }
          }
        } catch (e) {
          debugPrint('[getExamAttempts] profiles query error: $e');
        }

        // D. Fallback: Fetch all profiles if specific query returned empty
        if (studentDetails.isEmpty) {
          try {
            final allProf = await client.from('profiles').select('*');
            for (final p in (allProf as List<dynamic>)) {
              final pMap = p as Map<String, dynamic>;
              final pId = pMap['id'].toString();
              final pName = (pMap['name'] ?? pMap['full_name'] ?? pMap['email']?.toString().split('@').first ?? '')?.toString().trim();
              if (pName != null && pName.isNotEmpty && pName != 'طالب') {
                studentDetails[pId] = {
                  'name': pName,
                  'student_code': 'STU-${pId.length >= 6 ? pId.substring(0, 6).toUpperCase() : pId}',
                };
              }
            }
          } catch (_) {}
        }
      }

      // 3. Sort chronologically by submission time first to identify the FIRST attempt
      response.sort((a, b) {
        final aTime = DateTime.tryParse(a['submitted_at']?.toString() ?? a['started_at']?.toString() ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['submitted_at']?.toString() ?? b['started_at']?.toString() ?? '') ?? DateTime.now();
        return aTime.compareTo(bTime);
      });

      // 4. Keep only the first attempt per student
      final Map<String, dynamic> firstAttemptPerStudent = {};
      for (final a in response) {
        final stuId = a['student_id']?.toString() ?? '';
        if (stuId.isNotEmpty && !firstAttemptPerStudent.containsKey(stuId)) {
          firstAttemptPerStudent[stuId] = a;
        }
      }

      final uniqueAttempts = firstAttemptPerStudent.values.toList();
      final attemptModels = uniqueAttempts.map((a) {
        final studentRel = a['students'] as Map<String, dynamic>?;
        final stuId = a['student_id']?.toString() ?? '';
        final fallbackStu = studentDetails[stuId];

        // 1. Check embedded student name from answers payload
        String? embeddedName;
        final answersRaw = a['answers'];
        if (answersRaw is Map && answersRaw['student_name'] != null) {
          final s = answersRaw['student_name']?.toString().trim();
          if (s != null && s.isNotEmpty && s != 'طالب') embeddedName = s;
        } else if (answersRaw is List && answersRaw.isNotEmpty) {
          for (final item in answersRaw) {
            if (item is Map && item['student_name'] != null) {
              final s = item['student_name']?.toString().trim();
              if (s != null && s.isNotEmpty && s != 'طالب') {
                embeddedName = s;
                break;
              }
            }
          }
        }

        var name = (embeddedName != null && embeddedName.isNotEmpty)
            ? embeddedName
            : (studentRel?['name']?.toString().trim());

        if (name == null || name.isEmpty || name == 'طالب') {
          name = fallbackStu?['name']?.toString().trim();
        }
        if (name == null || name.isEmpty || name == 'طالب') {
          name = a['student_name']?.toString().trim();
        }
        if (name == null || name.isEmpty || name == 'طالب') {
          name = 'طالب مسجل';
        }

        final code = studentRel?['student_code'] ??
            fallbackStu?['student_code'] ??
            'STU-${stuId.length >= 6 ? stuId.substring(0, 6).toUpperCase() : stuId}';

        return ExamAttemptModel(
          id: a['id']?.toString() ?? '',
          examId: examId,
          studentId: stuId,
          studentName: name,
          studentCode: code.toString(),
          score: (a['score'] as num?)?.toDouble() ?? 0.0,
          totalScore: (a['total_score'] as num?)?.toDouble() ?? 100.0,
          startedAt: DateTime.tryParse(a['started_at']?.toString() ?? '') ?? DateTime.now(),
          submittedAt: DateTime.tryParse(a['submitted_at']?.toString() ?? '') ?? DateTime.now(),
          answers: a['answers'] ?? a['breakdown'],
        );
      }).toList();

      // Sort by score descending (highest score first)
      attemptModels.sort((a, b) => b.score.compareTo(a.score));
      return attemptModels;
    } catch (e) {
      debugPrint('[Supabase] getExamAttempts error: $e');
      return [];
    }
  }

  @override
  Future<ExamModel> createExamWithQuestions({
    required String gradeId,
    String? lessonId,
    required String title,
    required int durationMinutes,
    DateTime? startAt,
    DateTime? endAt,
    required List<Map<String, dynamic>> questions,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) throw const ServerException('Supabase client not initialized');

    try {
      final teacherId = client.auth.currentUser?.id;
      final payload = <String, dynamic>{
        'grade_id': gradeId,
        'lesson_id': lessonId,
        'title': title,
        'duration_minutes': durationMinutes,
        'start_at': startAt?.toIso8601String(),
        'end_at': endAt?.toIso8601String(),
      };
      if (teacherId != null && teacherId.isNotEmpty) {
        payload['teacher_id'] = teacherId;
      }

      final inserted = await client.from('exams').insert(payload).select().single();

      final examId = inserted['id'].toString();
      if (questions.isNotEmpty) {
        final qInserts = questions.map((q) => {
          'exam_id': examId,
          'question': q['question'],
          'options': q['options'],
          'correct_answer': q['correct_answer'],
        }).toList();
        await client.from('exam_questions').insert(qInserts);
      }

      return ExamModel(
        id: examId,
        gradeId: gradeId,
        title: title,
        durationMinutes: durationMinutes,
        startAt: startAt,
        endAt: endAt,
        questionsCount: questions.length,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[Supabase] createExamWithQuestions error: $e');
      rethrow;
    }
  }

  @override
  Future<ExamModel> createExamFromJson(String groupId, Map<String, dynamic> examJson) async {
    final title = examJson['title'] as String? ?? 'اختبار جديد';
    final duration = examJson['duration_minutes'] as int? ?? 30;
    final questions = examJson['questions'] as List<dynamic>? ?? [];

    return createExamWithQuestions(
      gradeId: groupId,
      title: title,
      durationMinutes: duration,
      questions: questions.cast<Map<String, dynamic>>(),
    );
  }

  @override
  Future<void> toggleExamActive(String examId, bool isActive) async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      await client.from('exams').update({'is_active': isActive}).eq('id', examId);
    } catch (e) {
      debugPrint('[Supabase] toggleExamActive error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteExam(String id) async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      await client.from('exams').delete().eq('id', id);
    } catch (e) {
      debugPrint('[Supabase] deleteExam error: $e');
      rethrow;
    }
  }

  @override
  Future<ExamModel> updateExam({
    required String examId,
    String? title,
    int? durationMinutes,
    bool? isActive,
    String? gradeId,
    List<Map<String, dynamic>>? questions,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) throw const ServerException('Supabase client not initialized');

    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (durationMinutes != null) updateData['duration_minutes'] = durationMinutes;
      if (isActive != null) updateData['is_active'] = isActive;
      if (gradeId != null) updateData['grade_id'] = gradeId;

      if (updateData.isNotEmpty) {
        await client.from('exams').update(updateData).eq('id', examId);
      }

      if (questions != null) {
        await client.from('exam_questions').delete().eq('exam_id', examId);
        if (questions.isNotEmpty) {
          final qInserts = questions.map((q) => {
            'exam_id': examId,
            'question': q['question'],
            'options': q['options'],
            'correct_answer': q['correct_answer'],
            'sort_order': q['sort_order'] ?? 0,
          }).toList();
          await client.from('exam_questions').insert(qInserts);
        }
      }

      final updated = await getExamById(examId);
      if (updated != null) return updated;

      return ExamModel(
        id: examId,
        gradeId: gradeId ?? '',
        title: title ?? 'امتحان',
        durationMinutes: durationMinutes ?? 30,
        isActive: isActive ?? true,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[Supabase] updateExam error: $e');
      rethrow;
    }
  }
}
