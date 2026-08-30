import 'package:flutter/foundation.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/errors/exceptions.dart';
import '../domain/grade_model.dart';

abstract class GradesRepository {
  Future<List<GradeModel>> getGrades();
  Future<GradeModel?> getGradeById(String id);
  Future<GradeModel> createGrade({
    required String name,
    required String code,
    String? gradeLevel,
    String? colorHex,
    String? schedule,
    int sortOrder = 0,
  });
  Future<GradeModel> updateGrade({
    required String id,
    String? name,
    String? code,
    String? gradeLevel,
    String? colorHex,
    String? schedule,
    int? sortOrder,
    bool? isActive,
  });
  Future<void> deleteGrade(String id);
}

class GradesRepositoryImpl implements GradesRepository {
  @override
  Future<List<GradeModel>> getGrades() async {
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
        final rawStudents = g['students'] as List<dynamic>? ?? [];
        return GradeModel.fromJson({
          'id': g['id'].toString(),
          'name': g['name'] as String,
          'code': g['code'] as String? ?? g['join_code'] as String? ?? 'CP-01',
          'color': g['color'] as String? ?? '#4f8ef7',
          'schedule': g['schedule'] as String? ?? 'السبت والثلاثاء • 5:00م',
          'student_count': rawStudents.length,
          'average_attendance': 0.0,
          'sort_order': g['sort_order'] as int? ?? 0,
          'is_active': g['is_active'] as bool? ?? true,
        });
      }).toList();

      return list;
    } catch (e) {
      debugPrint('[Supabase] getGrades error: $e');
      rethrow;
    }
  }

  @override
  Future<GradeModel?> getGradeById(String id) async {
    final client = SupabaseConfig.client;
    if (client == null) return null;

    try {
      final teacherId = client.auth.currentUser?.id;
      var query = client.from('grades').select('*, students(id)').eq('id', id);
      if (teacherId != null && teacherId.isNotEmpty) {
        query = query.eq('teacher_id', teacherId);
      }
      final g = await query.maybeSingle();

      if (g == null) return null;
      final rawStudents = g['students'] as List<dynamic>? ?? [];
      return GradeModel.fromJson({
        'id': g['id'].toString(),
        'name': g['name'] as String,
        'code': g['code'] as String? ?? 'CP-01',
        'color': g['color'] as String? ?? '#4f8ef7',
        'schedule': g['schedule'] as String? ?? 'السبت والثلاثاء • 5:00م',
        'student_count': rawStudents.length,
        'average_attendance': 0.0,
        'sort_order': g['sort_order'] as int? ?? 0,
        'is_active': g['is_active'] as bool? ?? true,
      });
    } catch (e) {
      debugPrint('[Supabase] getGradeById error: $e');
      rethrow;
    }
  }

  @override
  Future<GradeModel> createGrade({
    required String name,
    required String code,
    String? gradeLevel,
    String? colorHex,
    String? schedule,
    int sortOrder = 0,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) throw const ServerException('Supabase client not initialized');

    try {
      final teacherId = client.auth.currentUser?.id;
      final payload = <String, dynamic>{
        'name': name,
        'code': code,
        'color': colorHex ?? '#4f8ef7',
        'schedule': schedule ?? 'السبت والثلاثاء • 5:00م',
        'sort_order': sortOrder,
      };
      if (teacherId != null && teacherId.isNotEmpty) {
        payload['teacher_id'] = teacherId;
      }

      dynamic inserted;
      try {
        inserted = await client.from('grades').insert(payload).select().single();
      } catch (e) {
        // If failed due to teacher_id column not existing in grades table, retry without it
        if (payload.containsKey('teacher_id')) {
          payload.remove('teacher_id');
          inserted = await client.from('grades').insert(payload).select().single();
        } else {
          rethrow;
        }
      }

      return GradeModel.fromJson({
        'id': inserted['id'].toString(),
        'name': inserted['name'],
        'code': inserted['code'],
        'color': inserted['color'] ?? colorHex ?? '#4f8ef7',
        'schedule': inserted['schedule'] ?? schedule ?? 'السبت والثلاثاء • 5:00م',
        'student_count': 0,
        'average_attendance': 100.0,
      });
    } catch (e) {
      debugPrint('[Supabase] createGrade error: $e');
      rethrow;
    }
  }

  @override
  Future<GradeModel> updateGrade({
    required String id,
    String? name,
    String? code,
    String? gradeLevel,
    String? colorHex,
    String? schedule,
    int? sortOrder,
    bool? isActive,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) throw const ServerException('Supabase client not initialized');

    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (code != null) updateData['code'] = code;
      if (colorHex != null) updateData['color'] = colorHex;
      if (schedule != null) updateData['schedule'] = schedule;
      if (sortOrder != null) updateData['sort_order'] = sortOrder;
      if (isActive != null) updateData['is_active'] = isActive;

      final updated = await client.from('grades').update(updateData).eq('id', id).select().single();
      return GradeModel.fromJson(updated);
    } catch (e) {
      debugPrint('[Supabase] updateGrade error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteGrade(String id) async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      await client.from('grades').delete().eq('id', id);
    } catch (e) {
      debugPrint('[Supabase] deleteGrade error: $e');
      rethrow;
    }
  }
}
