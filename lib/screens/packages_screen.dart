import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

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
                    trailing: ProviderBadge(provider: p, height: 32, fontSize: 13, radius: 10, glow: true),
                  ),
                  const SizedBox(height: 22),
                  const StepProgress(step: 2, total: 3, label: 'Package'),
                  const SizedBox(height: 20),
                  FadeSlideIn(
                    delay: Stagger.at(0),
                    child: SlidingSegments(
                      labels: [for (final m in _durations) '$m month${m == 1 ? '' : 's'}'],
                      index: _durations.indexOf(d.months),
                      onChanged: (i) => s.setMonths(_durations[i]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final (i, pkg) in p.packages.indexed) ...[
                    FadeSlideIn(
                      delay: Stagger.at(i + 1, stepMs: 55),
                      child: SelectTile(
                        radioFirst: true,
                        selected: sel?.id == pkg.id,
                        onTap: () => s.setPackage(pkg),
                        title: pkg.name,
                        badge: pkg.popular ? 'Popular' : null,
                        subtitle: pkg.channels,
                        trailing: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          transitionBuilder: (c, a) => FadeTransition(
                            opacity: a,
                            child: SlideTransition(
                              position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(a),
                              child: c,
                            ),
                          ),
                          child: Column(
                            key: ValueKey('${pkg.id}-${d.months}'),
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                Fmt.naira(pkg.priceFor(d.months)),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                              if (d.months > 1)
                                Text(
                                  '${Fmt.naira(pkg.monthlyPrice)}/mo',
                                  style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w500),
                                ),
                            ],
                          ),
                        ),
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
            _CheckoutBar(
              caption: sel == null ? 'No package selected' : '${sel.name} · ${d.months} month${d.months == 1 ? '' : 's'}',
              total: d.total.toDouble(),
              onContinue: sel == null ? null : () => Navigator.of(context).pushNamed(Routes.review),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.caption, required this.total, required this.onContinue});
  final String caption;
  final double total;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      offset: const Offset(0, 60),
      duration: const Duration(milliseconds: 650),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Color(0x1A0B1A55), blurRadius: 34, offset: Offset(0, -12))],
        ),
        padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.paddingOf(context).bottom + 18),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    caption,
                    key: ValueKey(caption),
                    style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedAmount(
                  value: total,
                  duration: const Duration(milliseconds: 600),
                  format: (v) => Fmt.naira(v.round()),
                  style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: -0.6),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                label: 'Continue',
                trailingIcon: Icons.arrow_forward_rounded,
                shimmer: onContinue != null,
                onPressed: onContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
