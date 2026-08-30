import 'package:flutter/material.dart';

/// Dark Executive Design Tokens (Matching React Web Spec + Full Compatibility)
class AppColors {
  AppColors._();

  // Dark Theme Background & Cards
  static const Color background = Color(0xFF0B0F1A);     // #0b0f1a (C.bg)
  static const Color card = Color(0xFF131929);           // #131929 (C.card)
  static const Color cardHover = Color(0xFF1A2236);      // #1a2236 (C.cardHover)
  static const Color surface = Color(0xFF131929);
  static const Color surfaceElevated = Color(0xFF1A2236);
  static const Color surfaceMuted = Color(0xFF0F1827);

  // Borders
  static const Color border = Color(0xFF1E2D45);         // #1e2d45 (C.border)
  static const Color borderLight = Color(0xFF243352);    // #243352 (C.borderLight)
  static const Color divider = Color(0xFF1E2D45);

  // Primary & Vibrant Accents
  static const Color primaryDark = Color(0xFF0B0F1A);
  static const Color primary = Color(0xFF4F8EF7);        // #4f8ef7 (C.primary)
  static const Color primaryLight = Color(0xFF6BA1F8);
  static const Color primaryDim = Color(0x244F8EF7);     // rgba(79,142,247,0.14)
  static const Color cyan = Color(0xFF22D3EE);           // #22d3ee (C.cyan)
  static const Color green = Color(0xFF34D399);          // #34d399 (C.green)
  static const Color yellow = Color(0xFFFBBF24);         // #fbbf24 (C.yellow)
  static const Color red = Color(0xFFF87171);            // #f87171 (C.red)
  static const Color purple = Color(0xFFA78BFA);         // #a78bfa (C.purple)

  // Compatibility Accents
  static const Color sage = Color(0xFF34D399);
  static const Color sageLight = Color(0x2634D399);
  static const Color sageDark = Color(0xFF34D399);
  static const Color bronze = Color(0xFFFBBF24);
  static const Color bronzeLight = Color(0x26FBBF24);
  static const Color bronzeDark = Color(0xFFFBBF24);

  // Status mapping
  static const Color success = Color(0xFF34D399);
  static const Color successBg = Color(0x2634D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningBg = Color(0x26FBBF24);
  static const Color danger = Color(0xFFF87171);
  static const Color dangerBg = Color(0x26F87171);
  static const Color info = Color(0xFF4F8EF7);
  static const Color infoBg = Color(0x264F8EF7);

  // Typography & Content
  static const Color textPrimary = Color(0xFFD8E4F5);    // #d8e4f5 (C.text)
  static const Color textSecondary = Color(0xFF5A7A9A);  // #5a7a9a (C.muted)
  static const Color textMuted = Color(0xFF5A7A9A);
  static const Color textFaint = Color(0xFF2A4060);      // #2a4060 (C.faint)
  static const Color textOnPrimary = Colors.white;

  // Table & Spreadsheet Colors
  static const Color tableHeaderBg = Color(0xFF0F1827);
  static const Color tableRowAlt = Color(0xFF0E1422);
  static const Color tableRowHover = Color(0xFF1A2236);
}
