import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key, required this.tx});
  final TvTransaction tx;

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _home() => Navigator.of(context).popUntil(ModalRoute.withName(Routes.main));

  @override
  Widget build(BuildContext context) {
    final tx = widget.tx;
    final pop = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    final fade = CurvedAnimation(parent: _c, curve: const Interval(0.3, 1, curve: Curves.easeOut));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _home();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Column(
              children: [
                SizedBox(
                  height: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(child: CustomPaint(painter: _CelebrationPainter(_c))),
                      ScaleTransition(
                        scale: pop,
                        child: Container(
                          width: 112,
                          height: 112,
                          decoration: const BoxDecoration(
                            color: AppColors.successStrong,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Color(0x591E9A3E), blurRadius: 40, offset: Offset(0, 20))],
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 58),
                        ),
                      ),
                    ],
                  ),
                ),
                FadeTransition(
                  opacity: fade,
                  child: Column(
                    children: [
                      const Text('Subscription successful!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                      const SizedBox(height: 8),
                      Text(
                        'Your ${tx.provider.name} ${tx.package.name} is now active. Enjoy every moment.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.body),
                      ),
                      const SizedBox(height: 26),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(22)),
                        child: Column(
                          children: [
                            InfoRow(label: 'Amount paid', value: Fmt.naira(tx.amount), padding: 13),
                            InfoRow(
                              label: tx.provider.idLabel.replaceAll(' number', ''),
                              value: Fmt.smartcard(tx.smartcard),
                              padding: 13,
                            ),
                            InfoRow(label: 'Active until', value: Fmt.date(tx.activeUntil), divider: false, padding: 13),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                PrimaryButton(
                  label: 'View receipt',
                  onPressed: () => Navigator.of(context).pushNamed(Routes.receipt, arguments: tx),
                ),
                const SizedBox(height: 12),
                PrimaryButton(label: 'Back to home', tone: ButtonTone.soft, onPressed: _home),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft rings and a few confetti pieces that drift in.
class _CelebrationPainter extends CustomPainter {
  _CelebrationPainter(this.anim) : super(repaint: anim);
  final Animation<double> anim;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final t = Curves.easeOut.transform(anim.value);
    canvas.drawCircle(c, 96 * t, Paint()..color = AppColors.successBg);
    canvas.drawCircle(
        c,
        140 * t,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xFFC6EBD1));
    canvas.drawCircle(
        c,
        190 * t,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = AppColors.successBg);

    final bits = <(Offset, Color, bool)>[
      (const Offset(-120, -95), AppColors.bright, true),
      (const Offset(120, -70), AppColors.amber, true),
      (const Offset(105, 80), AppColors.blue, false),
      (const Offset(-107, 70), AppColors.amber, false),
      (const Offset(59, -134), AppColors.successStrong, true),
      (const Offset(-40, 125), AppColors.bright, false),
    ];
    for (final (o, color, square) in bits) {
      final p = c + o * t;
      final paint = Paint()..color = color.withAlpha((255 * t).round());
      if (square) {
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(0.4 * t);
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(-5, -5, 10, 10), const Radius.circular(2)),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(p, 5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter old) => false;
}
