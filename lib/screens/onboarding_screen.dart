import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../data/catalog.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/paypoint_logo.dart';

class _Slide {
  const _Slide(this.title, this.body, this.panel);
  final String title;
  final String body;
  final Color panel;
}

const _light = Color(0xFFEEF2FF);

const _slides = [
  _Slide(
    'All your cable TV,\nin one place',
    'Renew DStv, GOtv and StarTimes subscriptions without switching apps or queueing at a shop.',
    _light,
  ),
  _Slide(
    'Back to your shows,\ninstantly',
    'Your decoder reactivates the moment payment clears, so you never miss the match or the finale.',
    Color(0xFFE9F0FF),
  ),
  _Slide(
    'Safe payments,\nevery single time',
    'Pay with your wallet, card or bank. Every transaction is protected and confirmed with your PIN.',
    AppColors.navy,
  ),
];

/// Three-page onboarding with parallax illustrations, a background that
/// blends continuously between slides, and a progress-ring Next button.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  double _pos = 0;

  int get _page => _pos.round();

  @override
  void initState() {
    super.initState();
    _pc.addListener(() {
      if (_pc.hasClients && _pc.position.haveDimensions) setState(() => _pos = _pc.page ?? 0);
    });
  }

  void _finish() => Navigator.of(context).pushReplacementNamed(Routes.signUp);

  void _next() {
    if (_page == _slides.length - 1) return _finish();
    _pc.nextPage(duration: const Duration(milliseconds: 520), curve: Curves.easeOutCubic);
  }

  void _back() => _pc.previousPage(duration: const Duration(milliseconds: 520), curve: Curves.easeOutCubic);

  Color get _panelColor {
    final i = _pos.floor().clamp(0, _slides.length - 1);
    final j = (i + 1).clamp(0, _slides.length - 1);
    return Color.lerp(_slides[i].panel, _slides[j].panel, _pos - i)!;
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final panelH = size.height * 0.56;
    final darkness = (_pos - 1).clamp(0.0, 1.0);
    final dark = darkness > 0.5;
    final top = MediaQuery.paddingOf(context).top;
    final last = _page == _slides.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Blending panel + decorative rings.
            Container(
              height: panelH,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: _panelColor,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(48)),
              ),
              child: Stack(
                children: [
                  if (darkness > 0)
                    Positioned.fill(
                      child: Opacity(
                        opacity: darkness,
                        child: const AuroraBackground(base: AppColors.navy, intensity: 0.45),
                      ),
                    ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: RingsPainter(
                        center: Offset(size.width / 2, panelH * 0.52),
                        radii: [size.width * 0.38, size.width * 0.56, size.width * 0.76],
                        color: Color.lerp(AppColors.blue, AppColors.electric, darkness)!,
                        opacities: [0.14 + darkness * 0.2, 0.09 + darkness * 0.12, 0.05 + darkness * 0.08],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PageView.builder(
              controller: _pc,
              itemCount: _slides.length,
              itemBuilder: (_, i) => _SlideView(
                slide: _slides[i],
                index: i,
                delta: i - _pos,
                panelH: panelH,
                topInset: top,
              ),
            ),
            Positioned(
              top: top + 12,
              left: 24,
              right: 24,
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: _page == 0
                        ? const PaypointLockup(key: ValueKey('logo'))
                        : BackRoundButton(key: ValueKey('back$dark'), onDark: dark, onPressed: _back),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: dark ? const Color(0xFFD6DFFF) : AppColors.label,
                      minimumSize: const Size(48, 44),
                    ),
                    child: const Text('Skip', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 28,
              right: 28,
              bottom: MediaQuery.paddingOf(context).bottom + 28,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                switchInCurve: Curves.easeOutBack,
                transitionBuilder: (c, a) => FadeTransition(
                  opacity: a,
                  child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(a), child: c),
                ),
                child: last
                    ? Column(
                        key: const ValueKey('last'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Dots(pos: _pos, center: true),
                          const SizedBox(height: 18),
                          PrimaryButton(
                            label: 'Get started',
                            trailingIcon: Icons.arrow_forward_rounded,
                            shimmer: true,
                            onPressed: _finish,
                          ),
                        ],
                      )
                    : Row(
                        key: const ValueKey('next'),
                        children: [
                          _Dots(pos: _pos),
                          const Spacer(),
                          _NextRing(progress: (_pos + 1) / _slides.length, onTap: _next),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dots that stretch and fill continuously with the swipe position.
class _Dots extends StatelessWidget {
  const _Dots({required this.pos, this.center = false});
  final double pos;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page ${pos.round() + 1} of ${_slides.length}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: List.generate(_slides.length, (i) {
          final t = (1 - (pos - i).abs()).clamp(0.0, 1.0);
          return Container(
            margin: const EdgeInsets.only(right: 6),
            width: 6 + 22 * t,
            height: 6,
            decoration: BoxDecoration(
              gradient: t > 0.05
                  ? LinearGradient(colors: [
                      Color.lerp(const Color(0xFFC9D3F2), AppColors.bright, t)!,
                      Color.lerp(const Color(0xFFC9D3F2), AppColors.blue, t)!,
                    ])
                  : null,
              color: t > 0.05 ? null : const Color(0xFFC9D3F2),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}

/// Round gradient Next button wrapped in a progress arc.
class _NextRing extends StatelessWidget {
  const _NextRing({required this.progress, required this.onTap});
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => CustomPaint(size: const Size.square(76), painter: _ArcPainter(v)),
          ),
          PressScale(
            scale: 0.9,
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.primary,
                boxShadow: AppShadows.button,
              ),
              child: Material(
                type: MaterialType.transparency,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap();
                  },
                  child: const Center(
                    child: Icon(Icons.arrow_forward_rounded, color: Colors.white, semanticLabel: 'Next'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter(this.v);
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(2);
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFDCE3F5),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * v,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [AppColors.bright, AppColors.blue, AppColors.bright],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) => old.v != v;
}

class _SlideView extends StatelessWidget {
  const _SlideView({
    required this.slide,
    required this.index,
    required this.delta,
    required this.panelH,
    required this.topInset,
  });

  final _Slide slide;
  final int index;

  /// Distance from the centred page: 0 = on screen, ±1 = one page away.
  final double delta;
  final double panelH;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final illoTop = topInset + 80;
    final d = delta.clamp(-1.0, 1.0);
    final away = d.abs();

    return Stack(
      children: [
        // Illustration moves slower than the page (parallax) and recedes.
        Positioned(
          top: illoTop,
          left: 40,
          right: 40,
          height: (panelH - illoTop - 28).clamp(180.0, 420.0),
          child: Transform.translate(
            offset: Offset(d * 140, 0),
            child: Transform.scale(
              scale: 1 - away * 0.12,
              child: Opacity(
                opacity: (1 - away * 0.8).clamp(0.0, 1.0),
                child: switch (index) {
                  0 => const _ProvidersIllustration(),
                  1 => const _InstantIllustration(),
                  _ => const _SecureIllustration(),
                },
              ),
            ),
          ),
        ),
        // Copy trails a little behind for depth.
        Positioned(
          top: panelH + 40,
          left: 28,
          right: 28,
          child: Transform.translate(
            offset: Offset(d * 60, 0),
            child: Opacity(
              opacity: (1 - away * 1.6).clamp(0.0, 1.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slide.title,
                    style: const TextStyle(fontSize: 31, height: 1.12, fontWeight: FontWeight.w800, letterSpacing: -1),
                  ),
                  const SizedBox(height: 14),
                  Text(slide.body, style: const TextStyle(fontSize: 15, height: 1.6, color: AppColors.body)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------- illustrations (pure Flutter shapes) ----------------

class _TvFrame extends StatelessWidget {
  const _TvFrame({required this.child, required this.width, this.height = 180});
  final Widget child;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A2B70), AppColors.navy],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: const [BoxShadow(color: Color(0x4D0B1A55), blurRadius: 50, offset: Offset(0, 26))],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(14), child: child),
      );
}

class _ProvidersIllustration extends StatelessWidget {
  const _ProvidersIllustration();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 30,
            child: Floating(
              amplitude: 4,
              child: _TvFrame(
                width: w - 60,
                child: ShimmerSweep(
                  opacity: 0.18,
                  child: Container(
                    decoration: const BoxDecoration(gradient: AppGradients.primary),
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.live_tv_rounded, color: Colors.white, size: 42),
                        SizedBox(height: 6),
                        Text('3 providers · 1 app',
                            style: TextStyle(color: Color(0xFFD6DFFF), fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            top: 150,
            child: Floating(
              phase: 0.2,
              child: ProviderBadge(provider: Catalog.dstv, width: 128, height: 56, fontSize: 22, radius: 18, glow: true),
            ),
          ),
          const Positioned(
            right: 0,
            top: 168,
            child: Floating(
              phase: 0.55,
              child: ProviderBadge(provider: Catalog.gotv, width: 128, height: 56, fontSize: 22, radius: 18, glow: true),
            ),
          ),
          Positioned(
            left: w / 2 - 79,
            top: 228,
            child: Floating(
              phase: 0.8,
              child: Container(
                width: 158,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [BoxShadow(color: Color(0x2E0B1A55), blurRadius: 30, offset: Offset(0, 14))],
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 5, backgroundColor: AppColors.orange),
                    SizedBox(width: 8),
                    Text('StarTimes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _InstantIllustration extends StatelessWidget {
  const _InstantIllustration();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 20,
            top: 10,
            child: _TvFrame(
              width: w - 40,
              height: 190,
              child: Container(
                decoration: const BoxDecoration(gradient: AppGradients.hero),
                padding: const EdgeInsets.all(16),
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        PulseDot(color: Color(0xFFFF5A5A), size: 6),
                        SizedBox(width: 4),
                        Text('LIVE',
                            style: TextStyle(
                                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.1, end: 0.68),
                        duration: const Duration(milliseconds: 1800),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v,
                          minHeight: 6,
                          color: AppColors.bright,
                          backgroundColor: const Color(0xFF24398F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(left: w / 2 - 9, top: 200, child: Container(width: 18, height: 26, color: AppColors.navy)),
          Positioned(
            left: w / 2 - 51,
            top: 224,
            child: Container(
              width: 102,
              height: 8,
              decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          Positioned(
            right: 0,
            top: -6,
            child: Floating(
              amplitude: 7,
              child: PulseRings(
                color: AppColors.amber,
                maxRadius: 64,
                rings: 2,
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: const BoxDecoration(
                    gradient: AppGradients.warm,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Color(0x73FFB020), blurRadius: 30, offset: Offset(0, 14))],
                  ),
                  child: const Icon(Icons.bolt_rounded, size: 42, color: AppColors.navy),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 214,
            child: Floating(
              phase: 0.4,
              amplitude: 5,
              child: Container(
                height: 62,
                padding: const EdgeInsets.fromLTRB(10, 0, 18, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(31),
                  boxShadow: const [BoxShadow(color: Color(0x290B1A55), blurRadius: 30, offset: Offset(0, 14))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.success),
                      alignment: Alignment.center,
                      child: const DrawnCheck(size: 26, strokeWidth: 3.4, delay: Duration(milliseconds: 500)),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Activated', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                        Text('in seconds', style: TextStyle(fontSize: 11, color: AppColors.body)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _SecureIllustration extends StatelessWidget {
  const _SecureIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Center(
          child: PulseRings(
            color: AppColors.electric,
            maxRadius: 170,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.primary,
                border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 2),
                boxShadow: const [BoxShadow(color: Color(0x803B6CFF), blurRadius: 50, offset: Offset(0, 18))],
              ),
              child: const Icon(Icons.verified_user_rounded, size: 76, color: Colors.white),
            ),
          ),
        ),
        const Positioned(
          right: -10,
          top: 0,
          child: Floating(child: _FeatureChip(icon: Icons.credit_card_rounded, text: 'Encrypted card details')),
        ),
        const Positioned(
          left: -6,
          bottom: 0,
          child: Floating(phase: 0.5, child: _FeatureChip(icon: Icons.lock_outline_rounded, text: 'PIN on every payment')),
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Glass(
        radius: 18,
        tint: const Color(0x26FFFFFF),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: SizedBox(
          width: 132,
          child: Row(
            children: [
              Icon(icon, size: 22, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 12, height: 1.3, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
}
