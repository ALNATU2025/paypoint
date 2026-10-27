import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'home_screen.dart' show showFundWalletSheet;

class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({super.key});

  String _subtitle(PaymentMethod m, AppState s) => 'Balance ${Fmt.naira(s.walletBalance, kobo: true)}';

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final d = s.draft;
    final walletShort = d.method == PaymentMethod.wallet && !s.walletCanCover;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  const FlowHeader(title: 'Payment method'),
                  const SizedBox(height: 24),
                  FadeSlideIn(
                    delay: Stagger.at(0),
                    child: AppCard(
                    gradient: AppGradients.hero,
                    shadow: AppShadows.hero,
                    radius: 24,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Amount due',
                                  style: TextStyle(fontSize: 12, color: AppColors.onNavyMuted, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 3),
                              AnimatedAmount(
                                value: d.total.toDouble(),
                                duration: const Duration(milliseconds: 800),
                                format: (v) => Fmt.naira(v.round()),
                                style: const TextStyle(
                                    fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.8),
                              ),
                            ],
                          ),
                        ),
                        Glass(
                          radius: 12,
                          tint: const Color(0x1FFFFFFF),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Text('${d.provider.name} ${d.package?.name ?? ''}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  ),
                  const SizedBox(height: 26),
                  const Text('Pay with', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  for (final (i, m) in PaymentMethod.values.indexed) ...[
                    FadeSlideIn(
                      delay: Stagger.at(i + 2, stepMs: 60),
                      child: SelectTile(
                        selected: d.method == m,
                        onTap: () => s.setMethod(m),
                        leading: IconTile(icon: m.icon, active: d.method == m),
                        title: m.title,
                        badge: 'Instant',
                        subtitle: _subtitle(m, s),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (walletShort)
                    Container(
                      margin: const EdgeInsets.only(top: 2, bottom: 10),
                      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                      decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text('Your wallet balance is too low for this payment.',
                                style: TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600)),
                          ),
                          TextButton(
                            onPressed: () => showFundWalletSheet(context),
                            child: const Text('Fund wallet', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  FadeSlideIn(
                    delay: Stagger.at(4),
                    child: AppCard(
                      onTap: () => showFundWalletSheet(context),
                      radius: 18,
                      padding: const EdgeInsets.all(14),
                      border: Border.all(color: const Color(0xFFDCE3F5)),
                      shadow: null,
                      child: const Row(
                        children: [
                          IconTile(icon: Icons.credit_card_rounded, size: 42, radius: 13, iconSize: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Card, bank transfer or USSD',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                                SizedBox(height: 2),
                                Text('Top up your wallet securely with Paystack',
                                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
                              ],
                            ),
                          ),
                          Icon(Icons.add_circle_outline_rounded, color: AppColors.blue),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.muted),
                      SizedBox(width: 6),
                      Text("You'll confirm with your transaction PIN",
                          style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: 'Pay ${Fmt.naira(d.total)}',
                    icon: Icons.lock_rounded,
                    shimmer: !walletShort,
                    onPressed: walletShort ? null : () => Navigator.of(context).pushNamed(Routes.pin),
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
