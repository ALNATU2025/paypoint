import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  static const _len = 6;
  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _seconds = 60;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _code.addListener(() => setState(() {}));
    _focus.addListener(() => setState(() {}));
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 1) t.cancel();
      if (mounted) setState(() => _seconds = (_seconds - 1).clamp(0, 60));
    });
  }

  Future<void> _verify() async {
    if (_code.text.length < _len) return;
    setState(() => _verifying = true);
    await Future<void>.delayed(const Duration(milliseconds: 800)); // call your OTP API here
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.main, (_) => false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final text = _code.text;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackRoundButton(),
              const SizedBox(height: 32),
              const IconTile(icon: Icons.smartphone_rounded, size: 64, radius: 20, iconSize: 30, bg: AppColors.sky),
              const SizedBox(height: 22),
              const Text('Verify your number',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'Enter the 6-digit code we sent to '),
                  TextSpan(
                    text: '${s.countryCode} ${s.phone}',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                ]),
                style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.body),
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
                            height: 60,
                            margin: EdgeInsets.only(right: i == _len - 1 ? 0 : 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: active ? AppColors.blue : AppColors.border, width: 1.5),
                              boxShadow: active
                                  ? const [BoxShadow(color: Color(0x1A1840C8), spreadRadius: 4)]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: filled
                                ? Text(text[i], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700))
                                : active
                                    ? Container(width: 2, height: 26, color: AppColors.blue)
                                    : null,
                          ),
                        );
                      }),
                    ),
                    // Invisible field that actually captures the code (supports paste + SMS autofill).
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0,
                        child: TextField(
                          controller: _code,
                          focusNode: _focus,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(_len),
                          ],
                          showCursor: false,
                          enableInteractiveSelection: false,
                          onChanged: (v) {
                            if (v.length == _len) _verify();
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
              const SizedBox(height: 22),
              Row(
                children: [
                  const Text("Didn't get it? ", style: TextStyle(fontSize: 14, color: AppColors.body)),
                  if (_seconds > 0)
                    Text('Resend in 00:${_seconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))
                  else
                    TextButton(
                      onPressed: _startTimer,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(44, 36)),
                      child: const Text('Resend code', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Verify & continue',
                loading: _verifying,
                onPressed: text.length == _len ? _verify : null,
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Change phone number', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
