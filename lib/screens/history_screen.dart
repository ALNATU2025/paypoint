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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.read(context).refreshHistory().catchError((_) {});
    });
  }

  Future<void> _refresh() => AppScope.read(context).refresh().catchError((Object e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      });

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    // "All" also shows wallet top-ups; provider filters show only that provider.
    final List<Object> rows = [
      ...s.transactions.where((t) => _filter == null || t.provider.id == _filter),
      if (_filter == null) ...s.fundings.where((f) => f.status == TxStatus.success),
    ]..sort((a, b) => _dateOf(b).compareTo(_dateOf(a)));

    final filterIndex = _filter == null ? 0 : Catalog.providers.indexWhere((p) => p.id == _filter) + 1;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                              Text('Your payments and top-ups will show up here.',
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
                          child: t is TvTransaction ? _TxTile(tx: t) : _FundingTile(tx: t as FundingTransaction),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  static DateTime _dateOf(Object o) => o is TvTransaction ? o.date : (o as FundingTransaction).date;
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
              StatusPill(success: tx.success, pending: tx.pending),
            ],
          ),
        ],
      ),
    );
  }
}

class _FundingTile extends StatelessWidget {
  const _FundingTile({required this.tx});
  final FundingTransaction tx;

  @override
  Widget build(BuildContext context) {
    final ok = tx.status == TxStatus.success;
    return AppCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          IconTile(icon: Icons.south_west_rounded, size: 46, radius: 15, active: ok),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.channel == 'admin' ? 'Wallet credit' : 'Wallet top-up',
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
              Text('+${Fmt.naira(tx.amount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: ok ? AppColors.success : AppColors.ink,
                  )),
              const SizedBox(height: 4),
              StatusPill(success: ok, pending: !ok, label: ok ? 'Received' : 'Awaiting payment'),
            ],
          ),
        ],
      ),
    );
  }
}
