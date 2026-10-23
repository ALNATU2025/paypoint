import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paypoint brand colours, taken from the flyer and the UI design canvas.
class AppColors {
  AppColors._();

  static const Color deep = Color(0xFF071036);
  static const Color navy = Color(0xFF0B1A55);
  static const Color navy2 = Color(0xFF1A2C78);
  static const Color navy3 = Color(0xFF102472);
  static const Color ink = Color(0xFF0B1430);
  static const Color blue = Color(0xFF1840C8);
  static const Color bright = Color(0xFF3B6CFF);
  static const Color sky = Color(0xFFE6ECFF);
  static const Color skySoft = Color(0xFFEEF2FF);
  static const Color bg = Color(0xFFF5F7FC);
  static const Color border = Color(0xFFE1E6F2);
  static const Color divider = Color(0xFFEEF1F7);
  static const Color label = Color(0xFF2A3556);
  static const Color body = Color(0xFF4A5577);
  static const Color muted = Color(0xFF5A6480);
  static const Color faint = Color(0xFF8A93AD);
  static const Color onNavyMuted = Color(0xFFC2CEF6);
  static const Color onNavyFaint = Color(0xFF9FB2F2);

  static const Color success = Color(0xFF14823A);
  static const Color successBg = Color(0xFFE3F6E8);
  static const Color successStrong = Color(0xFF1E9A3E);
  static const Color warning = Color(0xFFB4500F);
  static const Color warningBg = Color(0xFFFFF4E3);
  static const Color warningText = Color(0xFF7A3A0A);
  static const Color amber = Color(0xFFFFB020);
  static const Color orange = Color(0xFFF28C1B);
  static const Color danger = Color(0xFFB42318);
  static const Color dangerBg = Color(0xFFFDE8E8);

  // Shadows use ARGB literals so no deprecated opacity helpers are needed.
  static const Color shadowSoft = Color(0x0F0B1A55); // ~6%
  static const Color shadowMid = Color(0x290B1A55); // ~16%
  static const Color shadowBlue = Color(0x4D1840C8); // ~30%
}

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(color: AppColors.shadowSoft, blurRadius: 18, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> raised = [
    BoxShadow(color: AppColors.shadowMid, blurRadius: 40, offset: Offset(0, 20)),
  ];
  static const List<BoxShadow> button = [
    BoxShadow(color: AppColors.shadowBlue, blurRadius: 28, offset: Offset(0, 12)),
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        primary: AppColors.blue,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.bg,
    );

    final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );

    return base.copyWith(
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: const TextStyle(color: AppColors.faint),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.blue : AppColors.border,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }
}
