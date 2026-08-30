import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/config/supabase_config.dart';
import '../../../core/errors/exceptions.dart';
import '../domain/user_profile.dart';

abstract class AuthRepository {
  Future<UserProfile?> getCurrentUser();
  Future<void> signInWithGoogle();
  Future<UserProfile> signInWithEmailPassword(String email, String password);
  Future<UserProfile> signUpWithEmailPassword(String email, String password, String name);
  Future<UserProfile> signInDemoMode();
  Future<UserProfile> updateProfileName(String newName);
  Future<void> signOut();
  Stream<UserProfile?> get authStateChanges;
}

class AuthRepositoryImpl implements AuthRepository {
  UserProfile? _cachedUser;

  static final UserProfile demoTeacher = UserProfile(
    id: '00000000-0000-0000-0000-000000000001',
    teacherId: 'tch-1',
    teacherCode: 'TCH-PROG01',
    name: 'م. أحمد مصطفى',
    email: 'ahmed.mostafa@classpilot.dev',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    role: 'teacher',
    createdAt: DateTime(2025, 9, 1),
  );

  @override
  Future<UserProfile?> getCurrentUser() async {
    if (SupabaseConfig.isDemoMode) {
      return _cachedUser ?? demoTeacher;
    }

    final client = SupabaseConfig.client;
    if (client == null) {
      return _cachedUser ?? demoTeacher;
    }

    final session = client.auth.currentSession;
    if (session == null) {
      _cachedUser = null;
      return null;
    }

    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', session.user.id)
          .maybeSingle();

      if (response != null) {
        final profile = UserProfile.fromJson(response);
        if (profile.role == 'student') {
          await client.auth.signOut();
          _cachedUser = null;
          throw const RoleUnauthorizedException('الحساب المسجل ليس حساب معلم مصرح له بالدخول لتطبيق الإدارة.');
        }
        _cachedUser = profile;
        return _cachedUser;
      }

      // If profile not created yet, create from OAuth session
      final newProfile = UserProfile(
        id: session.user.id,
        name: session.user.userMetadata?['full_name'] ?? session.user.userMetadata?['name'] ?? session.user.email?.split('@').first ?? 'الأستاذ',
        email: session.user.email ?? '',
        avatarUrl: session.user.userMetadata?['avatar_url'] as String?,
        role: 'teacher',
        createdAt: DateTime.now(),
      );

      try {
        await client.from('profiles').upsert(newProfile.toJson());
      } catch (upsertErr) {
        debugPrint('Profile upsert fallback: $upsertErr');
      }

      _cachedUser = newProfile;
      return _cachedUser;
    } catch (e) {
      if (e is RoleUnauthorizedException) rethrow;
      debugPrint('Error loading profile: $e');

      // Fallback: don't kick user out if session exists
      final fallbackProfile = UserProfile(
        id: session.user.id,
        name: session.user.userMetadata?['full_name'] ?? session.user.userMetadata?['name'] ?? session.user.email?.split('@').first ?? 'الأستاذ',
        email: session.user.email ?? '',
        avatarUrl: session.user.userMetadata?['avatar_url'] as String?,
        role: 'teacher',
        createdAt: DateTime.now(),
      );
      _cachedUser = fallbackProfile;
      return _cachedUser;
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    if (SupabaseConfig.isDemoMode) {
      _cachedUser = demoTeacher;
      return;
    }

    final client = SupabaseConfig.client;
    if (client == null) {
      _cachedUser = demoTeacher;
      return;
    }

    try {
      String? redirectUrl;
      if (kIsWeb) {
        redirectUrl = null;
      } else if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        redirectUrl = null;
      } else {
        redirectUrl = 'io.supabase.teacher://login-callback';
      }

      await client.auth.signInWithOAuth(
        sb.OAuthProvider.google,
        redirectTo: redirectUrl,
        authScreenLaunchMode: sb.LaunchMode.externalApplication,
      );
    } catch (e) {
      throw AuthException('خطأ أثناء بدء تسجيل الدخول بـ Google: $e');
    }
  }

  @override
  Future<UserProfile> signInWithEmailPassword(String email, String password) async {
    if (SupabaseConfig.isDemoMode || SupabaseConfig.client == null) {
      _cachedUser = demoTeacher;
      return demoTeacher;
    }

    final client = SupabaseConfig.client!;
    try {
      final res = await client.auth.signInWithPassword(email: email, password: password);
      if (res.user == null) {
        throw const AuthException('بيانات الدخول غير صحيحة');
      }
      final user = await getCurrentUser();
      if (user == null) {
        throw const AuthException('تعذر تحميل بيانات المعلم');
      }
      return user;
    } catch (e) {
      if (e is RoleUnauthorizedException) rethrow;
      throw AuthException(e.toString().replaceAll('AuthException: ', ''));
    }
  }

  @override
  Future<UserProfile> signUpWithEmailPassword(String email, String password, String name) async {
    if (SupabaseConfig.isDemoMode || SupabaseConfig.client == null) {
      _cachedUser = demoTeacher;
      return demoTeacher;
    }

    final client = SupabaseConfig.client!;
    try {
      final res = await client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name, 'role': 'teacher'},
      );
      if (res.user == null) {
        throw const AuthException('فشل إنشاء الحساب');
      }
      final user = await getCurrentUser();
      return user ?? demoTeacher;
    } catch (e) {
      throw AuthException(e.toString().replaceAll('AuthException: ', ''));
    }
  }

  @override
  Future<UserProfile> signInDemoMode() async {
    await SupabaseConfig.enableDemoMode();
    _cachedUser = demoTeacher;
    return demoTeacher;
  }

  @override
  Future<UserProfile> updateProfileName(String newName) async {
    final cleanName = newName.trim();
    if (cleanName.isEmpty) throw const ServerException('يرجى إدخال اسم صحيح');

    if (SupabaseConfig.isDemoMode) {
      final current = _cachedUser ?? demoTeacher;
      final updated = current.copyWith(name: cleanName);
      _cachedUser = updated;
      return updated;
    }

    final client = SupabaseConfig.client;
    final user = client?.auth.currentUser;
    if (user == null || client == null) throw const ServerException('المستخدم غير مسجل');

    try {
      // 1. Update profiles table
      try {
        await client.from('profiles').update({'name': cleanName}).eq('id', user.id);
      } catch (e) {
        debugPrint('[updateProfileName] profiles update note: $e');
      }

      // 2. Update teachers table if exists
      try {
        await client.from('teachers').update({'display_name': cleanName}).eq('profile_id', user.id);
      } catch (e) {
        debugPrint('[updateProfileName] teachers update note: $e');
      }

      // 3. Update auth user metadata
      try {
        await client.auth.updateUser(sb.UserAttributes(data: {'full_name': cleanName, 'name': cleanName}));
      } catch (e) {
        debugPrint('[updateProfileName] auth metadata update note: $e');
      }

      final updatedProfile = await getCurrentUser();
      final result = updatedProfile ??
          UserProfile(
            id: user.id,
            name: cleanName,
            email: user.email ?? '',
            role: 'teacher',
            createdAt: DateTime.now(),
          );
      _cachedUser = result;
      return result;
    } catch (e) {
      throw ServerException('فشل تحديث الاسم: $e');
    }
  }

  @override
  Future<void> signOut() async {
    _cachedUser = null;
    final client = SupabaseConfig.client;
    if (client != null && !SupabaseConfig.isDemoMode) {
      await client.auth.signOut();
    }
  }

  @override
  Stream<UserProfile?> get authStateChanges async* {
    if (SupabaseConfig.isDemoMode) {
      yield _cachedUser ?? demoTeacher;
      return;
    }

    final client = SupabaseConfig.client;
    if (client == null) {
      yield _cachedUser ?? demoTeacher;
      return;
    }

    await for (final authState in client.auth.onAuthStateChange) {
      if (authState.session != null) {
        yield await getCurrentUser();
      } else {
        _cachedUser = null;
        yield null;
      }
    }
  }
}
