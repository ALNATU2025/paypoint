import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

/// Payment success: a check that draws itself inside a springy badge,
/// rippling rings, a confetti burst and a count-up of the amount paid.
class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key, required this.tx});
  final TvTransaction tx;

  void _home(BuildContext context) => Navigator.of(context).popUntil(ModalRoute.withName(Routes.main));

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _home(context);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Soft green glow behind the badge.
            Positioned(
              top: -120,
              left: -60,
              right: -60,
              child: IgnorePointer(
                child: Container(
                  height: 520,
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(colors: [Color(0x331E9A3E), Color(0x001E9A3E)]),
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
                          const Positioned.fill(child: ConfettiBurst()),
                          FadeSlideIn(
                            duration: const Duration(milliseconds: 900),
                            offset: Offset.zero,
                            scaleFrom: 0.2,
                            curve: Curves.elasticOut,
                            child: PulseRings(
                              color: AppColors.successStrong,
                              maxRadius: 150,
                              child: Container(
                                width: 116,
                                height: 116,
                                decoration: BoxDecoration(
                                  gradient: AppGradients.success,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0x661E9A3E), blurRadius: 40, offset: Offset(0, 18)),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const DrawnCheck(size: 62, strokeWidth: 7, delay: Duration(milliseconds: 380)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 450),
                      child: Column(
                        children: [
                          const Text('Subscription successful!',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                          const SizedBox(height: 8),
                          Text(
                            'Your ${tx.provider.name} ${tx.package.name} is now active. Enjoy every moment.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.body),
                          ),
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
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                          color: AppColors.ink,
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
                            InfoRow(label: 'Active until', value: Fmt.date(tx.activeUntil), divider: false, padding: 13),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 900),
                      child: Column(
                        children: [
                          PrimaryButton(
                            label: 'View receipt',
                            icon: Icons.receipt_long_rounded,
                            shimmer: true,
                            onPressed: () => Navigator.of(context).pushNamed(Routes.receipt, arguments: tx),
                          ),
                          const SizedBox(height: 12),
                          PrimaryButton(label: 'Back to home', tone: ButtonTone.soft, onPressed: () => _home(context)),
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
