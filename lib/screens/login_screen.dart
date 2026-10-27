import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/paypoint_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final s = AppScope.read(context);
    try {
      await s.login(phone: _phone.text.trim(), password: _password.text);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(s.hasPin ? Routes.main : Routes.createPin, (_) => false);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -160,
            right: -120,
            child: IgnorePointer(
              child: Container(
                width: 380,
                height: 380,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color(0x2E3B6CFF), Color(0x003B6CFF)]),
                ),
              ),
            ),
          ),
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
                                Text('Welcome back',
                                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.9)),
                                SizedBox(height: 8),
                                Text('Log in to renew your DStv, GOtv and StarTimes in seconds.',
                                    style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.body)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          FadeSlideIn(
                            delay: Stagger.at(2),
                            child: TextFormField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.telephoneNumber],
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                                LengthLimitingTextInputFormatter(16),
                              ],
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(
                                labelText: 'Phone number',
                                hintText: '0803 456 7890',
                                prefixIcon: Icon(Icons.phone_iphone_rounded),
                              ),
                              validator: (v) =>
                                  (v ?? '').replaceAll(RegExp(r'\D'), '').length < 10 ? 'Enter your phone number' : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeSlideIn(
                            delay: Stagger.at(3),
                            child: TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) => _submit(),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  tooltip: _obscure ? 'Show password' : 'Hide password',
                                  icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) => (v ?? '').isEmpty ? 'Enter your password' : null,
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            child: _error == null
                                ? const SizedBox(width: double.infinity)
                                : Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: _ErrorBanner(_error!),
                                  ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 24),
                          if (_busy)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Center(
                                child: Text('Connecting… the first login can take up to a minute.',
                                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
                              ),
                            ),
                          FadeSlideIn(
                            delay: Stagger.at(4),
                            child: PrimaryButton(label: 'Log in', loading: _busy, shimmer: true, onPressed: _submit),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.signUp),
                              child: const Text.rich(
                                TextSpan(children: [
                                  TextSpan(text: 'New to Paypoint? ', style: TextStyle(color: AppColors.body)),
                                  TextSpan(
                                      text: 'Create an account',
                                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.blue)),
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.danger),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        ),
      );
}
