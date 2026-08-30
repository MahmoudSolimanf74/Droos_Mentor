import 'package:flutter/foundation.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/token_generator.dart';
import '../domain/group_model.dart';

abstract class GroupsRepository {
  Future<List<GroupModel>> getGroups({String? gradeId});
  Future<GroupModel> getGroupById(String groupId);
  Future<GroupModel> createGroup({required String name, required String gradeId});
  Future<GroupModel> updateGroup({
    required String groupId,
    required String name,
    required String gradeId,
    String? status,
  });
  Future<void> deleteGroup(String groupId);
  Future<String> regenerateQrToken(String groupId);
  Future<String> regenerateJoinCode(String groupId);
  Future<bool> toggleActive(String groupId, bool isActive);
}

class GroupsRepositoryImpl implements GroupsRepository {
  @override
  Future<List<GroupModel>> getGroups({String? gradeId}) async {
    final client = SupabaseConfig.client;
    if (client == null) return [];

    try {
      final teacherId = client.auth.currentUser?.id;
      var query = client.from('grades').select('*, students(id)');
      if (teacherId != null && teacherId.isNotEmpty) {
        query = query.eq('teacher_id', teacherId);
      }
      if (gradeId != null && gradeId.isNotEmpty) {
        query = query.eq('id', gradeId);
      }
      final response = await query.order('sort_order', ascending: true);

      return (response as List<dynamic>).map((item) {
        final students = item['students'] as List<dynamic>? ?? [];
        return GroupModel.fromJson(item, students.length);
      }).toList();
    } catch (e) {
      debugPrint('[Supabase] getGroups error: $e');
      return [];
    }
  }

  @override
  Future<GroupModel> getGroupById(String groupId) async {
    final groups = await getGroups(gradeId: groupId);
    if (groups.isNotEmpty) return groups.first;
    throw const ServerException('المجموعة غير موجودة');
  }

  @override
  Future<GroupModel> createGroup({required String name, required String gradeId}) async {
    final joinCode = TokenGenerator.generateGroupCode();
    final client = SupabaseConfig.client;
    if (client == null) throw const ServerException('Supabase client not initialized');

    try {
      final payload = <String, dynamic>{
        'name': name,
        'code': joinCode,
        'color': '#4f8ef7',
        'schedule': 'السبت والثلاثاء • 5:00م',
      };
      final teacherId = client.auth.currentUser?.id;
      if (teacherId != null && teacherId.isNotEmpty) {
        payload['teacher_id'] = teacherId;
      }

      dynamic response;
      try {
        response = await client.from('grades').insert(payload).select().single();
      } catch (_) {
        payload.remove('teacher_id');
        response = await client.from('grades').insert(payload).select().single();
      }

      return GroupModel.fromJson(response, 0);
    } catch (e) {
      throw ServerException('فشل إنشاء المجموعة: $e');
    }
  }

  @override
  Future<GroupModel> updateGroup({
    required String groupId,
    required String name,
    required String gradeId,
    String? status,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) throw const ServerException('Supabase client not initialized');

    try {
      final response = await client
          .from('grades')
          .update({'name': name})
          .eq('id', groupId)
          .select('*, students(id)')
          .single();

      final students = response['students'] as List<dynamic>? ?? [];
      return GroupModel.fromJson(response, students.length);
    } catch (e) {
      throw ServerException('فشل تعديل المجموعة: $e');
    }
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      await client.from('grades').delete().eq('id', groupId);
    } catch (e) {
      throw ServerException('فشل حذف المجموعة: $e');
    }
  }

  @override
  Future<String> regenerateQrToken(String groupId) async {
    return TokenGenerator.generateInviteToken();
  }

  @override
  Future<String> regenerateJoinCode(String groupId) async {
    final newCode = TokenGenerator.generateJoinCode();
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client.from('grades').update({'code': newCode}).eq('id', groupId);
      } catch (_) {}
    }
    return newCode;
  }

  @override
  Future<bool> toggleActive(String groupId, bool isActive) async {
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client.from('grades').update({'is_active': isActive}).eq('id', groupId);
      } catch (_) {}
    }
    return isActive;
  }
}
