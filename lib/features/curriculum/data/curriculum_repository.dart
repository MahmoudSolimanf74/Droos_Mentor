import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/errors/exceptions.dart';
import '../domain/curriculum_model.dart';
import '../domain/lesson_file_model.dart';
import '../domain/lesson_model.dart';
import '../domain/unit_model.dart';

abstract class CurriculumRepository {
  Future<CurriculumModel> getCurriculum(String groupId);
  Future<CurriculumModel?> getCurriculumByGrade(String gradeId);
  Future<CurriculumModel> createCurriculum({required String gradeId, required String title});
  Future<List<UnitModel>> getUnits(String curriculumId);
  Future<List<LessonModel>> getLessons(String unitId);
  Future<List<LessonFileModel>> getLessonFiles(String lessonId);
  Future<UnitModel> createUnit({required String curriculumId, required String title, String? description, int sortOrder = 0});
  Future<UnitModel> updateUnit({required String unitId, String? title, String? description, int? sortOrder});
  Future<LessonModel> createLesson({required String unitId, required String title, String? description, int sortOrder = 0});
  Future<LessonModel> updateLesson({required String lessonId, String? title, String? description, int? sortOrder});
  Future<LessonFileModel> uploadLessonFile({
    required String lessonId,
    required String title,
    String? filePath,
    String? fileName,
    Uint8List? fileBytes,
    required String fileType,
    required int fileSize,
  });
  Future<String?> getSignedFileUrl(String filePath);
  Future<void> deleteUnit(String unitId, [String? curriculumId]);
  Future<void> deleteLesson(String lessonId, [String? unitId]);
  Future<void> deleteLessonFile(String fileId, [String? lessonId]);
}

class CurriculumRepositoryImpl implements CurriculumRepository {
  @override
  Future<CurriculumModel> getCurriculum(String groupId) async {
    final curr = await getCurriculumByGrade(groupId);
    return curr ?? await createCurriculum(gradeId: groupId, title: 'منهج البرمجة والحاسب');
  }

  @override
  Future<CurriculumModel?> getCurriculumByGrade(String gradeId) async {
    final client = SupabaseConfig.client;
    if (client == null) return null;

    try {
      final res = await client.from('curriculum').select('*').eq('grade_id', gradeId).maybeSingle();
      if (res != null) {
        return CurriculumModel.fromJson({
          'id': res['id'].toString(),
          'grade_id': res['grade_id']?.toString() ?? gradeId,
          'title': res['title'] as String? ?? 'المنهج الدراسي المعتمد',
          'created_at': res['created_at']?.toString() ?? DateTime.now().toIso8601String(),
        });
      }
      return null;
    } catch (e) {
      debugPrint('[Supabase] getCurriculumByGrade error: $e');
      rethrow;
    }
  }

  @override
  Future<CurriculumModel> createCurriculum({required String gradeId, required String title}) async {
    final client = SupabaseConfig.client;
    if (client == null) throw const ServerException('Supabase client not initialized');

    try {
      final teacherId = client.auth.currentUser?.id;
      final payload = <String, dynamic>{
        'grade_id': gradeId,
        'title': title,
      };
      if (teacherId != null && teacherId.isNotEmpty) {
        payload['teacher_id'] = teacherId;
      }

      final inserted = await client.from('curriculum').insert(payload).select().single();

      return CurriculumModel.fromJson(inserted);
    } catch (e) {
      debugPrint('[Supabase] createCurriculum error: $e');
      rethrow;
    }
  }

