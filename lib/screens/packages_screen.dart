import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

/// Live bouquets from VTPass (through the backend).
class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  static const _durations = [1, 3, 6];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool force = false}) async {
    final s = AppScope.read(context);
    if (!force && s.packagesFor(s.draft.provider) != null) {
      _syncSelection(s);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await s.loadPackages(s.draft.provider, force: force);
      _syncSelection(s);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Keep the selected package pointing at the live (current-price) entry, and
  /// preselect the customer's current bouquet when nothing is chosen yet.
  void _syncSelection(AppState s) {
    final list = s.packagesFor(s.draft.provider) ?? const <TvPackage>[];
    final want = s.draft.package?.id ?? s.draft.customer?.currentBouquetCode;
    final match = list.where((p) => p.id == want).toList();
    if (match.isNotEmpty) {
      s.setPackage(match.first);
    } else if (s.draft.package != null) {
      s.draft.package = null; // no longer sold
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final d = s.draft;
    final p = d.provider;
    final sel = d.package;
    final currentCode = d.customer?.currentBouquetCode;
    final packages = s.packagesFor(p);

    Widget body;
    if (packages == null && _error == null) {
      body = Column(
        children: [
          for (var i = 0; i < 6; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ShimmerSweep(
                opacity: 0.6,
                period: const Duration(milliseconds: 1400),
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(color: const Color(0xFFE9EDF6), borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
        ],
      );
    } else if (packages == null || packages.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const IconTile(icon: Icons.wifi_off_rounded, size: 64, radius: 22, iconSize: 30),
            const SizedBox(height: 14),
            Text(_error ?? 'No packages available right now.',
                textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Try again',
              icon: Icons.refresh_rounded,
              expand: false,
              loading: _loading,
              onPressed: () => _load(force: true),
            ),
          ],
        ),
      );
    } else {
      body = Column(
        children: [
          for (final (i, pkg) in packages.indexed) ...[
            FadeSlideIn(
              delay: Stagger.at(i + 1, baseMs: 0, stepMs: 35),
              child: SelectTile(
                radioFirst: true,
                selected: sel?.id == pkg.id,
                onTap: () => s.setPackage(pkg),
                title: pkg.name,
                badge: pkg.id == currentCode ? 'Current' : null,
                subtitle: p.supportsMonths ? '${Fmt.naira(pkg.monthlyPrice)} / month' : null,
                trailing: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (c, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(a),
                      child: c,
                    ),
                  ),
                  child: Text(
                    Fmt.naira(pkg.priceFor(d.months)),
                    key: ValueKey('${pkg.id}-${d.months}'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _load(force: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  children: [
                    FlowHeader(
                      title: 'Choose a package',
                      trailing: ProviderBadge(provider: p, height: 32, fontSize: 13, radius: 10, glow: true),
                    ),
                    const SizedBox(height: 22),
                    const StepProgress(step: 2, total: 3, label: 'Package'),
                    if (d.customer != null) ...[
                      const SizedBox(height: 16),
                      FadeSlideIn(
                        child: Row(
                          children: [
                            const Icon(Icons.verified_rounded, size: 16, color: AppColors.success),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${d.customer!.accountName} · ${Fmt.smartcard(d.number)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.label),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (p.supportsMonths) ...[
                      const SizedBox(height: 16),
                      FadeSlideIn(
                        child: SlidingSegments(
                          labels: [for (final m in _durations) '$m month${m == 1 ? '' : 's'}'],
                          index: _durations.contains(d.months) ? _durations.indexOf(d.months) : 0,
                          onChanged: (i) => s.setMonths(_durations[i]),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    body,
                    const SizedBox(height: 4),
                    const Text(
                      'Live prices from the provider.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
            _CheckoutBar(
              caption: sel == null
                  ? 'No package selected'
                  : '${sel.name} · ${d.months} month${d.months == 1 ? '' : 's'}',
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
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      caption,
                      key: ValueKey(caption),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 170,
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
