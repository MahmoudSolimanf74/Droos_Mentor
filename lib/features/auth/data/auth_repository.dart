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
  Future<UserProfile> updateProfileName(String newName);
  Future<void> signOut();
  Stream<UserProfile?> get authStateChanges;
}

class AuthRepositoryImpl implements AuthRepository {
  UserProfile? _cachedUser;

  @override
  Future<UserProfile?> getCurrentUser() async {
    final client = SupabaseConfig.client;
    if (client == null) {
      _cachedUser = null;
      return null;
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
        var profile = UserProfile.fromJson(response);
        // If user was previously registered in student app, allow/upgrade to teacher role
        if (profile.role == 'student') {
          try {
            await client.from('profiles').update({'role': 'teacher'}).eq('id', session.user.id);
            profile = profile.copyWith(role: 'teacher');
          } catch (e) {
            debugPrint('[Role Upgrade note]: $e');
            profile = profile.copyWith(role: 'teacher');
          }
        }
        _cachedUser = profile;
        return _cachedUser;
      }

      // If profile not created yet, create from OAuth session
      final teacherName = session.user.userMetadata?['full_name'] ??
          session.user.userMetadata?['name'] ??
          session.user.email?.split('@').first ??
          'الأستاذ';
      final teacherEmail = session.user.email ?? '';
      final teacherAvatar = session.user.userMetadata?['avatar_url'] as String?;

      final newProfile = UserProfile(
        id: session.user.id,
        name: teacherName,
        email: teacherEmail,
        avatarUrl: teacherAvatar,
        role: 'teacher',
        createdAt: DateTime.now(),
      );

      try {
        await client.from('profiles').upsert({
          'id': session.user.id,
          'name': teacherName,
          'email': teacherEmail,
          'avatar_url': teacherAvatar,
          'role': 'teacher',
        });
      } catch (upsertErr) {
        debugPrint('Profile upsert fallback: $upsertErr');
      }

      try {
        final cleanId = session.user.id.replaceAll('-', '');
        final teacherCode = 'TCH-${cleanId.length >= 6 ? cleanId.substring(0, 6).toUpperCase() : 'PROG01'}';
        await client.from('teachers').upsert({
          'profile_id': session.user.id,
          'display_name': teacherName,
          'teacher_code': teacherCode,
        }, onConflict: 'profile_id');
      } catch (tchErr) {
        debugPrint('Teacher record upsert fallback: $tchErr');
      }

      _cachedUser = newProfile;
      return _cachedUser;
    } catch (e) {
      if (e is RoleUnauthorizedException) rethrow;
      debugPrint('Error loading profile: $e');

      final fallbackProfile = UserProfile(
        id: session.user.id,
        name: session.user.userMetadata?['full_name'] ??
            session.user.userMetadata?['name'] ??
            session.user.email?.split('@').first ??
            'المعلم',
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
    final client = SupabaseConfig.client;
    if (client == null) {
      throw const AuthException('تعذر الاتصال بخادم قاعدة البيانات');
    }

    try {
      final origin = kIsWeb ? Uri.base.origin.toLowerCase() : '';
      final redirectUrl = kIsWeb
          ? (origin.contains('localhost')
              ? origin
              : '$origin/Droos_Mentor/')
          : 'io.supabase.teacher://login-callback';

      debugPrint('[signInWithGoogle] isWeb: $kIsWeb, redirectUrl: $redirectUrl');

      await client.auth.signInWithOAuth(
        sb.OAuthProvider.google,
        redirectTo: redirectUrl,
        authScreenLaunchMode: kIsWeb
            ? sb.LaunchMode.platformDefault
            : sb.LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('[signInWithGoogle] error: $e');
      throw AuthException('خطأ أثناء بدء تسجيل الدخول بـ Google: $e');
    }
  }

  @override
  Future<UserProfile> signInWithEmailPassword(String email, String password) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw const AuthException('تعذر الاتصال بقاعدة البيانات');
    }

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
    final client = SupabaseConfig.client;
    if (client == null) {
      throw const AuthException('تعذر الاتصال بقاعدة البيانات');
    }

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
      if (user == null) {
        throw const AuthException('تم إنشاء الحساب، يرجى تسجيل الدخول');
      }
      return user;
    } catch (e) {
      throw AuthException(e.toString().replaceAll('AuthException: ', ''));
    }
  }

  @override
  Future<UserProfile> updateProfileName(String newName) async {
    final cleanName = newName.trim();
    if (cleanName.isEmpty) throw const ServerException('يرجى إدخال اسم صحيح');

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
    if (client != null) {
      await client.auth.signOut();
    }
  }

  @override
  Stream<UserProfile?> get authStateChanges async* {
    final client = SupabaseConfig.client;
    if (client == null) {
      yield null;
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
