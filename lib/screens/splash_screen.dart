import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/motion.dart';
import '../widgets/paypoint_logo.dart';

/// Splash: drifting aurora, the logo drawing itself, the wordmark rising in
/// letter by letter, then a smooth hand-off to onboarding.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();
  late final AnimationController _load =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2900))..forward();
  Timer? _timer;
  bool _leaving = false;
  bool _minTimeDone = false;
  Future<bool>? _session;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 3100), () {
      _minTimeDone = true;
      _next();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _session = AppScope.read(context).init();
      _session!.then((_) => _next(), onError: (_) => _next());
    });
  }

  /// Leaves once the intro has played and the saved session has been checked.
  Future<void> _next() async {
    if (!mounted || _leaving || !_minTimeDone || _session == null) return;
    _leaving = true;
    _timer?.cancel();
    final loggedIn = await _session!.catchError((_) => false);
    if (!mounted) return;
    final s = AppScope.read(context);
    final target = loggedIn
        ? (s.hasPin ? Routes.main : Routes.createPin)
        : (s.onboardingSeen ? Routes.login : Routes.onboarding);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        settings: RouteSettings(name: target),
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) => Routes.build(target),
        transitionsBuilder: (_, a, __, child) {
          final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: c,
            child: ScaleTransition(scale: Tween(begin: 1.06, end: 1.0).animate(c), child: child),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intro.dispose();
    _load.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draw = CurvedAnimation(parent: _intro, curve: const Interval(0.15, 0.85, curve: Curves.easeInOutCubic));
    final pop = CurvedAnimation(parent: _intro, curve: const Interval(0, 0.5, curve: Curves.easeOutBack));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.deep,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _minTimeDone = true;
            _next();
          },
          child: AuroraBackground(
            intensity: 0.5,
            child: Stack(
              children: [
                Align(
                  alignment: const Alignment(0, -0.12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PulseRings(
                        maxRadius: 170,
                        color: AppColors.electric,
                        child: AnimatedBuilder(
                          animation: _intro,
                          builder: (_, __) => Transform.scale(
                            scale: 0.5 + 0.5 * pop.value,
                            child: Opacity(
                              opacity: pop.value.clamp(0.0, 1.0),
                              child: LogoTile(size: 108, radius: 32, glow: true, progress: draw.value),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const StaggeredText(
                        'Paypoint',
                        delay: Duration(milliseconds: 650),
                        style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800, letterSpacing: -1),
                      ),
                      const SizedBox(height: 10),
                      const FadeSlideIn(
                        delay: Duration(milliseconds: 1250),
                        offset: Offset(0, 10),
                        child: Text(
                          'PAY BILLS  ·  STAY CONNECTED',
                          style: TextStyle(
                            color: Color(0xFFB9C6F5),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.paddingOf(context).bottom + 56,
                  child: FadeSlideIn(
                    delay: const Duration(milliseconds: 900),
                    child: Column(
                      children: [
                        Container(
                          width: 140,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          alignment: Alignment.centerLeft,
                          child: AnimatedBuilder(
                            animation: _load,
                            builder: (_, __) => FractionallySizedBox(
                              widthFactor: Curves.easeInOutCubic.transform(_load.value),
                              heightFactor: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [AppColors.bright, Colors.white]),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: const [BoxShadow(color: Color(0x995B8CFF), blurRadius: 10)],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Your TV, our priority',
                          style: TextStyle(color: Color(0xFFC9D3F7), fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
