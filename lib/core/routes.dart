import 'package:flutter/material.dart';

import '../models/models.dart';
import '../screens/main_shell.dart';
import '../screens/onboarding_screen.dart';
import '../screens/packages_screen.dart';
import '../screens/payment_method_screen.dart';
import '../screens/pin_screen.dart';
import '../screens/receipt_screen.dart';
import '../screens/review_screen.dart';
import '../screens/sign_up_screen.dart';
import '../screens/smartcard_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/success_screen.dart';
import '../screens/verify_screen.dart';

class Routes {
  Routes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const signUp = '/sign-up';
  static const verify = '/verify';
  static const main = '/main';
  static const smartcard = '/pay/smartcard';
  static const packages = '/pay/packages';
  static const review = '/pay/review';
  static const payment = '/pay/method';
  static const pin = '/pay/pin';
  static const success = '/pay/success';
  static const receipt = '/receipt';

  static Route<dynamic> onGenerate(RouteSettings s) {
    Widget page;
    switch (s.name) {
      case splash:
        page = const SplashScreen();
      case onboarding:
        page = const OnboardingScreen();
      case signUp:
        page = const SignUpScreen();
      case verify:
        page = const VerifyScreen();
      case main:
        page = MainShell(initialTab: (s.arguments as int?) ?? 0);
      case smartcard:
        page = const SmartcardScreen();
      case packages:
        page = const PackagesScreen();
      case review:
        page = const ReviewScreen();
      case payment:
        page = const PaymentMethodScreen();
      case pin:
        return PageRouteBuilder<void>(
          settings: s,
          opaque: false,
          barrierColor: Colors.transparent,
          transitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (_, __, ___) => const PinScreen(),
          transitionsBuilder: (_, a, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
            child: child,
          ),
        );
      case success:
        page = SuccessScreen(tx: s.arguments! as TvTransaction);
      case receipt:
        page = ReceiptScreen(tx: s.arguments! as TvTransaction);
      default:
        page = const SplashScreen();
    }
    return MaterialPageRoute<void>(settings: s, builder: (_) => page);
  }
}
