import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class PackagesScreen extends StatelessWidget {
  const PackagesScreen({super.key});

  static const _durations = [1, 3, 6];

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final d = s.draft;
    final p = d.provider;
    final sel = d.package;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  FlowHeader(
                    title: 'Choose a package',
                    trailing: ProviderBadge(provider: p, height: 32, fontSize: 13, radius: 10),
                  ),
                  const SizedBox(height: 22),
                  const StepProgress(step: 2, total: 3, label: 'Package'),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6EAF3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        for (final m in _durations)
                          Expanded(
                            child: _DurationTab(
                              label: '$m month${m == 1 ? '' : 's'}',
                              selected: d.months == m,
                              onTap: () => s.setMonths(m),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final pkg in p.packages) ...[
                    SelectTile(
                      radioFirst: true,
                      selected: sel?.id == pkg.id,
                      onTap: () => s.setPackage(pkg),
                      title: pkg.name,
                      subtitle: pkg.popular ? '${pkg.channels} · Popular' : pkg.channels,
                      trailing: Text(
                        Fmt.naira(pkg.priceFor(d.months)),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 4),
                  const Text(
                    'Prices are set by the provider and may change.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Color(0x140B1A55), blurRadius: 30, offset: Offset(0, -10))],
              ),
              padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.paddingOf(context).bottom + 18),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sel == null ? 'No package selected' : '${sel.name} · ${d.months} mo',
                        style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(Fmt.naira(d.total),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Continue',
                      onPressed: sel == null ? null : () => Navigator.of(context).pushNamed(Routes.review),
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

class _DurationTab extends StatelessWidget {
  const _DurationTab({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? const [BoxShadow(color: Color(0x140B1A55), blurRadius: 6, offset: Offset(0, 2))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? AppColors.ink : AppColors.body,
            ),
          ),
        ),
      ),
    );
  }
}
