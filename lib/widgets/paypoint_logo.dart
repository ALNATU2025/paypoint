import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'motion.dart' show extractPathFraction;

/// The Paypoint "P" mark: a rounded P with a blue swoosh, drawn as vectors
/// on a 48×48 grid so it stays sharp at any size.
///
/// [progress] (0..1) draws the strokes on progressively — used by the splash.
class PaypointMark extends StatelessWidget {
  const PaypointMark({super.key, this.size = 48, this.onDark = false, this.progress = 1});

  final double size;

  /// White P for navy backgrounds.
  final bool onDark;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _MarkPainter(bowl: onDark ? Colors.white : AppColors.navy, progress: progress),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.bowl, required this.progress});
  final Color bowl;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);

    // The P draws over the first 70% of progress, the swoosh over the rest.
    final pT = (progress / 0.7).clamp(0.0, 1.0);
    final sT = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);

    final p = Path()
      ..moveTo(17, 40)
      ..lineTo(17, 9)
      ..lineTo(28, 9)
      ..arcToPoint(const Offset(28, 29), radius: const Radius.circular(10))
      ..lineTo(22, 29);
    canvas.drawPath(
      pT >= 1 ? p : extractPathFraction(p, pT),
      Paint()
        ..color = bowl
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (sT > 0) {
      final swoosh = Path()
        ..moveTo(5, 31)
        ..cubicTo(12, 31, 18, 28, 22, 23);
      canvas.drawPath(
        sT >= 1 ? swoosh : extractPathFraction(swoosh, sT),
        Paint()
          ..color = AppColors.bright
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) => old.bowl != bowl || old.progress != progress;
}

/// Mark + "Paypoint" wordmark in a row.
class PaypointLockup extends StatelessWidget {
  const PaypointLockup({super.key, this.markSize = 28, this.fontSize = 18, this.onDark = false});

  final double markSize;
  final double fontSize;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PaypointMark(size: markSize, onDark: onDark),
        const SizedBox(width: 8),
        Text(
          'Paypoint',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: onDark ? Colors.white : AppColors.navy,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

/// White rounded tile holding the mark (used on sign-up and splash).
class LogoTile extends StatelessWidget {
  const LogoTile({super.key, this.size = 48, this.radius = 14, this.glow = false, this.progress = 1});

  final double size;
  final double radius;
  final bool glow;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: glow
            ? const [
                BoxShadow(color: Color(0x803B6CFF), blurRadius: 60, offset: Offset(0, 24)),
                BoxShadow(color: Color(0x40FFFFFF), blurRadius: 2, spreadRadius: 1),
              ]
            : AppShadows.card,
      ),
      alignment: Alignment.center,
      child: PaypointMark(size: size * 0.62, progress: progress),
    );
  }
}

/// Concentric outline rings used as quiet decoration on navy surfaces.
class RingsPainter extends CustomPainter {
  RingsPainter({
    required this.center,
    required this.radii,
    this.color = AppColors.bright,
    this.opacities = const [0.35, 0.22, 0.14],
  });

  final Offset center;
  final List<double> radii;
  final Color color;
  final List<double> opacities;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < radii.length; i++) {
      final a = opacities[i.clamp(0, opacities.length - 1)];
      canvas.drawCircle(
        center,
        radii[i],
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = color.withValues(alpha: a),
      );
    }
  }

  @override
  bool shouldRepaint(covariant RingsPainter old) =>
      old.center != center || old.radii != radii || old.color != color;
}
