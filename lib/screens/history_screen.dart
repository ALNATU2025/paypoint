import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../data/catalog.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/paypoint_logo.dart';
import 'main_shell.dart' show kFloatingNavClearance;

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  TvProviderId? _filter; // null = all

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final rows = s.transactions.where((t) => _filter == null || t.provider.id == _filter).toList();

    final filterIndex = _filter == null ? 0 : Catalog.providers.indexWhere((p) => p.id == _filter) + 1;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, kFloatingNavClearance + 12),
        children: [
          const FadeSlideIn(
            child: Text('History', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.9)),
          ),
          const SizedBox(height: 18),
          FadeSlideIn(
            delay: Stagger.at(1),
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), boxShadow: AppShadows.hero),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Container(
                  decoration: const BoxDecoration(gradient: AppGradients.hero),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: RingsPainter(
                            center: const Offset(320, 10),
                            radii: const [60, 100],
                            opacities: const [0.4, 0.2],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                child: _Stat(
                                  label: 'Spent this month',
                                  value: s.spentThisMonth().toDouble(),
                                  format: (v) => Fmt.naira(v.round()),
                                ),
                              ),
                              VerticalDivider(color: Colors.white.withValues(alpha: 0.14), width: 32, thickness: 1),
                              Expanded(
                                child: _Stat(
                                  label: 'Renewals',
                                  value: s.renewalsThisMonth().toDouble(),
                                  format: (v) => '${v.round()}',
                                ),
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
          const SizedBox(height: 18),
          FadeSlideIn(
            delay: Stagger.at(2),
            child: SlidingSegments(
              height: 46,
              background: Colors.white,
              labels: ['All', for (final p in Catalog.providers) p.name],
              indicatorColors: [AppColors.blue, for (final p in Catalog.providers) p.color],
              index: filterIndex,
              onChanged: (i) => setState(() => _filter = i == 0 ? null : Catalog.providers[i - 1].id),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: Column(
              key: ValueKey(_filter),
              children: rows.isEmpty
                  ? [
                      const FadeSlideIn(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Column(
                            children: [
                              IconTile(icon: Icons.receipt_long_rounded, size: 72, radius: 24, iconSize: 34),
                              SizedBox(height: 14),
                              Text('No transactions yet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                              SizedBox(height: 4),
                              Text('Payments for this provider will show up here.',
                                  style: TextStyle(color: AppColors.muted, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ]
                  : [
                      for (final (i, t) in rows.indexed) ...[
                        FadeSlideIn(
                          delay: Stagger.at(i + 3, stepMs: 60),
                          offset: const Offset(0, 18),
                          child: _TxTile(tx: t),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.format});
  final String label;
  final double value;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.onNavyMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          AnimatedAmount(
            value: value,
            format: format,
            style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: -0.6),
          ),
        ],
      );
}

class _TxTile extends StatelessWidget {
  const _TxTile({required this.tx});
  final TvTransaction tx;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => Navigator.of(context).pushNamed(Routes.receipt, arguments: tx),
      child: Row(
        children: [
          ProviderBadge(provider: tx.provider, width: 46, height: 46, fontSize: 11, radius: 15, short: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${tx.provider.name} ${tx.package.name}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(Fmt.shortDateTime(tx.date),
                    style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Fmt.naira(tx.amount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              StatusPill(success: tx.success),
            ],
          ),
        ],
      ),
    );
  }
}
