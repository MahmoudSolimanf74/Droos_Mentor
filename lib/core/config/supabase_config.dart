import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const String _prefUrlKey = 'supabase_url';
  static const String _prefAnonKey = 'supabase_anon_key';
  static const String _prefDemoModeKey = 'demo_mode_enabled';

  // Live Supabase Project Credentials
  static const String defaultUrl = 'https://tuqjyvauojrxvkttakcz.supabase.co';
  static const String defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR1cWp5dmF1b2pyeHZrdHRha2N6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc4NDQ1NjUsImV4cCI6MjEwMzQyMDU2NX0.xlmxk5cPHRIXDwS5KKc8Sz5UKA05UG7yTS5dZz5Wscg';

  static String _currentUrl = defaultUrl;
  static String _currentAnonKey = defaultAnonKey;
  static bool _isInitialized = false;

  static String get currentUrl => _currentUrl;
  static String get currentAnonKey => _currentAnonKey;
  static bool get isInitialized => _isInitialized;
  static bool get isDemoMode => false; // Demo mode completely disabled

  static SupabaseClient? get client {
    if (_isInitialized) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    // Purge any saved demo mode flag
    await prefs.remove(_prefDemoModeKey);
    _currentUrl = prefs.getString(_prefUrlKey) ?? defaultUrl;
    _currentAnonKey = prefs.getString(_prefAnonKey) ?? defaultAnonKey;
  }

  static Future<bool> initialize({String? url, String? anonKey, bool? demoMode}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefDemoModeKey);

    if (url != null && url.isNotEmpty) {
      _currentUrl = url;
      await prefs.setString(_prefUrlKey, url);
    }
    if (anonKey != null && anonKey.isNotEmpty) {
      _currentAnonKey = anonKey;
      await prefs.setString(_prefAnonKey, anonKey);
    }

    try {
      // ignore: deprecated_member_use
      await Supabase.initialize(
        url: _currentUrl,
        // ignore: deprecated_member_use
        anonKey: _currentAnonKey,
      );
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('[Supabase] Initialization error: $e');
      _isInitialized = false;
      return false;
    }
  }

  static Future<void> enableDemoMode() async {
    // No-op: Demo mode completely removed
  }

  static Future<void> disableDemoMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefDemoModeKey);
    await initialize();
  }
}
