import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Motion toolkit: small, dependency-free building blocks used across screens.
///
/// Every looping or entrance animation respects the system "reduce motion"
/// setting via [MediaQuery.disableAnimationsOf].

bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Stagger timing helper: `Stagger.at(i)` → delay for the i-th item.
class Stagger {
  Stagger._();
  static Duration at(int i, {int baseMs = 40, int stepMs = 70}) => Duration(milliseconds: baseMs + i * stepMs);
}

// ---------------------------------------------------------------------------
// Entrances
// ---------------------------------------------------------------------------

/// Fades and slides its child in once, after an optional [delay].
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 560),
    this.offset = const Offset(0, 22),
    this.curve = Curves.easeOutCubic,
    this.scaleFrom = 1.0,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final Curve curve;
  final double scaleFrom;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: widget.curve);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (_, child) {
        final v = _a.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: widget.offset * (1 - v),
            child: widget.scaleFrom == 1.0
                ? child
                : Transform.scale(scale: widget.scaleFrom + (1 - widget.scaleFrom) * v, child: child),
          ),
        );
      },
    );
  }
}

/// Renders [text] with each character rising in, one after another.
class StaggeredText extends StatelessWidget {
  const StaggeredText(this.text, {super.key, required this.style, this.delay = Duration.zero, this.stepMs = 45});

  final String text;
  final TextStyle style;
  final Duration delay;
  final int stepMs;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < text.length; i++)
              FadeSlideIn(
                delay: delay + Duration(milliseconds: i * stepMs),
                duration: const Duration(milliseconds: 520),
                offset: const Offset(0, 18),
                curve: Curves.easeOutBack,
                child: Text(text[i], style: style),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Interaction
// ---------------------------------------------------------------------------

/// Shrinks its child slightly while a pointer is down. Uses a raw [Listener]
/// so it never competes with the child's own InkWell / gesture handling.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = 0.965, this.enabled = true});

  final Widget child;
  final double scale;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (!widget.enabled || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: Duration(milliseconds: _down ? 90 : 220),
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ambient loops
// ---------------------------------------------------------------------------

/// Gently bobs its child up and down.
class Floating extends StatefulWidget {
  const Floating({
    super.key,
    required this.child,
    this.amplitude = 6,
    this.period = const Duration(milliseconds: 3200),
    this.phase = 0,
  });

  final Widget child;
  final double amplitude;
  final Duration period;

  /// 0..1 offset so neighbours don't move in lockstep.
  final double phase;

  @override
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) {
        final dy = math.sin((_c.value + widget.phase) * 2 * math.pi) * widget.amplitude;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
    );
  }
}

/// A light band that sweeps diagonally across its child every [period].
class ShimmerSweep extends StatefulWidget {
  const ShimmerSweep({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 3600),
    this.opacity = 0.16,
    this.enabled = true,
  });

  final Widget child;
  final Duration period;
  final double opacity;
  final bool enabled;

  @override
  State<ShimmerSweep> createState() => _ShimmerSweepState();
}

class _ShimmerSweepState extends State<ShimmerSweep> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || reduceMotion(context)) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _SweepPainter(_c, widget.opacity)),
          ),
        ),
      ],
    );
  }
}

class _SweepPainter extends CustomPainter {
  _SweepPainter(this.anim, this.opacity) : super(repaint: anim);
  final Animation<double> anim;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    // Sweep during the first 45% of the cycle, then rest.
    final t = (anim.value / 0.45).clamp(0.0, 1.0);
    if (t <= 0 || t >= 1) return;
    final bandW = size.width * 0.45;
    final x = -bandW + (size.width + bandW * 2) * Curves.easeInOut.transform(t);
    final rect = Rect.fromLTWH(x - bandW / 2, -size.height, bandW, size.height * 3);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: opacity),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(0.35);
    canvas.translate(-size.width / 2, -size.height / 2);
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SweepPainter old) => old.opacity != opacity;
}

