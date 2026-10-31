import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';
import '../widgets/amount_sheet.dart';
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
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  /// DStv: pay an exact amount instead of a package.
  Future<void> _payAny(AppState s) async {
    final limits = s.customAmountLimits(s.draft.provider);
    if (limits == null) return;
    final amount = await showAmountSheet(
      context,
      title: 'Pay any amount',
      subtitle: 'The exact amount you enter is paid to this decoder.',
      initial: s.draft.custom ? s.draft.package?.monthlyPrice : s.draft.customer?.renewalAmount?.round(),
      min: limits.$1,
      max: limits.$2,
    );
    if (amount != null && mounted) s.selectCustomAmount(amount);
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
    if (s.draft.renew || s.draft.custom) return;
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
    final all = s.packagesFor(p);
    final q = _query.trim().toLowerCase();
    final packages = all == null || q.isEmpty ? all : all.where((x) => x.name.toLowerCase().contains(q)).toList();

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
    } else if (packages != null && packages.isEmpty && q.isNotEmpty) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Text('No package matches "$_query".',
            textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
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
                selected: !d.renew && sel?.id == pkg.id,
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
                    if (s.canRenew) ...[
                      const SizedBox(height: 16),
                      FadeSlideIn(child: _RenewCard(customer: d.customer!, selected: d.renew, onTap: s.selectRenewal)),
                      const SizedBox(height: 14),
                      const Text('Or change bouquet',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.label)),
                    ],
                    if (s.customAmountLimits(p) != null) ...[
                      SizedBox(height: s.canRenew ? 10 : 16),
                      FadeSlideIn(
                        child: SelectTile(
                          radioFirst: true,
                          selected: d.custom,
                          onTap: () => _payAny(s),
                          title: 'Pay any amount',
                          subtitle: d.custom ? 'Tap to change the amount' : 'Enter exactly what you want to pay',
                          trailing: d.custom
                              ? Text(Fmt.naira(d.package?.monthlyPrice ?? 0),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))
                              : const Icon(Icons.edit_rounded, size: 20, color: AppColors.blue),
                        ),
                      ),
                    ],
                    if (p.supportsMonths && !d.renew && !d.custom) ...[
                      const SizedBox(height: 16),
                      FadeSlideIn(
                        child: SlidingSegments(
                          labels: [for (final m in _durations) '$m month${m == 1 ? '' : 's'}'],
                          index: _durations.contains(d.months) ? _durations.indexOf(d.months) : 0,
                          onChanged: (i) => s.setMonths(_durations[i]),
                        ),
                      ),
                    ],
                    if ((all?.length ?? 0) > 10) ...[
                      const SizedBox(height: 14),
                      TextField(
                        onChanged: (v) => setState(() => _query = v),
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Search ${all!.length} ${p.name} packages',
                          prefixIcon: const Icon(Icons.search_rounded),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
              caption: d.caption,
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

/// "Renew current bouquet" at VTPass's Renewal_Amount (DStv / GOtv).
class _RenewCard extends StatelessWidget {
  const _RenewCard({required this.customer, required this.selected, required this.onTap});
  final CustomerLookup customer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: PressScale(
        scale: 0.98,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          decoration: BoxDecoration(
            gradient: AppGradients.hero,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: selected ? AppColors.bright : Colors.transparent, width: 2),
            boxShadow: selected ? AppShadows.hero : AppShadows.card,
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.autorenew_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Renew current bouquet',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 3),
                          Text(
                            customer.currentBouquet?.isNotEmpty == true
                                ? customer.currentBouquet!
                                : 'Same bouquet as now',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.onNavyMuted, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(Fmt.naira(customer.renewalAmount ?? 0),
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: selected
                              ? const Icon(Icons.check_circle_rounded, key: ValueKey(1), color: AppColors.amber, size: 22)
                              : const Icon(Icons.radio_button_unchecked_rounded,
                                  key: ValueKey(0), color: AppColors.onNavyMuted, size: 22),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
