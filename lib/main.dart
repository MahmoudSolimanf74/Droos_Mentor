import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'app.dart';
import 'core/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register Windows Desktop URL protocol for Deep Linking
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    try {
      await protocolHandler.register('io.supabase.teacher');
    } catch (e) {
      debugPrint('ProtocolHandler registration error: $e');
    }
  }

  // Load saved config & attempt Supabase initialization
  await SupabaseConfig.loadConfig();
  await SupabaseConfig.initialize();

  // On Web: capture OAuth callback from URL parameters if present
  if (kIsWeb) {
    try {
      final uri = Uri.base;
      if (uri.fragment.contains('access_token') || uri.queryParameters.containsKey('code')) {
        debugPrint('[Web OAuth Callback] Processing tokens from URL: $uri');
        await SupabaseConfig.client?.auth.getSessionFromUrl(uri);
      }
    } catch (e) {
      debugPrint('[Web OAuth Callback] getSessionFromUrl error: $e');
    }
  }

  runApp(const ClassPilotTeacherApp());
}
