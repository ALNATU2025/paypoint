import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formatters.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

/// Transaction PIN entry: a sheet that springs up over the blurred payment
/// screen, with bouncing PIN dots, a shake on error and an animated
/// processing ring.
class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> with TickerProviderStateMixin {
  static const _len = 4;
  String _pin = '';
  bool _busy = false;
  String? _error;

  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 460));
  late final AnimationController _sheet =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 560))..forward();
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final Animation<double> _sheetAnim =
      CurvedAnimation(parent: _sheet, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);

  @override
  void dispose() {
    _shake.dispose();
    _sheet.dispose();
    _spin.dispose();
    super.dispose();
  }

  void _press(String k) {
    if (_busy) return;
    HapticFeedback.selectionClick();
    setState(() {
      _error = null;
      if (k == 'del') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else if (_pin.length < _len) {
        _pin += k;
      }
    });
    if (_pin.length == _len) _submit();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    _spin.repeat();
    final state = AppScope.read(context);
    try {
      final result = await state.pay(_pin);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pushNamedAndRemoveUntil(
        Routes.success,
        ModalRoute.withName(Routes.main),
        arguments: result.transaction,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _spin.stop();
      HapticFeedback.heavyImpact();
      if (e.code == 'PIN_NOT_SET') {
        Navigator.of(context).pushReplacementNamed(Routes.createPin);
        return;
      }
      // A failed payment comes back with the (refunded) transaction: show it.
      if (e.data is TvTransaction) {
        final tx = e.data! as TvTransaction;
        Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.success,
          ModalRoute.withName(Routes.main),
          arguments: tx,
        );
        return;
      }
      _shake.forward(from: 0);
      setState(() {
        _busy = false;
        _pin = '';
        _error = e.message;
      });
    }
  }

  Future<void> _close() async {
    if (_busy) return;
    await _sheet.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final d = s.draft;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final sheetAnim = _sheetAnim;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: !_busy,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Blur whatever is behind (the payment screen).
              Positioned.fill(
                child: GestureDetector(
                  onTap: _close,
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: const ColoredBox(color: Color(0x33071036)),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: FadeTransition(
                    opacity: sheetAnim,
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: BackRoundButton(onDark: true, close: true, onPressed: _close),
                        ),
                        const SizedBox(height: 18),
                        Text('Paying ${d.provider.name} ${d.package?.name ?? ''}',
                            style: const TextStyle(
                                color: AppColors.onNavyMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(Fmt.naira(d.total),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1)),
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(sheetAnim),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(24, 14, 24, bottom + 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
                      boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 40, offset: Offset(0, -10))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 5,
                          decoration:
                              BoxDecoration(color: const Color(0xFFD9DEEA), borderRadius: BorderRadius.circular(3)),
                        ),
                        const SizedBox(height: 20),
                        _LockBadge(spin: _spin, busy: _busy),
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          child: Text(
                            _busy ? 'Processing payment' : 'Enter your PIN',
                            key: ValueKey(_busy),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          child: Text(
                            _busy ? 'Hold on, this takes a moment…' : (_error ?? 'Enter your 4-digit transaction PIN'),
                            key: ValueKey('$_busy$_error'),
                            style: TextStyle(
                              fontSize: 14,
                              color: _error != null && !_busy ? AppColors.danger : AppColors.body,
                              fontWeight: _error != null ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        AnimatedBuilder(
                          animation: _shake,
                          builder: (_, child) {
                            final t = _shake.value;
                            final dx = math.sin(t * math.pi * 6) * 12 * (1 - t);
                            return Transform.translate(offset: Offset(dx, 0), child: child);
                          },
                          child: Semantics(
                            label: '${_pin.length} of $_len digits entered',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(_len, (i) => _PinDot(filled: i < _pin.length, error: _error != null)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 260),
                          opacity: _busy ? 0.35 : 1,
                          child: IgnorePointer(ignoring: _busy, child: _Keypad(onKey: _press)),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('PIN reset is available under Profile › Security & PIN.')),
                          ),
                          child: const Text('Forgot PIN?', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinDot extends StatelessWidget {
  const _PinDot({required this.filled, required this.error});
  final bool filled;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final border = error ? AppColors.danger : const Color(0xFFC3CADB);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 9),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: filled ? Colors.transparent : border, width: 2),
      ),
      child: AnimatedScale(
        scale: filled ? 1 : 0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.selectedBorder,
            boxShadow: [BoxShadow(color: Color(0x663B6CFF), blurRadius: 10, offset: Offset(0, 3))],
          ),
        ),
      ),
    );
  }
}

/// Lock icon with a gradient ring that spins while processing.
class _LockBadge extends StatelessWidget {
  const _LockBadge({required this.spin, required this.busy});
  final Animation<double> spin;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            opacity: busy ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            child: RotationTransition(
              turns: spin,
              child: CustomPaint(size: const Size.square(72), painter: _RingPainter()),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: IconTile(
              key: ValueKey(busy),
              icon: busy ? Icons.sync_lock_rounded : Icons.lock_rounded,
              size: 56,
              radius: 18,
              iconSize: 26,
              active: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 1.6,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [Color(0x003B6CFF), AppColors.bright, AppColors.blue],
          stops: [0, 0.6, 0.8],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onKey});
  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'del'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 16,
      childAspectRatio: 1.9,
      children: [
        for (final k in keys)
          if (k.isEmpty)
            const SizedBox.shrink()
          else
            PressScale(
              scale: 0.9,
              child: Material(
                color: k == 'del' ? Colors.transparent : const Color(0xFFF3F5FA),
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onKey(k),
                  splashColor: const Color(0x223B6CFF),
                  highlightColor: const Color(0x113B6CFF),
                  child: Center(
                    child: k == 'del'
                        ? const Icon(Icons.backspace_outlined, color: AppColors.ink, semanticLabel: 'Delete')
                        : Text(k, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
