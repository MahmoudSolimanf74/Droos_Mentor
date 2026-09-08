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

  // Load saved config & attempt Supabase initialization (or initialize in demo mode)
  await SupabaseConfig.loadConfig();
  await SupabaseConfig.initialize();

  runApp(const ClassPilotTeacherApp());
}