  @override
  Future<List<UnitModel>> getUnits(String curriculumId) async {
    final client = SupabaseConfig.client;
    if (client == null) return [];

    try {
      final response = await client
          .from('units')
          .select('*')
          .eq('curriculum_id', curriculumId)
          .order('sort_order', ascending: true);

      final list = (response as List<dynamic>).map((u) => UnitModel.fromJson({
        'id': u['id'].toString(),
        'curriculum_id': u['curriculum_id']?.toString() ?? curriculumId,
        'title': u['title'] as String,
        'description': u['description'] as String?,
        'sort_order': u['sort_order'] as int? ?? 0,
        'created_at': u['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      })).toList();

      return list;
    } catch (e) {
      debugPrint('[Supabase] getUnits error: $e');
      rethrow;
    }
  }

  @override
  Future<List<LessonModel>> getLessons(String unitId) async {
    final client = SupabaseConfig.client;
    if (client == null) return [];

    try {
      final response = await client
          .from('lessons')
          .select('*')
          .eq('unit_id', unitId)
          .order('sort_order', ascending: true);

      final list = (response as List<dynamic>).map((l) => LessonModel.fromJson({
        'id': l['id'].toString(),
        'unit_id': l['unit_id']?.toString() ?? unitId,
        'title': l['title'] as String,
        'description': l['description'] as String?,
        'sort_order': l['sort_order'] as int? ?? 0,
        'created_at': l['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      })).toList();

      return list;
    } catch (e) {
      debugPrint('[Supabase] getLessons error: $e');
      rethrow;
    }
  }

  @override
  Future<List<LessonFileModel>> getLessonFiles(String lessonId) async {
    final client = SupabaseConfig.client;
    if (client == null) return [];

    try {
      final response = await client
          .from('lesson_files')
          .select('*')
          .eq('lesson_id', lessonId);

      final list = (response as List<dynamic>).map((f) => LessonFileModel.fromJson({
        'id': f['id'].toString(),
        'lesson_id': f['lesson_id']?.toString() ?? lessonId,
        'title': f['title'] as String,
        'file_path': f['file_path'] as String,
        'file_type': f['file_type'] as String? ?? 'pdf',
        'file_size': f['file_size'] as int? ?? 0,
        'created_at': f['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      })).toList();

      return list;
    } catch (e) {
      debugPrint('[Supabase] getLessonFiles error: $e');
      rethrow;
    }
  }

  @override
  Future<UnitModel> createUnit({required String curriculumId, required String title, String? description, int sortOrder = 0}) async {
    final client = SupabaseConfig.client;
    if (client == null) throw const ServerException('Supabase client not initialized');

    try {
      final inserted = await client.from('units').insert({
        'curriculum_id': curriculumId,
        'title': title,
        'description': description,
        'sort_order': sortOrder,
      }).select().single();

      return UnitModel.fromJson({
        'id': inserted['id'].toString(),
        'curriculum_id': curriculumId,
        'title': inserted['title'],
        'description': inserted['description'],
        'sort_order': inserted['sort_order'] ?? 0,
        'created_at': inserted['created_at'] ?? DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[Supabase] createUnit error: $e');
      rethrow;
    }
  }

  @override
  Future<UnitModel> updateUnit({required String unitId, String? title, String? description, int? sortOrder}) async {
    final client = SupabaseConfig.client;
    if (client == null) throw const ServerException('Supabase client not initialized');

    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (sortOrder != null) updateData['sort_order'] = sortOrder;
      final updated = await client.from('units').update(updateData).eq('id', unitId).select().single();

      return UnitModel.fromJson(updated);
    } catch (e) {
      debugPrint('[Supabase] updateUnit error: $e');
      rethrow;
    }
  }

  @override
  Future<LessonModel> createLesson({required String unitId, required String title, String? description, int sortOrder = 0}) async {
    final client = SupabaseConfig.client;
    if (client == null) throw const ServerException('Supabase client not initialized');

    try {
      final inserted = await client.from('lessons').insert({
        'unit_id': unitId,
        'title': title,
        'description': description,
        'sort_order': sortOrder,
      }).select().single();

      return LessonModel.fromJson({
        'id': inserted['id'].toString(),
        'unit_id': unitId,
        'title': inserted['title'],
        'description': inserted['description'],
        'sort_order': inserted['sort_order'] ?? 0,
        'created_at': inserted['created_at'] ?? DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[Supabase] createLesson error: $e');
      rethrow;
    }
  }

  @override
  Future<LessonModel> updateLesson({required String lessonId, String? title, String? description, int? sortOrder}) async {
    final client = SupabaseConfig.client;
    if (client == null) throw const ServerException('Supabase client not initialized');

    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (sortOrder != null) updateData['sort_order'] = sortOrder;
      final updated = await client.from('lessons').update(updateData).eq('id', lessonId).select().single();

      return LessonModel.fromJson(updated);
    } catch (e) {
      debugPrint('[Supabase] updateLesson error: $e');
      rethrow;
    }
  }

  @override
  Future<LessonFileModel> uploadLessonFile({
    required String lessonId,
    required String title,
    String? filePath,
    String? fileName,
    Uint8List? fileBytes,
    required String fileType,
    required int fileSize,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) throw const ServerException('Supabase client not initialized');

    final ext = (fileType.isNotEmpty ? fileType : (fileName?.split('.').last ?? 'pdf')).replaceAll('.', '');
    final cleanFileName = '${DateTime.now().millisecondsSinceEpoch}_${lessonId.substring(0, lessonId.length > 8 ? 8 : lessonId.length)}.$ext';
    final path = filePath ?? 'lessons/$cleanFileName';

    try {
      if (fileBytes != null && fileBytes.isNotEmpty) {
        await client.storage.from('lesson-files').uploadBinary(
          path,
          fileBytes,
          fileOptions: FileOptions(contentType: ext == 'pdf' ? 'application/pdf' : 'application/octet-stream'),
        );
      }

      final inserted = await client.from('lesson_files').insert({
        'lesson_id': lessonId,
        'title': title,
        'file_path': path,
        'file_type': fileType,
        'file_size': fileSize,
      }).select().single();

      return LessonFileModel.fromJson({
        'id': inserted['id'].toString(),
        'lesson_id': lessonId,
        'title': inserted['title'],
        'file_path': inserted['file_path'],
        'file_type': inserted['file_type'],
        'file_size': inserted['file_size'],
        'created_at': inserted['created_at'] ?? DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[Supabase] uploadLessonFile error: $e');
      rethrow;
    }
  }

  @override
  Future<String?> getSignedFileUrl(String filePath) async {
    final client = SupabaseConfig.client;
    if (client == null) return null;

    try {
      return client.storage.from('lesson-files').getPublicUrl(filePath);
    } catch (e) {
      debugPrint('[Supabase] getSignedFileUrl error: $e');
      return null;
    }
  }

  @override
  Future<void> deleteUnit(String unitId, [String? curriculumId]) async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      await client.from('units').delete().eq('id', unitId);
    } catch (e) {
      debugPrint('[Supabase] deleteUnit error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteLesson(String lessonId, [String? unitId]) async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      await client.from('lessons').delete().eq('id', lessonId);
    } catch (e) {
      debugPrint('[Supabase] deleteLesson error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteLessonFile(String fileId, [String? lessonId]) async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      await client.from('lesson_files').delete().eq('id', fileId);
    } catch (e) {
      debugPrint('[Supabase] deleteLessonFile error: $e');
      rethrow;
    }
  }
}
