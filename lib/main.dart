import 'package:flutter/material.dart';
import 'app.dart';
import 'core/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved config & attempt Supabase initialization (or initialize in demo mode)
  await SupabaseConfig.loadConfig();
  await SupabaseConfig.initialize();

  runApp(const ClassPilotTeacherApp());
}
