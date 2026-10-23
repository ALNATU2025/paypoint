import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../data/catalog.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

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

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          const Text('History', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(22)),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(child: _Stat(label: 'Spent this month', value: Fmt.naira(s.spentThisMonth()))),
                  const VerticalDivider(color: Color(0xFF24398F), width: 32, thickness: 1),
                  Expanded(child: _Stat(label: 'Renewals', value: '${s.renewalsThisMonth()}')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _Chip(label: 'All', selected: _filter == null, onTap: () => setState(() => _filter = null)),
                for (final p in Catalog.providers)
                  _Chip(label: p.name, selected: _filter == p.id, onTap: () => setState(() => _filter = p.id)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_rounded, size: 48, color: AppColors.faint),
                  SizedBox(height: 12),
                  Text('No transactions yet', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            )
          else
            for (final t in rows) ...[
              _TxTile(tx: t),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.onNavyMuted, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w800)),
        ],
      );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          showCheckmark: false,
          selectedColor: AppColors.blue,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: selected ? Colors.white : AppColors.label),
          side: BorderSide(color: selected ? AppColors.blue : AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
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
          ProviderBadge(provider: tx.provider, width: 44, height: 44, fontSize: 11, radius: 14, short: true),
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
