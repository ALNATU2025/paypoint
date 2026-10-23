import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/paypoint_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
  late final AnimationController _dots =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2600), _next);
  }

  void _next() {
    if (!mounted) return;
    _timer?.cancel();
    Navigator.of(context).pushReplacementNamed(Routes.onboarding);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final logoAnim = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    final fade = CurvedAnimation(parent: _c, curve: const Interval(0.35, 1, curve: Curves.easeOut));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.deep,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _next,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: RingsPainter(
                    center: Offset(size.width / 2, size.height * 0.45),
                    radii: const [150, 230, 320],
                  ),
                ),
              ),
              Positioned.fill(child: CustomPaint(painter: _WavesPainter())),
              Align(
                alignment: const Alignment(0, -0.1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: Tween(begin: 0.6, end: 1.0).animate(logoAnim),
                      child: const LogoTile(size: 104, radius: 30, glow: true),
                    ),
                    const SizedBox(height: 22),
                    FadeTransition(
                      opacity: fade,
                      child: const Column(
                        children: [
                          Text(
                            'Paypoint',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'PAY BILLS  ·  STAY CONNECTED',
                            style: TextStyle(
                              color: Color(0xFFB9C6F5),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 3.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 64,
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _dots,
                      builder: (_, __) {
                        final active = (_dots.value * 3).floor() % 3;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            final on = i == active;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: on ? 22 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: on ? Colors.white : const Color(0xFF3D59C4),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Your TV, our priority',
                      style: TextStyle(color: Color(0xFFC9D3F7), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final h = s.height;
    final w = s.width;
    final back = Path()
      ..moveTo(-40, h * 0.83)
      ..cubicTo(w * 0.23, h * 0.73, w * 0.67, h * 0.76, w + 40, h * 0.66)
      ..lineTo(w + 40, h)
      ..lineTo(-40, h)
      ..close();
    final front = Path()
      ..moveTo(-40, h * 0.9)
      ..cubicTo(w * 0.3, h * 0.83, w * 0.72, h * 0.85, w + 40, h * 0.77)
      ..lineTo(w + 40, h)
      ..lineTo(-40, h)
      ..close();
    canvas.drawPath(back, Paint()..color = AppColors.navy);
    canvas.drawPath(front, Paint()..color = AppColors.navy3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