/// Soft, slowly drifting colour blobs: the "aurora" behind dark hero areas.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({
    super.key,
    this.base = AppColors.deep,
    this.colors = const [AppColors.blue, AppColors.bright, Color(0xFF2B1F8F)],
    this.child,
    this.intensity = 0.55,
    this.period = const Duration(seconds: 16),
  });

  final Color base;
  final List<Color> colors;
  final Widget? child;
  final double intensity;
  final Duration period;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = reduceMotion(context);
    return CustomPaint(
      painter: _AuroraPainter(
        still ? const AlwaysStoppedAnimation(0.2) : _c,
        widget.base,
        widget.colors,
        widget.intensity,
      ),
      child: widget.child,
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.anim, this.base, this.colors, this.intensity) : super(repaint: anim);
  final Animation<double> anim;
  final Color base;
  final List<Color> colors;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final t = anim.value * 2 * math.pi;
    final w = size.width;
    final h = size.height;
    final r = math.max(w, h) * 0.55;
    final centers = [
      Offset(w * (0.2 + 0.12 * math.sin(t)), h * (0.22 + 0.08 * math.cos(t * 1.3))),
      Offset(w * (0.85 + 0.1 * math.cos(t * 0.8)), h * (0.45 + 0.1 * math.sin(t * 1.1))),
      Offset(w * (0.4 + 0.15 * math.sin(t * 0.7 + 1)), h * (0.85 + 0.06 * math.cos(t))),
    ];
    for (var i = 0; i < centers.length; i++) {
      final c = colors[i % colors.length];
      final rect = Rect.fromCircle(center: centers[i], radius: r);
      canvas.drawCircle(
        centers[i],
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [c.withValues(alpha: intensity), c.withValues(alpha: 0)],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) => old.base != base || old.intensity != intensity;
}

/// Rings that expand and fade outward from the centre, on a loop.
class PulseRings extends StatefulWidget {
  const PulseRings({
    super.key,
    required this.child,
    this.color = AppColors.bright,
    this.maxRadius = 120,
    this.rings = 3,
    this.period = const Duration(milliseconds: 2800),
  });

  final Widget child;
  final Color color;
  final double maxRadius;
  final int rings;
  final Duration period;

  @override
  State<PulseRings> createState() => _PulseRingsState();
}

class _PulseRingsState extends State<PulseRings> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    return CustomPaint(
      painter: _PulsePainter(_c, widget.color, widget.maxRadius, widget.rings),
      child: widget.child,
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter(this.anim, this.color, this.maxRadius, this.rings) : super(repaint: anim);
  final Animation<double> anim;
  final Color color;
  final double maxRadius;
  final int rings;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final minR = size.shortestSide / 2;
    for (var i = 0; i < rings; i++) {
      final t = (anim.value + i / rings) % 1.0;
      final radius = minR + (maxRadius - minR) * Curves.easeOut.transform(t);
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = color.withValues(alpha: (1 - t) * 0.45),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PulsePainter old) => false;
}

/// A small dot that softly pulses (live / attention indicator).
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, this.color = AppColors.orange, this.size = 8});
  final Color color;
  final double size;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 2.4,
      height: s * 2.4,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = reduceMotion(context) ? 0.0 : _c.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: s + s * 1.4 * t,
                height: s + s * 1.4 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.4 * (1 - t)),
                ),
              ),
              Container(
                width: s,
                height: s,
                decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Values
// ---------------------------------------------------------------------------

/// Counts smoothly from 0 (first build) and between later values.
class AnimatedAmount extends StatelessWidget {
  const AnimatedAmount({
    super.key,
    required this.value,
    required this.format,
    required this.style,
    this.duration = const Duration(milliseconds: 1100),
    this.from = 0,
    this.textAlign,
  });

  final double value;
  final String Function(double v) format;
  final TextStyle style;
  final Duration duration;
  final double from;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return Text(format(value), style: style, textAlign: textAlign);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: from, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(
        format(v),
        style: style.copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()]),
        textAlign: textAlign,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Surfaces
// ---------------------------------------------------------------------------

/// Frosted glass panel.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 20,
    this.blur = 18,
    this.tint = const Color(0x1FFFFFFF),
    this.borderColor = const Color(0x33FFFFFF),
    this.padding,
  });

  final Widget child;
  final double radius;
  final double blur;
  final Color tint;
  final Color borderColor;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Animated check mark that draws itself from left to right.
class DrawnCheck extends StatefulWidget {
  const DrawnCheck({
    super.key,
    this.size = 54,
    this.color = Colors.white,
    this.strokeWidth = 6,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
  });

  final double size;
  final Color color;
  final double strokeWidth;
  final Duration delay;
  final Duration duration;

  @override
  State<DrawnCheck> createState() => _DrawnCheckState();
}

class _DrawnCheckState extends State<DrawnCheck> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(widget.size),
      painter: _CheckPainter(
        reduceMotion(context) ? const AlwaysStoppedAnimation(1.0) : _curve,
        widget.color,
        widget.strokeWidth,
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.anim, this.color, this.stroke) : super(repaint: anim);
  final Animation<double> anim;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final path = Path()
      ..moveTo(s * 0.2, s * 0.53)
      ..lineTo(s * 0.42, s * 0.74)
      ..lineTo(s * 0.8, s * 0.3);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(extractPathFraction(path, anim.value), paint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) => old.color != color;
}

