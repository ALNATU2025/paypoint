import 'package:flutter/cupertino.dart';
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
  static const Color electric = Color(0xFF5B8CFF);
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

  // Shadows use ARGB literals so no opacity helpers are needed.
  static const Color shadowSoft = Color(0x0F0B1A55); // ~6%
  static const Color shadowMid = Color(0x290B1A55); // ~16%
  static const Color shadowBlue = Color(0x4D1840C8); // ~30%
}

/// Brand gradients. Used sparingly: hero cards, primary actions, selected states.
class AppGradients {
  AppGradients._();

  /// Primary call-to-action.
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A55E8), AppColors.blue, Color(0xFF1433A8)],
    stops: [0, 0.55, 1],
  );

  /// Deep navy hero surfaces (wallet, review, receipt header).
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A2F8A), AppColors.navy, Color(0xFF071036)],
    stops: [0, 0.55, 1],
  );

  /// Selected outline on option cards.
  static const LinearGradient selectedBorder = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.bright, AppColors.blue],
  );

  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34C266), AppColors.successStrong, Color(0xFF14823A)],
  );

  static const LinearGradient warm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFC24A), AppColors.orange],
  );

  /// A lighter-to-darker sweep of any brand colour (provider tiles).
  static LinearGradient of(Color c) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.lerp(c, Colors.white, 0.18)!, c, Color.lerp(c, Colors.black, 0.25)!],
        stops: const [0, 0.5, 1],
      );
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
  static const List<BoxShadow> glowBlue = [
    BoxShadow(color: Color(0x381840C8), blurRadius: 26, offset: Offset(0, 12)),
  ];
  static const List<BoxShadow> hero = [
    BoxShadow(color: Color(0x520B1A55), blurRadius: 44, offset: Offset(0, 22)),
  ];
}

/// Fade + gentle horizontal slide, used for every pushed page on Android,
/// web and desktop. iOS keeps the native swipe-back transition.
class PremiumPageTransitionsBuilder extends PageTransitionsBuilder {
  const PremiumPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final incoming = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    final outgoing = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic);
    return SlideTransition(
      position: Tween(begin: Offset.zero, end: const Offset(-0.06, 0)).animate(outgoing),
      child: FadeTransition(
        opacity: incoming,
        child: SlideTransition(
          position: Tween(begin: const Offset(0.09, 0), end: Offset.zero).animate(incoming),
          child: child,
        ),
      ),
    );
  }
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
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PremiumPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: PremiumPageTransitionsBuilder(),
          TargetPlatform.linux: PremiumPageTransitionsBuilder(),
          TargetPlatform.fuchsia: PremiumPageTransitionsBuilder(),
        },
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.blue),
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
          borderSide: const BorderSide(color: AppColors.blue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
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
