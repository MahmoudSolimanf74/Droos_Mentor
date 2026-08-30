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
  static bool _isDemoMode = false; // Live mode by default with project keys

  static String get currentUrl => _currentUrl;
  static String get currentAnonKey => _currentAnonKey;
  static bool get isInitialized => _isInitialized;
  static bool get isDemoMode => _isDemoMode;

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
    _currentUrl = prefs.getString(_prefUrlKey) ?? defaultUrl;
    _currentAnonKey = prefs.getString(_prefAnonKey) ?? defaultAnonKey;
    _isDemoMode = prefs.getBool(_prefDemoModeKey) ?? false;
  }

  static Future<bool> initialize({String? url, String? anonKey, bool? demoMode}) async {
    final prefs = await SharedPreferences.getInstance();

    if (url != null) {
      _currentUrl = url;
      await prefs.setString(_prefUrlKey, url);
    }
    if (anonKey != null) {
      _currentAnonKey = anonKey;
      await prefs.setString(_prefAnonKey, anonKey);
    }
    if (demoMode != null) {
      _isDemoMode = demoMode;
      await prefs.setBool(_prefDemoModeKey, demoMode);
    }

    if (_isDemoMode || _currentUrl.isEmpty) {
      _isDemoMode = true;
      _isInitialized = false;
      return true;
    }

    try {
      // ignore: deprecated_member_use
      await Supabase.initialize(
        url: _currentUrl,
        // ignore: deprecated_member_use
        anonKey: _currentAnonKey,
      );
      _isInitialized = true;
      _isDemoMode = false;
      await prefs.setBool(_prefDemoModeKey, false);
      return true;
    } catch (e) {
      // Fallback to demo mode if connection fails
      _isInitialized = false;
      _isDemoMode = true;
      return false;
    }
  }

  static Future<void> enableDemoMode() async {
    _isDemoMode = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefDemoModeKey, true);
  }

  static Future<void> disableDemoMode() async {
    _isDemoMode = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefDemoModeKey, false);
    await initialize();
  }
}