/// Returns the first [fraction] (0..1) of [path], measured by length.
Path extractPathFraction(Path path, double fraction) {
  final out = Path();
  final metrics = path.computeMetrics().toList();
  final total = metrics.fold<double>(0, (s, m) => s + m.length);
  var remaining = total * fraction.clamp(0.0, 1.0);
  for (final m in metrics) {
    if (remaining <= 0) break;
    final take = math.min(remaining, m.length);
    out.addPath(m.extractPath(0, take), Offset.zero);
    remaining -= take;
  }
  return out;
}

// ---------------------------------------------------------------------------
// Celebration
// ---------------------------------------------------------------------------

/// One-shot confetti burst from the centre of its box.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.count = 70, this.delay = const Duration(milliseconds: 250)});
  final int count;
  final Duration delay;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _Particle {
  _Particle(math.Random r)
      : angle = r.nextDouble() * 2 * math.pi,
        speed = 260 + r.nextDouble() * 420,
        spin = (r.nextDouble() - 0.5) * 14,
        size = 5 + r.nextDouble() * 6,
        color = _palette[r.nextInt(_palette.length)],
        isRect = r.nextBool(),
        drift = (r.nextDouble() - 0.5) * 60;

  static const _palette = [
    AppColors.bright,
    AppColors.blue,
    AppColors.amber,
    AppColors.successStrong,
    AppColors.orange,
    Color(0xFF8FB0FF),
  ];

  final double angle;
  final double speed;
  final double spin;
  final double size;
  final Color color;
  final bool isRect;
  final double drift;
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  late final List<_Particle> _ps;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final r = math.Random();
    _ps = List.generate(widget.count, (_) => _Particle(r));
    _timer = Timer(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return const SizedBox.expand();
    return IgnorePointer(child: CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_c, _ps)));
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.anim, this.ps) : super(repaint: anim);
  final Animation<double> anim;
  final List<_Particle> ps;

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    if (t == 0) return;
    final secs = t * 2.6;
    final origin = size.center(Offset.zero);
    const gravity = 520.0;
    final fade = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);
    for (final p in ps) {
      // Exponential drag so pieces burst out fast then float down.
      final dragged = (1 - math.exp(-secs * 3.2)) / 3.2;
      final x = origin.dx + math.cos(p.angle) * p.speed * dragged + p.drift * secs;
      final y = origin.dy + math.sin(p.angle) * p.speed * dragged + 0.5 * gravity * secs * secs * 0.35;
      final paint = Paint()..color = p.color.withValues(alpha: fade.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * secs);
      if (p.isRect) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55),
              const Radius.circular(1.5)),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.size * 0.38, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => false;
}

// ---------------------------------------------------------------------------
// Segmented control with a sliding indicator
// ---------------------------------------------------------------------------

/// Pill-shaped segmented control whose highlight glides between options.
class SlidingSegments extends StatelessWidget {
  const SlidingSegments({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.height = 48,
    this.indicatorColors,
    this.background = const Color(0xFFE6EAF3),
    this.selectedText = AppColors.ink,
    this.unselectedText = AppColors.body,
    this.italic,
    this.fontSize = 13,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final double height;

  /// Per-option indicator colour; null = white pill with soft shadow.
  final List<Color>? indicatorColors;
  final Color background;
  final Color selectedText;
  final Color unselectedText;
  final List<bool>? italic;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final n = labels.length;
    final colored = indicatorColors != null;
    final pillColor = colored ? indicatorColors![index] : Colors.white;
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(height / 2.6)),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: Alignment(n == 1 ? 0 : -1 + 2 * index / (n - 1), 0),
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutBack,
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: colored ? AppGradients.of(pillColor) : null,
                  color: colored ? null : Colors.white,
                  borderRadius: BorderRadius.circular((height - 8) / 2.6),
                  boxShadow: [
                    BoxShadow(
                      color: colored ? pillColor.withValues(alpha: 0.35) : const Color(0x170B1A55),
                      blurRadius: colored ? 16 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: Semantics(
                    selected: i == index,
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(i),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          style: DefaultTextStyle.of(context).style.copyWith(
                            fontSize: fontSize,
                            fontWeight: i == index ? FontWeight.w800 : FontWeight.w600,
                            fontStyle: (italic?[i] ?? false) ? FontStyle.italic : FontStyle.normal,
                            color: i == index ? (colored ? Colors.white : selectedText) : unselectedText,
                          ),
                          child: Text(labels[i], maxLines: 1, overflow: TextOverflow.fade, softWrap: false),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
