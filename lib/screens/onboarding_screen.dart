import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../data/catalog.dart';
import '../widgets/common.dart';
import '../widgets/paypoint_logo.dart';

class _Slide {
  const _Slide(this.title, this.body, this.dark);
  final String title;
  final String body;
  final bool dark;
}

const _slides = [
  _Slide(
    'All your cable TV,\nin one place',
    'Renew DStv, GOtv and StarTimes subscriptions without switching apps or queueing at a shop.',
    false,
  ),
  _Slide(
    'Back to your shows,\ninstantly',
    'Your decoder reactivates the moment payment clears, so you never miss the match or the finale.',
    false,
  ),
  _Slide(
    'Safe payments,\nevery single time',
    'Pay with your wallet, card or bank. Every transaction is protected and confirmed with your PIN.',
    true,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _page = 0;

  void _finish() => Navigator.of(context).pushReplacementNamed(Routes.signUp);

  void _next() {
    if (_page == _slides.length - 1) return _finish();
    _pc.nextPage(duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
  }

  void _back() => _pc.previousPage(duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final panelH = h * 0.56;
    final dark = _slides[_page].dark;
    final top = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 380),
              height: panelH,
              decoration: BoxDecoration(
                color: dark ? AppColors.navy : const Color(0xFFEEF2FF),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(44)),
              ),
            ),
            PageView.builder(
              controller: _pc,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => _SlideView(
                slide: _slides[i],
                index: i,
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
                  if (_page == 0)
                    const PaypointLockup()
                  else
                    BackRoundButton(onDark: dark, onPressed: _back),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: dark ? const Color(0xFFD6DFFF) : AppColors.label,
                      minimumSize: const Size(48, 44),
                    ),
                    child: const Text('Skip', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 28,
              right: 28,
              bottom: MediaQuery.paddingOf(context).bottom + 32,
              child: _page == _slides.length - 1
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Dots(page: _page, center: true),
                        const SizedBox(height: 18),
                        PrimaryButton(label: 'Get started', onPressed: _finish),
                      ],
                    )
                  : Row(
                      children: [
                        _Dots(page: _page),
                        const Spacer(),
                        PrimaryButton(
                          label: 'Next',
                          trailingIcon: Icons.arrow_forward_rounded,
                          expand: false,
                          onPressed: _next,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.page, this.center = false});
  final int page;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page ${page + 1} of ${_slides.length}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: List.generate(_slides.length, (i) {
          final on = i == page;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            margin: const EdgeInsets.only(right: 6),
            width: on ? 24 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: on ? AppColors.blue : const Color(0xFFC9D3F2),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.index, required this.panelH, required this.topInset});
  final _Slide slide;
  final int index;
  final double panelH;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final illoTop = topInset + 76;
    return Stack(
      children: [
        Positioned(
          top: illoTop,
          left: 40,
          right: 40,
          height: (panelH - illoTop - 24).clamp(180.0, 420.0),
          child: switch (index) {
            0 => const _ProvidersIllustration(),
            1 => const _InstantIllustration(),
            _ => const _SecureIllustration(),
          },
        ),
        Positioned(
          top: panelH + 44,
          left: 28,
          right: 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slide.title,
                style: const TextStyle(fontSize: 30, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -0.8),
              ),
              const SizedBox(height: 14),
              Text(slide.body, style: const TextStyle(fontSize: 15, height: 1.55, color: AppColors.body)),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------- illustrations (pure Flutter shapes) ----------------

class _TvFrame extends StatelessWidget {
  const _TvFrame({required this.child, this.width = 250, this.height = 180});
  final Widget child;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x400B1A55), blurRadius: 50, offset: Offset(0, 24))],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
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
            right: 30,
            child: _TvFrame(
              width: w - 60,
              child: Container(
                color: AppColors.blue,
                alignment: Alignment.center,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tv_rounded, color: Colors.white, size: 40),
                    SizedBox(height: 6),
                    Text('3 providers · 1 app',
                        style: TextStyle(color: Color(0xFFD6DFFF), fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            top: 150,
            child: _FloatBadge(child: ProviderBadge(provider: Catalog.dstv, width: 128, height: 56, fontSize: 22, radius: 16)),
          ),
          const Positioned(
            right: 0,
            top: 168,
            child: _FloatBadge(child: ProviderBadge(provider: Catalog.gotv, width: 128, height: 56, fontSize: 22, radius: 16)),
          ),
          Positioned(
            left: w / 2 - 79,
            top: 226,
            child: Container(
              width: 158,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
        ],
      );
    });
  }
}

class _FloatBadge extends StatelessWidget {
  const _FloatBadge({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x400B1A55), blurRadius: 30, offset: Offset(0, 14))],
        ),
        child: child,
      );
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
                color: AppColors.navy3,
                padding: const EdgeInsets.all(16),
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NOW SHOWING',
                        style: TextStyle(color: AppColors.onNavyFaint, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: const LinearProgressIndicator(
                        value: 0.62,
                        minHeight: 6,
                        color: AppColors.bright,
                        backgroundColor: Color(0xFF24398F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: w / 2 - 9,
            top: 200,
            child: Container(width: 18, height: 26, color: AppColors.navy),
          ),
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
            top: 0,
            child: Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: AppColors.amber,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x73FFB020), blurRadius: 30, offset: Offset(0, 14))],
              ),
              child: const Icon(Icons.bolt_rounded, size: 40, color: AppColors.navy),
            ),
          ),
          Positioned(
            left: 0,
            top: 214,
            child: Container(
              height: 60,
              padding: const EdgeInsets.fromLTRB(10, 0, 18, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Color(0x290B1A55), blurRadius: 30, offset: Offset(0, 14))],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.successBg,
                    child: Icon(Icons.check_rounded, color: AppColors.success, size: 22),
                  ),
                  SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Activated', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      Text('in seconds', style: TextStyle(fontSize: 11, color: AppColors.body)),
                    ],
                  ),
                ],
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
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final ch = c.maxHeight;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: RingsPainter(center: Offset(w / 2, ch / 2), radii: const [110, 165], opacities: const [0.35, 0.18]),
            ),
          ),
          const Center(child: Icon(Icons.verified_user_rounded, size: 150, color: AppColors.blue)),
          const Positioned(right: -10, top: 0, child: _FeatureChip(icon: Icons.credit_card_rounded, text: 'Encrypted card details')),
          const Positioned(left: -6, bottom: 0, child: _FeatureChip(icon: Icons.lock_outline_rounded, text: 'PIN on every payment')),
        ],
      );
    });
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        width: 156,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 30, offset: Offset(0, 14))],
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: const TextStyle(fontSize: 12, height: 1.3, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}
