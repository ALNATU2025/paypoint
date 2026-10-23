import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/paypoint_logo.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final d = s.draft;
    final pkg = d.package!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  const FlowHeader(title: 'Review & confirm'),
                  const SizedBox(height: 22),
                  const StepProgress(step: 3, total: 3, label: 'Confirm'),
                  const SizedBox(height: 24),
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(26)),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: RingsPainter(center: const Offset(40, 220), radii: const [70], opacities: const [0.35]),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(22),
                          child: Center(
                            child: Column(
                              children: [
                                ProviderBadge(provider: d.provider, height: 30, fontSize: 13, radius: 10),
                                const SizedBox(height: 14),
                                const Text("You're paying",
                                    style: TextStyle(color: AppColors.onNavyMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text(Fmt.naira(d.total),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1)),
                                const SizedBox(height: 4),
                                Text('${pkg.name} · ${d.months} month${d.months == 1 ? '' : 's'}',
                                    style: const TextStyle(color: AppColors.onNavyMuted, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    radius: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    child: Column(
                      children: [
                        InfoRow(label: 'Account name', value: d.customer?.accountName ?? '—'),
                        InfoRow(label: d.provider.idLabel.replaceAll(' number', ''), value: Fmt.smartcard(d.number)),
                        InfoRow(label: 'Package', value: pkg.name),
                        InfoRow(label: 'New expiry', value: Fmt.date(d.newExpiry)),
                        const InfoRow(label: 'Service fee', value: 'Free', valueColor: AppColors.success),
                        InfoRow(label: 'Total', value: Fmt.naira(d.total), emphasis: true, divider: false, padding: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(16)),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: AppColors.warning),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Keep your decoder switched on for up to 15 minutes after payment.',
                            style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.warningText, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: PrimaryButton(
                label: 'Proceed to payment',
                onPressed: () => Navigator.of(context).pushNamed(Routes.payment),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
