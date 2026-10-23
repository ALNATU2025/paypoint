import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/paypoint_logo.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 600)); // send OTP here
    if (!mounted) return;
    AppScope.read(context).setAccount(name: _name.text, phone: _phone.text, email: _email.text);
    setState(() => _submitting = false);
    Navigator.of(context).pushNamed(Routes.verify);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned(top: -140, right: -120, child: _Glow(size: 360, color: Color(0x2E3B6CFF))),
          const Positioned(top: 120, left: -160, child: _Glow(size: 300, color: Color(0x1A1840C8))),
          SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              sliver: SliverFillRemaining(
                hasScrollBody: false,
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeSlideIn(
                        delay: Stagger.at(0),
                        child: const Row(
                          children: [
                            LogoTile(),
                            SizedBox(width: 10),
                            Text('Paypoint',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),
                      FadeSlideIn(
                        delay: Stagger.at(1),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Create your account',
                                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.9)),
                            SizedBox(height: 8),
                            Text(
                              "It takes less than a minute. We'll send a code to verify your number.",
                              style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.body),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      FadeSlideIn(delay: Stagger.at(2), child: const _FieldLabel('Full name')),
                      FadeSlideIn(
                        delay: Stagger.at(2),
                        child: TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        style: _inputStyle,
                        decoration: const InputDecoration(hintText: 'e.g. Ada Okafor'),
                        validator: (v) => (v == null || v.trim().length < 3) ? 'Enter your full name' : null,
                      )),
                      const SizedBox(height: 18),
                      FadeSlideIn(delay: Stagger.at(3), child: const _FieldLabel('Phone number')),
                      FadeSlideIn(
                        delay: Stagger.at(3),
                        child: TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.telephoneNumberNational],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        style: _inputStyle,
                        decoration: const InputDecoration(
                          hintText: '803 456 7890',
                          prefixIcon: _CountryPrefix(),
                          prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                        ),
                        validator: (v) => (v == null || v.length < 10) ? 'Enter a valid phone number' : null,
                      )),
                      const SizedBox(height: 18),
                      FadeSlideIn(delay: Stagger.at(4), child: const _FieldLabel('Email', hint: '(optional, for receipts)')),
                      FadeSlideIn(
                        delay: Stagger.at(4),
                        child: TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        style: _inputStyle,
                        decoration: const InputDecoration(hintText: 'you@example.com'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v) ? null : 'Enter a valid email';
                        },
                      )),
                      const SizedBox(height: 22),
                      const Text.rich(
                        TextSpan(children: [
                          TextSpan(text: "By continuing you agree to Paypoint's "),
                          TextSpan(text: 'Terms', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.blue)),
                          TextSpan(text: ' and '),
                          TextSpan(
                              text: 'Privacy Policy', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.blue)),
                          TextSpan(text: '.'),
                        ]),
                        style: TextStyle(fontSize: 12, height: 1.55, color: AppColors.muted),
                      ),
                      const Spacer(),
                      const SizedBox(height: 24),
                      FadeSlideIn(
                        delay: Stagger.at(6),
                        child: PrimaryButton(label: 'Continue', loading: _submitting, shimmer: true, onPressed: _continue),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(Routes.main, (_) => false),
                          child: const Text.rich(
                            TextSpan(children: [
                              TextSpan(text: 'Already have an account? ', style: TextStyle(color: AppColors.body)),
                              TextSpan(text: 'Log in', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.blue)),
                            ]),
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }
}

/// Soft radial colour glow used behind light screens.
class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
          ),
        ),
      );
}

const _inputStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink);

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.hint});
  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text.rich(
          TextSpan(children: [
            TextSpan(text: text),
            if (hint != null)
              TextSpan(text: ' $hint', style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.muted)),
          ]),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.label),
        ),
      );
}

class _CountryPrefix extends StatelessWidget {
  const _CountryPrefix();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.fromLTRB(18, 4, 12, 4),
        decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppColors.border))),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('+234', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.body),
          ],
        ),
      );
}
