import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/paypoint_logo.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final d = s.draft;
    final pkg = d.package!;
    final extraViewPrice = s.extraViewPriceFor(d.provider);

    final List<(String, String, Color?)> rows = [
      ('Account name', d.customer?.accountName ?? '—', null),
      (d.provider.idLabel.replaceAll(' number', ''), Fmt.smartcard(d.number), null),
      if (d.custom)
        ('Amount', Fmt.naira(pkg.monthlyPrice), null)
      else
        ('Package', d.renew ? '${pkg.name} (renewal)' : '${pkg.name} · ${d.months} mo', null),
      if (d.extraView) ('Extra View', Fmt.naira(d.extraViewPrice), null),
      ('Paid from', 'Wallet · ${Fmt.naira(s.walletBalance, kobo: true)}', null),
      ('Service fee', d.serviceFee == 0 ? 'Free' : Fmt.naira(d.serviceFee), d.serviceFee == 0 ? AppColors.success : null),
    ];

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
                  FadeSlideIn(
                    scaleFrom: 0.95,
                    child: Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), boxShadow: AppShadows.hero),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: AuroraBackground(
                          base: AppColors.navy,
                          intensity: 0.4,
                          child: ShimmerSweep(
                            opacity: 0.1,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: RingsPainter(
                                      center: const Offset(30, 210),
                                      radii: const [70, 110],
                                      opacities: const [0.35, 0.18],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 26),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        ProviderBadge(provider: d.provider, height: 32, fontSize: 13, radius: 10, glow: true),
                                        const SizedBox(height: 16),
                                        const Text("You're paying",
                                            style: TextStyle(
                                                color: AppColors.onNavyMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        AnimatedAmount(
                                          value: d.total.toDouble(),
                                          format: (v) => Fmt.naira(v.round()),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 42,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Glass(
                                          radius: 14,
                                          tint: const Color(0x1AFFFFFF),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          child: Text(d.caption,
                                              style: const TextStyle(
                                                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (extraViewPrice != null) ...[
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      delay: Stagger.at(2),
                      child: AppCard(
                        radius: 22,
                        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
                        border: Border.all(
                          color: d.extraView ? AppColors.blue : AppColors.border,
                          width: d.extraView ? 1.6 : 1,
                        ),
                        onTap: () => s.setExtraView(!d.extraView),
                        child: Row(
                          children: [
                            IconTile(icon: Icons.connected_tv_rounded, size: 42, radius: 13, active: d.extraView),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Add Extra View', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                  const SizedBox(height: 2),
                                  Text('Second decoder · +${Fmt.naira(extraViewPrice)}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                                ],
                              ),
                            ),
                            Switch(value: d.extraView, onChanged: s.setExtraView),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  AppCard(
                    radius: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    child: Column(
                      children: [
                        for (final (i, r) in rows.indexed)
                          FadeSlideIn(
                            delay: Stagger.at(i + 3, stepMs: 60),
                            offset: const Offset(16, 0),
                            child: InfoRow(label: r.$1, value: r.$2, valueColor: r.$3),
                          ),
                        FadeSlideIn(
                          delay: Stagger.at(rows.length + 3, stepMs: 60),
                          child: InfoRow(
                            label: 'Total',
                            value: Fmt.naira(d.total),
                            emphasis: true,
                            divider: false,
                            padding: 16,
                            valueColor: AppColors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    delay: Stagger.at(9),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.warningBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFE2B3)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 18, color: AppColors.warning),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Keep your decoder switched on for up to 15 minutes after payment.',
                              style: TextStyle(
                                  fontSize: 12, height: 1.5, color: AppColors.warningText, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: PrimaryButton(
                label: 'Proceed to payment',
                icon: Icons.lock_rounded,
                shimmer: true,
                onPressed: () => Navigator.of(context).pushNamed(Routes.payment),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
