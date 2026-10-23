import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'home_screen.dart' show showFundWalletSheet;

class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({super.key});

  String _subtitle(PaymentMethod m, AppState s) => switch (m) {
        PaymentMethod.wallet => 'Balance ${Fmt.naira(s.walletBalance, kobo: true)}',
        PaymentMethod.card => 'Visa •••• 4821',
        PaymentMethod.bank => 'Pay from any bank app',
        PaymentMethod.ussd => 'No internet needed',
      };

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
                  AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Amount due',
                                  style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 3),
                              Text(Fmt.naira(d.total), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: AppColors.sky, borderRadius: BorderRadius.circular(10)),
                          child: Text('${d.provider.name} ${d.package?.name ?? ''}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.blue)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text('Pay with', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  for (final m in PaymentMethod.values) ...[
                    SelectTile(
                      selected: d.method == m,
                      onTap: () => s.setMethod(m),
                      leading: IconTile(icon: m.icon),
                      title: m.title,
                      subtitle: _subtitle(m, s),
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
                  OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Card linking is handled by your payment gateway SDK.')),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add new card', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.blue,
                      minimumSize: const Size.fromHeight(52),
                      side: const BorderSide(color: Color(0xFFB9C4E4), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                      Text('Payments are encrypted end to end',
                          style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: 'Pay ${Fmt.naira(d.total)}',
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
