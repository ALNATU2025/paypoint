import 'dart:async';

import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

/// Result of a cable payment.
/// - success: drawn check, rings, confetti and a count-up of the amount.
/// - pending: amber "processing" state that re-checks automatically.
/// - failed:  clear refund message.
class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key, required this.tx});
  final TvTransaction tx;

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  late TvTransaction _tx = widget.tx;
  Timer? _poll;
  int _polls = 0;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    if (_tx.pending) _poll = Timer.periodic(const Duration(seconds: 8), (_) => _check(auto: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _check({bool auto = false}) async {
    if (_checking) return;
    if (auto && ++_polls > 15) {
      _poll?.cancel();
      return;
    }
    setState(() => _checking = true);
    try {
      final updated = await AppScope.read(context).requery(_tx);
      if (!mounted) return;
      setState(() => _tx = updated);
      if (!updated.pending) _poll?.cancel();
    } on ApiException catch (e) {
      if (mounted && !auto) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _home() => Navigator.of(context).popUntil(ModalRoute.withName(Routes.main));

  @override
  Widget build(BuildContext context) {
    final tx = _tx;
    final (Color glow, LinearGradient badge, String title, String body) = switch (tx.status) {
      TxStatus.success => (
          const Color(0x331E9A3E),
          AppGradients.success,
          'Subscription successful!',
          'Your ${tx.provider.name} ${tx.package.name} is now active. Enjoy every moment.',
        ),
      TxStatus.pending => (
          const Color(0x33F28C1B),
          AppGradients.warm,
          'Payment processing',
          '${tx.provider.name} is confirming your payment. This usually takes less than a minute. '
              "We'll update this screen automatically.",
        ),
      TxStatus.failed => (
          const Color(0x26B42318),
          const LinearGradient(colors: [Color(0xFFE5484D), AppColors.danger]),
          'Payment failed',
          '${tx.message?.isNotEmpty == true ? '${tx.message}. ' : ''}'
              '${tx.refunded ? 'Your wallet has been refunded.' : 'No money was taken.'}',
        ),
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _home();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned(
              top: -120,
              left: -60,
              right: -60,
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: 520,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(colors: [glow, glow.withValues(alpha: 0)]),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    sliver: SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 270,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (tx.success) Positioned.fill(child: ConfettiBurst(key: ValueKey(tx.status))),
                                FadeSlideIn(
                                  key: ValueKey(tx.status),
                                  duration: const Duration(milliseconds: 900),
                                  offset: Offset.zero,
                                  scaleFrom: 0.2,
                                  curve: Curves.elasticOut,
                                  child: PulseRings(
                                    color: badge.colors.last,
                                    maxRadius: 150,
                                    child: Container(
                                      width: 116,
                                      height: 116,
                                      decoration: BoxDecoration(
                                        gradient: badge,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: badge.colors.last.withValues(alpha: 0.4),
                                            blurRadius: 40,
                                            offset: const Offset(0, 18),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: switch (tx.status) {
                                        TxStatus.success => const DrawnCheck(
                                            size: 62, strokeWidth: 7, delay: Duration(milliseconds: 380)),
                                        TxStatus.pending => const SizedBox(
                                            width: 48,
                                            height: 48,
                                            child: CircularProgressIndicator(strokeWidth: 4, color: Colors.white),
                                          ),
                                        TxStatus.failed => const Icon(Icons.close_rounded, color: Colors.white, size: 60),
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            child: Column(
                              key: ValueKey(tx.status),
                              children: [
                                Text(title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                                const SizedBox(height: 8),
                                Text(body,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.body)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 600),
                            child: AnimatedAmount(
                              value: tx.amount.toDouble(),
                              duration: const Duration(milliseconds: 1400),
                              format: (v) => Fmt.naira(v.round()),
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.2,
                                color: tx.failed ? AppColors.muted : AppColors.ink,
                                decoration: tx.failed ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 750),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.bg,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Column(
                                children: [
                                  InfoRow(label: 'Reference', value: tx.reference, padding: 13),
                                  InfoRow(
                                    label: tx.provider.idLabel.replaceAll(' number', ''),
                                    value: Fmt.smartcard(tx.smartcard),
                                    padding: 13,
                                  ),
                                  InfoRow(
                                    label: 'Package',
                                    value: '${tx.package.name} · ${tx.months} mo',
                                    divider: false,
                                    padding: 13,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 20),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 900),
                            child: Column(
                              children: [
                                if (tx.pending)
                                  PrimaryButton(
                                    label: 'Check status',
                                    icon: Icons.refresh_rounded,
                                    loading: _checking,
                                    onPressed: () => _check(),
                                  )
                                else if (tx.failed)
                                  PrimaryButton(
                                    label: 'Try again',
                                    icon: Icons.refresh_rounded,
                                    onPressed: () {
                                      final nav = Navigator.of(context);
                                      nav.popUntil(ModalRoute.withName(Routes.main));
                                      nav.pushNamed(Routes.review);
                                    },
                                  )
                                else
                                  PrimaryButton(
                                    label: 'View receipt',
                                    icon: Icons.receipt_long_rounded,
                                    shimmer: true,
                                    onPressed: () => Navigator.of(context).pushNamed(Routes.receipt, arguments: tx),
                                  ),
                                const SizedBox(height: 12),
                                PrimaryButton(label: 'Back to home', tone: ButtonTone.soft, onPressed: _home),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
