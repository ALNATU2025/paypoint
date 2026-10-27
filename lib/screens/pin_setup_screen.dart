import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

enum _Step { current, create, confirm }

/// Create (after sign-up) or change (from Profile) the 4-digit transaction PIN.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key, this.change = false});

  final bool change;

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  static const _len = 4;
  final _code = TextEditingController();
  final _focus = FocusNode();
  late _Step _step = widget.change ? _Step.current : _Step.create;
  String _current = '';
  String _first = '';
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _title => switch (_step) {
        _Step.current => 'Enter current PIN',
        _Step.create => widget.change ? 'Choose a new PIN' : 'Create your PIN',
        _Step.confirm => 'Confirm your PIN',
      };

  String get _subtitle => switch (_step) {
        _Step.current => 'Enter the 4-digit PIN you use to approve payments.',
        _Step.create => 'You will use this 4-digit PIN to approve every payment. Avoid 1234 or your birth year.',
        _Step.confirm => 'Enter the same 4 digits again.',
      };

  Future<void> _onComplete(String v) async {
    switch (_step) {
      case _Step.current:
        _current = v;
        _next(_Step.create);
      case _Step.create:
        if (RegExp(r'^(\d)\1{3}$').hasMatch(v) || v == '1234' || v == '4321') {
          _fail('That PIN is too easy to guess. Choose another.');
          return;
        }
        _first = v;
        _next(_Step.confirm);
      case _Step.confirm:
        if (v != _first) {
          _first = '';
          _fail("PINs didn't match. Let's start again.", back: _Step.create);
          return;
        }
        await _save(v);
    }
  }

  void _next(_Step s) {
    setState(() {
      _step = s;
      _error = null;
    });
    _code.clear();
  }

  void _fail(String msg, {_Step? back}) {
    HapticFeedback.heavyImpact();
    setState(() {
      _error = msg;
      if (back != null) _step = back;
    });
    _code.clear();
  }

  Future<void> _save(String pin) async {
    setState(() => _saving = true);
    try {
      await AppScope.read(context).setPin(pin, currentPin: widget.change ? _current : null);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      if (widget.change) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction PIN updated')));
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(Routes.main, (_) => false);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _fail(e.message, back: widget.change ? _Step.current : _Step.create);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _code.text;

    return PopScope(
      canPop: widget.change,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.change) const BackRoundButton() else const SizedBox(height: 44),
                const SizedBox(height: 14),
                const FadeSlideIn(
                  scaleFrom: 0.6,
                  curve: Curves.easeOutBack,
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: PulseRings(
                      maxRadius: 62,
                      rings: 2,
                      child: IconTile(icon: Icons.lock_rounded, size: 64, radius: 22, iconSize: 30, active: true),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (c, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(a),
                      child: c,
                    ),
                  ),
                  child: Column(
                    key: ValueKey(_step),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                      const SizedBox(height: 8),
                      Text(_subtitle, style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.body)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () => _focus.requestFocus(),
                  child: Stack(
                    children: [
                      Row(
                        children: List.generate(_len, (i) {
                          final filled = i < text.length;
                          final active = i == text.length && _focus.hasFocus;
                          return Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              height: 64,
                              margin: EdgeInsets.only(right: i == _len - 1 ? 0 : 12),
                              decoration: BoxDecoration(
                                color: filled ? const Color(0xFFF7F9FF) : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: _error != null
                                      ? AppColors.danger
                                      : active
                                          ? AppColors.blue
                                          : filled
                                              ? const Color(0xFFB9C8F5)
                                              : AppColors.border,
                                  width: active ? 1.8 : 1.5,
                                ),
                                boxShadow: active
                                    ? const [BoxShadow(color: Color(0x1F1840C8), spreadRadius: 4)]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: filled
                                  ? FadeSlideIn(
                                      key: ValueKey('p$i${_step.name}'),
                                      duration: const Duration(milliseconds: 280),
                                      offset: Offset.zero,
                                      scaleFrom: 0.2,
                                      curve: Curves.easeOutBack,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: AppGradients.selectedBorder,
                                        ),
                                      ),
                                    )
                                  : active
                                      ? Container(width: 2, height: 26, color: AppColors.blue)
                                      : null,
                            ),
                          );
                        }),
                      ),
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0,
                          child: TextField(
                            controller: _code,
                            focusNode: _focus,
                            autofocus: true,
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(_len),
                            ],
                            showCursor: false,
                            enableInteractiveSelection: false,
                            enabled: !_saving,
                            onChanged: (v) {
                              if (_error != null) setState(() => _error = null);
                              if (v.length == _len) _onComplete(v);
                            },
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _error == null
                      ? const SizedBox(height: 20)
                      : Row(
                          key: ValueKey(_error),
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.danger),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                ),
                const Spacer(),
                PrimaryButton(
                  label: _step == _Step.confirm ? 'Save PIN' : 'Continue',
                  loading: _saving,
                  shimmer: text.length == _len,
                  onPressed: text.length == _len && !_saving ? () => _onComplete(text) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
