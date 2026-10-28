import 'package:flutter/material.dart';

import '../models/models.dart';
import '../screens/admin_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_shell.dart';
import '../screens/onboarding_screen.dart';
import '../screens/packages_screen.dart';
import '../screens/payment_method_screen.dart';
import '../screens/pin_screen.dart';
import '../screens/pin_setup_screen.dart';
import '../screens/receipt_screen.dart';
import '../screens/review_screen.dart';
import '../screens/sign_up_screen.dart';
import '../screens/smartcard_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/success_screen.dart';

class Routes {
  Routes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const signUp = '/sign-up';
  static const login = '/login';
  static const createPin = '/create-pin';
  static const changePin = '/change-pin';
  static const main = '/main';
  static const smartcard = '/pay/smartcard';
  static const packages = '/pay/packages';
  static const review = '/pay/review';
  static const payment = '/pay/method';
  static const pin = '/pay/pin';
  static const success = '/pay/success';
  static const receipt = '/receipt';
  static const admin = '/admin';

  /// The page widget for a route name.
  static Widget build(String? name, [Object? args]) {
    switch (name) {
      case onboarding:
        return const OnboardingScreen();
      case signUp:
        return const SignUpScreen();
      case login:
        return const LoginScreen();
      case admin:
        return const AdminScreen();
      case createPin:
        return const PinSetupScreen();
      case changePin:
        return const PinSetupScreen(change: true);
      case main:
        return MainShell(initialTab: (args as int?) ?? 0);
      case smartcard:
        return const SmartcardScreen();
      case packages:
        return const PackagesScreen();
      case review:
        return const ReviewScreen();
      case payment:
        return const PaymentMethodScreen();
      case pin:
        return const PinScreen();
      case success:
        return SuccessScreen(tx: args! as TvTransaction);
      case receipt:
        return ReceiptScreen(tx: args! as TvTransaction);
      default:
        return const SplashScreen();
    }
  }

  static Route<dynamic> onGenerate(RouteSettings s) {
    final page = build(s.name, s.arguments);
    switch (s.name) {
      // PIN slides up as a sheet over a dimmed, blurred backdrop.
      case pin:
        return PageRouteBuilder<void>(
          settings: s,
          opaque: false,
          barrierColor: const Color(0x99071036),
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, a, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
            child: child,
          ),
        );
      // Celebration screens zoom in softly instead of sliding.
      case success:
      case main:
        return PageRouteBuilder<void>(
          settings: s,
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, a, __, child) {
            final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: c,
              child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(c), child: child),
            );
          },
        );
      default:
        return MaterialPageRoute<void>(settings: s, builder: (_) => page);
    }
  }
}
