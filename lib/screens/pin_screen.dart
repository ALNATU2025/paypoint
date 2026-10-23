import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formatters.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// Transaction PIN entry, presented as a sheet over a navy backdrop.
class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> with SingleTickerProviderStateMixin {
  static const _len = 4;
  String _pin = '';
  bool _busy = false;
  String? _error;

  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void dispose() {
    _shake.dispose();
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
    try {
      final tx = await AppScope.read(context).pay(_pin);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        Routes.success,
        ModalRoute.withName(Routes.main),
        arguments: tx,
      );
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _shake.forward(from: 0);
      setState(() {
        _busy = false;
        _pin = '';
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final d = s.draft;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1440),
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: BackRoundButton(onDark: true, close: true, onPressed: _busy ? () {} : null),
                    ),
                    const SizedBox(height: 20),
                    Text('Paying ${d.provider.name} ${d.package?.name ?? ''}',
                        style: const TextStyle(color: AppColors.onNavyFaint, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Text(Fmt.naira(d.total),
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(24, 14, 24, bottom + 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(color: const Color(0xFFD9DEEA), borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(height: 22),
                    const IconTile(icon: Icons.lock_outline_rounded, size: 56, radius: 18, iconSize: 26, bg: AppColors.sky),
                    const SizedBox(height: 16),
                    const Text('Enter your PIN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      _error ?? 'Enter your 4-digit transaction PIN',
                      style: TextStyle(fontSize: 14, color: _error != null ? AppColors.danger : AppColors.body),
                    ),
                    const SizedBox(height: 24),
                    AnimatedBuilder(
                      animation: _shake,
                      builder: (_, child) {
                        final t = _shake.value;
                        final dx = t == 0 ? 0.0 : 10 * (1 - t) * (((t * 10).floor().isEven) ? 1 : -1);
                        return Transform.translate(offset: Offset(dx, 0), child: child);
                      },
                      child: Semantics(
                        label: '${_pin.length} of $_len digits entered',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(_len, (i) {
                            final on = i < _pin.length;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              margin: const EdgeInsets.symmetric(horizontal: 9),
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: on ? AppColors.blue : Colors.transparent,
                                border: Border.all(color: on ? AppColors.blue : const Color(0xFFC3CADB), width: 2),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (_busy)
                      const SizedBox(
                        height: 260,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Processing payment…',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.body)),
                            ],
                          ),
                        ),
                      )
                    else
                      _Keypad(onKey: _press),
                    const SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }
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
      crossAxisSpacing: 18,
      childAspectRatio: 1.9,
      children: [
        for (final k in keys)
          if (k.isEmpty)
            const SizedBox.shrink()
          else
            Material(
              color: k == 'del' ? Colors.transparent : const Color(0xFFF3F5FA),
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onKey(k),
                child: Center(
                  child: k == 'del'
                      ? const Icon(Icons.backspace_outlined, color: AppColors.ink, semanticLabel: 'Delete')
                      : Text(k, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
      ],
    );
  }
}
