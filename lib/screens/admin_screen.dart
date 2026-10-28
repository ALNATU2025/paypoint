import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/catalog.dart';
import '../services/admin_api.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/paypoint_logo.dart';

/// Admin dashboard: live overview, Paypoint wallet and Revenue wallet, users
/// (credit / debit / unlock PIN) and every user's payments. Super admins get
/// the same screen with everything visible plus funding the Paypoint wallet.
/// Only reachable by admin accounts; the backend enforces it too.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tab = 0;
  late final AdminApi _api = AdminApi(AppScope.read(context).api);
  late final bool _super = AppScope.read(context).isSuperAdmin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  FlowHeader(
                    title: _super ? 'Super admin' : 'Admin dashboard',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: _super ? AppGradients.warm : AppGradients.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_super ? 'SUPER' : 'ADMIN',
                          style: TextStyle(
                              color: _super ? AppColors.ink : Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SlidingSegments(
                    labels: const ['Overview', 'Wallets', 'Users', 'Payments'],
                    index: _tab,
                    fontSize: 12.5,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: switch (_tab) {
                  0 => _OverviewTab(key: const ValueKey(0), api: _api, onOpenWallets: () => setState(() => _tab = 1)),
                  1 => _WalletsTab(key: const ValueKey(1), api: _api, isSuper: _super),
                  2 => _UsersTab(key: const ValueKey(2), api: _api),
                  _ => _PaymentsTab(key: const ValueKey(3), api: _api),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _toast(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

/// Shared loading / error / retry wrapper.
class _Loader<T> extends StatelessWidget {
  const _Loader({required this.future, required this.onRetry, required this.builder});
  final Future<T>? future;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
        }
        if (snap.hasError) return _ErrorView(error: snap.error!, onRetry: onRetry);
        return builder(snap.data as T);
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IconTile(icon: Icons.cloud_off_rounded, size: 60, radius: 20, iconSize: 28),
              const SizedBox(height: 12),
              Text(error.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              PrimaryButton(label: 'Try again', icon: Icons.refresh_rounded, expand: false, onPressed: onRetry),
            ],
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Real-time: reload every few seconds while the screen is open
// ---------------------------------------------------------------------------

/// How often the dashboard refreshes itself.
const kLiveInterval = Duration(seconds: 5);

/// Loads [load] now and then every [every], keeping the last good data on
/// screen. The first load shows a spinner; later ones update in place.
class _Live<T> extends StatefulWidget {
  const _Live({super.key, required this.load, required this.builder, this.every = kLiveInterval});
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, _LiveInfo live) builder;
  final Duration every;

  @override
  State<_Live<T>> createState() => _LiveState<T>();
}

/// Passed to the builder: last update time, connection state and a manual refresh.
class _LiveInfo {
  const _LiveInfo({required this.updatedAt, required this.offline, required this.refresh});
  final DateTime updatedAt;
  final bool offline;
  final Future<void> Function() refresh;
}

class _LiveState<T> extends State<_Live<T>> {
  T? _data;
  Object? _error;
  DateTime _updated = DateTime.now();
  bool _inFlight = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(widget.every, (_) {
      final state = WidgetsBinding.instance.lifecycleState;
      // Don't poll while the app is in the background.
      if (state == null || state == AppLifecycleState.resumed) _fetch();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      final d = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = d;
        _error = null;
        _updated = DateTime.now();
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      _inFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) {
      if (_error != null) {
        return _ErrorView(
          error: _error!,
          onRetry: () {
            setState(() => _error = null);
            _fetch();
          },
        );
      }
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
    }
    return widget.builder(context, data, _LiveInfo(updatedAt: _updated, offline: _error != null, refresh: _fetch));
  }
}

/// "● Live · updated 10:42:05" (or "Reconnecting…" when the last refresh failed).
class _LiveBadge extends StatelessWidget {
  const _LiveBadge(this.live);
  final _LiveInfo live;

  static String _hms(DateTime d) =>
      [d.hour, d.minute, d.second].map((n) => n.toString().padLeft(2, '0')).join(':');

  @override
  Widget build(BuildContext context) {
    final color = live.offline ? AppColors.warning : AppColors.successStrong;
    return Row(
      children: [
        PulseDot(color: color, size: 7),
        const SizedBox(width: 8),
        Text(live.offline ? 'Reconnecting…' : 'Live',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(width: 6),
        Text('· updated ${_hms(live.updatedAt)}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Overview
// ---------------------------------------------------------------------------

/// Below this the dashboard warns that the Paypoint wallet is running low.
const kPoolLowNaira = 20000.0;

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({super.key, required this.api, required this.onOpenWallets});
  final AdminApi api;
  final VoidCallback onOpenWallets;

  @override
  Widget build(BuildContext context) {
    return _Live<AdminStats>(
      load: api.stats,
      builder: (context, st, live) {
        final w = st.wallets;
        return RefreshIndicator(
          onRefresh: live.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _LiveBadge(live),
              const SizedBox(height: 10),
              FadeSlideIn(child: _SalesHero(stats: st)),
              const SizedBox(height: 14),
              if (w.paypointBalance <= 0)
                const _Banner(
                  icon: Icons.block_rounded,
                  danger: true,
                  text: 'Payments are paused: the Paypoint wallet is empty. No one can pay until it is funded.',
                )
              else if (w.paypointBalance < kPoolLowNaira)
                const _Banner(
                  icon: Icons.battery_alert_rounded,
                  text: 'The Paypoint wallet is running low. Payments stop when it runs out.',
                ),
              if (!st.vtpassConfigured)
                const _Banner(
                  icon: Icons.warning_amber_rounded,
                  text: 'Cable TV is off: VTPass keys are missing on the server.',
                ),
              if (st.pending > 0)
                _Banner(
                  icon: Icons.schedule_rounded,
                  text: '${st.pending} payment${st.pending == 1 ? '' : 's'} still processing. See Payments → Pending.',
                ),
              const SizedBox(height: 4),
              FadeSlideIn(
                delay: Stagger.at(1),
                child: _PoolCard(summary: w, onTap: onOpenWallets, compact: true),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: Stagger.at(2),
                child: _RevenueCard(
                  title: 'Revenue',
                  percent: w.revenuePercent,
                  balance: w.revenueBalance,
                  sub: 'Earned ${Fmt.naira(w.revenueEarned, kobo: true)} · withdrawn ${Fmt.naira(w.revenueWithdrawn, kobo: true)}',
                  onTap: onOpenWallets,
                ),
              ),
              if (w.hasSuperRevenue) ...[
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: Stagger.at(3),
                  child: _RevenueCard(
                    title: 'My revenue',
                    percent: w.superRevenuePercent,
                    balance: w.superRevenueTotal,
                    sub: 'Record of your share of every sale',
                    recordOnly: true,
                    onTap: onOpenWallets,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: [
                  _StatTile(i: 4, icon: Icons.people_alt_rounded, label: 'Users', value: '${st.users}',
                      sub: '+${st.newUsersToday} today'),
                  _StatTile(i: 5, icon: Icons.account_balance_wallet_rounded, label: 'In user wallets',
                      value: Fmt.naira(st.walletBalances.round())),
                  if (st.isSuper)
                    _StatTile(i: 6, icon: Icons.savings_rounded, label: 'VTPass balance',
                        value: st.vtpassBalance == null ? '—' : Fmt.naira(st.vtpassBalance!.round()),
                        sub: st.vtpassMode == 'sandbox' ? 'Sandbox' : 'Live')
                  else
                    _StatTile(i: 6, icon: Icons.schedule_rounded, label: 'Processing', value: '${st.pending}',
                        sub: 'awaiting VTPass'),
                  _StatTile(i: 7, icon: Icons.error_outline_rounded, label: 'Failed today', value: '${st.failedToday}',
                      sub: 'auto-refunded'),
                ],
              ),
              const SizedBox(height: 22),
              const SectionTitle('Sales by provider'),
              const SizedBox(height: 10),
              for (final (i, p) in Catalog.providers.indexed)
                FadeSlideIn(
                  delay: Stagger.at(i + 8),
                  child: _ProviderBar(
                    name: p.name,
                    color: p.color,
                    amount: st.byProvider[p.serviceID]?.$1 ?? 0,
                    count: st.byProvider[p.serviceID]?.$2 ?? 0,
                    total: st.salesAllAmount,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// The Paypoint wallet: navy hero card with the pool balance.
class _PoolCard extends StatelessWidget {
  const _PoolCard({required this.summary, this.onTap, this.compact = false, this.actions});
  final WalletSummary summary;
  final VoidCallback? onTap;
  final bool compact;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final bal = summary.paypointBalance;
    final empty = bal <= 0;
    final low = !empty && bal < kPoolLowNaira;
    return PressScale(
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: AppShadows.hero),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AuroraBackground(
              base: AppColors.deep,
              intensity: 0.5,
              child: Padding(
                padding: EdgeInsets.all(compact ? 18 : 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const PaypointMark(size: 26, onDark: true),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('Paypoint wallet',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: empty
                                ? AppColors.danger
                                : low
                                    ? AppColors.amber
                                    : AppColors.successStrong,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(empty ? 'PAUSED' : (low ? 'LOW' : 'ACTIVE'),
                              style: TextStyle(
                                  color: low ? AppColors.ink : Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1)),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 12 : 18),
                    AnimatedAmount(
                      value: bal,
                      duration: const Duration(milliseconds: 800),
                      format: (v) => Fmt.naira(v, kobo: true),
                      style: TextStyle(
                          color: Colors.white, fontSize: compact ? 28 : 34, fontWeight: FontWeight.w800, letterSpacing: -1),
                    ),
                    const SizedBox(height: 4),
                    const Text('Covers every subscription paid in the app',
                        style: TextStyle(color: AppColors.onNavyMuted, fontSize: 12.5)),
                    if (actions != null) ...[const SizedBox(height: 16), actions!],
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

/// A Revenue wallet card (admin: withdrawable; super admin: record only).
class _RevenueCard extends StatelessWidget {
  const _RevenueCard({
    required this.title,
    required this.percent,
    required this.balance,
    required this.sub,
    this.recordOnly = false,
    this.onTap,
    this.action,
  });
  final String title;
  final double percent;
  final double balance;
  final String sub;
  final bool recordOnly;
  final VoidCallback? onTap;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final pct = percent == percent.roundToDouble() ? percent.toStringAsFixed(0) : percent.toString();
    return AppCard(
      onTap: onTap,
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(
                icon: recordOnly ? Icons.receipt_long_rounded : Icons.trending_up_rounded,
                size: 38,
                radius: 12,
                iconSize: 19,
                bg: recordOnly ? AppColors.warningBg : AppColors.successBg,
                fg: recordOnly ? AppColors.warning : AppColors.success,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    Text('$pct% of every sale', style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                  ],
                ),
              ),
              if (recordOnly) const GradientTag('Record only'),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedAmount(
            value: balance,
            duration: const Duration(milliseconds: 800),
            format: (v) => Fmt.naira(v, kobo: true),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6),
          ),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}

class _SalesHero extends StatelessWidget {
  const _SalesHero({required this.stats});
  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), boxShadow: AppShadows.hero),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: AuroraBackground(
          base: AppColors.navy,
          intensity: 0.4,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: RingsPainter(center: const Offset(330, 20), radii: const [70, 110], opacities: const [0.35, 0.18]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Today's sales",
                        style: TextStyle(color: AppColors.onNavyMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    AnimatedAmount(
                      value: stats.salesTodayAmount,
                      format: (v) => Fmt.naira(v.round()),
                      style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1),
                    ),
                    const SizedBox(height: 4),
                    Text('${stats.salesTodayCount} subscription${stats.salesTodayCount == 1 ? '' : 's'}',
                        style: const TextStyle(color: AppColors.onNavyMuted, fontSize: 13)),
                    const SizedBox(height: 16),
                    Glass(
                      radius: 14,
                      tint: const Color(0x1AFFFFFF),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        'All time: ${Fmt.naira(stats.salesAllAmount.round())} · ${stats.salesAllCount} sales',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.i, required this.icon, required this.label, required this.value, this.sub});
  final int i;
  final IconData icon;
  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      delay: Stagger.at(i, stepMs: 50),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTile(icon: icon, size: 30, radius: 10, iconSize: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            ),
            if (sub != null)
              Text(sub!, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _ProviderBar extends StatelessWidget {
  const _ProviderBar({required this.name, required this.color, required this.amount, required this.count, required this.total});
  final String name;
  final Color color;
  final double amount;
  final int count;
  final double total;

  @override
  Widget build(BuildContext context) {
    final frac = total <= 0 ? 0.0 : (amount / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              Text('$count sales', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              const Spacer(),
              Text(Fmt.naira(amount.round()), style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 10,
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(5)),
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: frac),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => FractionallySizedBox(
                widthFactor: v,
                heightFactor: 1,
                child: Container(
                  decoration: BoxDecoration(gradient: AppGradients.of(color), borderRadius: BorderRadius.circular(5)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text, this.danger = false});
  final IconData icon;
  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: danger ? AppColors.dangerBg : AppColors.warningBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: danger ? const Color(0xFFF7C5C1) : const Color(0xFFFFE2B3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: danger ? AppColors.danger : AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 12.5, color: danger ? AppColors.danger : AppColors.warningText, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Wallets: Paypoint wallet (pool), Revenue wallets and their history
// ---------------------------------------------------------------------------

class _WalletsTab extends StatefulWidget {
  const _WalletsTab({super.key, required this.api, required this.isSuper});
  final AdminApi api;
  final bool isSuper;

  @override
  State<_WalletsTab> createState() => _WalletsTabState();
}

class _WalletsTabState extends State<_WalletsTab> {
  int _filter = 0;
  bool _busy = false;
  final _liveKey = GlobalKey<_LiveState<WalletSummary>>();

  List<(String, String?)> get _filters => [
        ('All', null),
        ('Paypoint', 'pool'),
        (widget.isSuper ? 'Admin rev.' : 'Revenue', 'adminRevenue'),
        if (widget.isSuper) ('My revenue', 'superRevenue'),
      ];

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      HapticFeedback.mediumImpact();
      await _liveKey.currentState?._fetch();
    } on ApiException catch (e) {
      if (mounted) _toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _fundPool({required bool credit}) async {
    final r = await showDialog<(double, String)>(
      context: context,
      builder: (_) => _MoneyDialog(
        title: credit ? 'Fund Paypoint wallet' : 'Correct Paypoint wallet',
        subtitle: credit ? 'Adds money that pays for subscriptions' : 'Takes money out of the Paypoint wallet',
        confirm: credit ? 'Fund' : 'Remove',
        danger: !credit,
        noteHint: credit ? 'Note, e.g. VTPass top-up ref' : 'Reason',
      ),
    );
    if (r == null || !mounted) return;
    await _run(() async {
      final w = credit ? await widget.api.creditPool(r.$1, r.$2) : await widget.api.debitPool(r.$1, r.$2);
      if (mounted) _toast(context, 'Paypoint wallet: ${Fmt.naira(w.paypointBalance, kobo: true)}');
    });
  }

  Future<void> _withdraw(WalletSummary w) async {
    final r = await showDialog<(double, bool)>(
      context: context,
      builder: (_) => _WithdrawDialog(available: w.revenueBalance),
    );
    if (r == null || !mounted) return;
    final app = AppScope.read(context);
    await _run(() async {
      await widget.api.withdrawRevenue(r.$1, toPool: r.$2);
      if (!r.$2) await app.refreshMe();
      if (mounted) {
        _toast(context, '${Fmt.naira(r.$1, kobo: true)} moved to ${r.$2 ? 'the Paypoint wallet' : 'your wallet'}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filters = _filters;
    final wallet = filters[_filter.clamp(0, filters.length - 1)].$2;
    return _Live<WalletSummary>(
      key: _liveKey,
      load: () => widget.api.wallets(wallet: wallet),
      builder: (context, w, live) => RefreshIndicator(
        onRefresh: live.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _LiveBadge(live),
            const SizedBox(height: 10),
            FadeSlideIn(
              child: _PoolCard(
                summary: w,
                actions: widget.isSuper
                    ? Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Fund wallet',
                              icon: Icons.add_rounded,
                              tone: ButtonTone.light,
                              height: 46,
                              loading: _busy,
                              onPressed: () => _fundPool(credit: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          RoundIconButton(
                            icon: Icons.remove_rounded,
                            onDark: true,
                            onPressed: _busy || w.paypointBalance <= 0 ? null : () => _fundPool(credit: false),
                          ),
                        ],
                      )
                    : const Text('Funded by Paypoint. Payments stop when it is empty.',
                        style: TextStyle(color: AppColors.onNavyFaint, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: Stagger.at(1),
              child: _RevenueCard(
                title: widget.isSuper ? 'Admin revenue' : 'Revenue',
                percent: w.revenuePercent,
                balance: w.revenueBalance,
                sub: 'Earned ${Fmt.naira(w.revenueEarned, kobo: true)} · withdrawn ${Fmt.naira(w.revenueWithdrawn, kobo: true)}',
                action: widget.isSuper
                    ? null
                    : PrimaryButton(
                        label: 'Withdraw',
                        icon: Icons.north_east_rounded,
                        height: 46,
                        loading: _busy,
                        onPressed: w.revenueBalance > 0 ? () => _withdraw(w) : null,
                      ),
              ),
            ),
            if (w.hasSuperRevenue) ...[
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: Stagger.at(2),
                child: _RevenueCard(
                  title: 'My revenue',
                  percent: w.superRevenuePercent,
                  balance: w.superRevenueTotal,
                  sub: 'Your share of every sale, kept as a record',
                  recordOnly: true,
                ),
              ),
            ],
            const SizedBox(height: 22),
            const SectionTitle('History'),
            const SizedBox(height: 10),
            SlidingSegments(
              height: 40,
              background: Colors.white,
              fontSize: 11.5,
              labels: [for (final f in filters) f.$1],
              index: _filter.clamp(0, filters.length - 1),
              onChanged: (i) {
                setState(() => _filter = i);
                live.refresh();
              },
            ),
            const SizedBox(height: 12),
            if (w.ledger.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: Text('No activity yet', style: TextStyle(color: AppColors.muted))),
              ),
            for (final e in w.ledger) ...[
              _LedgerRow(entry: e, showWallet: wallet == null),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry, required this.showWallet});
  final LedgerEntry entry;
  final bool showWallet;

  IconData get _icon => switch (entry.kind) {
        'topup' => Icons.add_card_rounded,
        'payment' => Icons.live_tv_rounded,
        'refund' => Icons.undo_rounded,
        'revenue' => Icons.trending_up_rounded,
        'withdrawal' => Icons.north_east_rounded,
        'transfer' => Icons.swap_horiz_rounded,
        _ => Icons.tune_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final sub = [
      if (showWallet) e.walletName,
      if (e.note.isNotEmpty && e.note != e.title) e.note,
      if (e.by != null) 'by ${e.by}',
      Fmt.shortDateTime(e.createdAt),
    ].join(' · ');
    return AppCard(
      radius: 16,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          IconTile(
            icon: _icon,
            size: 38,
            radius: 12,
            iconSize: 18,
            bg: e.credit ? AppColors.successBg : AppColors.skySoft,
            fg: e.credit ? AppColors.success : AppColors.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${e.credit ? '+' : '-'}${Fmt.naira(e.amount.abs(), kobo: true)}',
                  style: TextStyle(fontWeight: FontWeight.w800, color: e.credit ? AppColors.success : AppColors.ink)),
              Text('Bal ${Fmt.naira(e.balanceAfter, kobo: true)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.faint)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Amount + note dialog. Returns (amount, note).
class _MoneyDialog extends StatefulWidget {
  const _MoneyDialog({
    required this.title,
    required this.subtitle,
    required this.confirm,
    this.danger = false,
    this.noteHint = 'Note',
    this.max,
  });
  final String title;
  final String subtitle;
  final String confirm;
  final bool danger;
  final String noteHint;
  final double? max;

  @override
  State<_MoneyDialog> createState() => _MoneyDialogState();
}

class _MoneyDialogState extends State<_MoneyDialog> {
  final _amount = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = double.tryParse(_amount.text) ?? 0;
    final over = widget.max != null && value > widget.max!;
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.subtitle, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 14),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              prefixText: '₦ ',
              hintText: '0',
              errorText: over ? 'More than ${Fmt.naira(widget.max!, kobo: true)}' : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: _note, maxLength: 100, decoration: InputDecoration(hintText: widget.noteHint)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: widget.danger ? AppColors.danger : AppColors.blue),
          onPressed: value > 0 && !over ? () => Navigator.pop(context, (value, _note.text.trim())) : null,
          child: Text('${widget.confirm} ${value > 0 ? Fmt.naira(value, kobo: value != value.roundToDouble()) : ''}'),
        ),
      ],
    );
  }
}

/// Admin revenue withdrawal: amount and destination. Returns (amount, toPool).
class _WithdrawDialog extends StatefulWidget {
  const _WithdrawDialog({required this.available});
  final double available;

  @override
  State<_WithdrawDialog> createState() => _WithdrawDialogState();
}

class _WithdrawDialogState extends State<_WithdrawDialog> {
  final _amount = TextEditingController();
  bool _toPool = true;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Widget _option({required bool pool, required IconData icon, required String title, required String sub}) {
    final selected = _toPool == pool;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: () => setState(() => _toPool = pool),
        radius: 16,
        padding: const EdgeInsets.all(12),
        shadow: null,
        color: selected ? AppColors.skySoft : Colors.white,
        border: Border.all(color: selected ? AppColors.blue : AppColors.border, width: selected ? 1.6 : 1),
        child: Row(
          children: [
            IconTile(icon: icon, size: 36, radius: 11, iconSize: 18, active: selected),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(sub, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                ],
              ),
            ),
            RadioDot(selected: selected),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = double.tryParse(_amount.text) ?? 0;
    final over = value > widget.available + 0.001;
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Withdraw revenue', style: TextStyle(fontWeight: FontWeight.w800)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available ${Fmt.naira(widget.available, kobo: true)}', style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                prefixText: '₦ ',
                hintText: '0',
                errorText: over ? 'More than your revenue' : null,
                suffixIcon: TextButton(
                  onPressed: () => setState(() => _amount.text = widget.available.toStringAsFixed(2)),
                  child: const Text('All'),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _option(
              pool: true,
              icon: Icons.account_balance_rounded,
              title: 'Paypoint wallet',
              sub: 'Keeps payments going',
            ),
            _option(
              pool: false,
              icon: Icons.account_balance_wallet_rounded,
              title: 'My wallet',
              sub: 'Your Paypoint app balance',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.blue),
          onPressed: value > 0 && !over ? () => Navigator.pop(context, (value, _toPool)) : null,
          child: const Text('Withdraw'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Users
// ---------------------------------------------------------------------------

class _UsersTab extends StatefulWidget {
  const _UsersTab({super.key, required this.api});
  final AdminApi api;

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  String _q = '';
  Timer? _debounce;
  late Future<List<AdminUser>> _future = widget.api.users();

  void _search(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _q = q.trim();
        _future = widget.api.users(q: _q);
      });
    });
  }

  Future<void> _reload() async {
    final f = widget.api.users(q: _q);
    setState(() => _future = f);
    await f.catchError((_) => <AdminUser>[]);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: TextField(
            onChanged: _search,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              hintText: 'Search name, email or phone',
              prefixIcon: Icon(Icons.search_rounded),
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        Expanded(
          child: _Loader<List<AdminUser>>(
            future: _future,
            onRetry: _reload,
            builder: (users) => RefreshIndicator(
              onRefresh: _reload,
              child: users.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('No users found', style: TextStyle(fontWeight: FontWeight.w700))),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => FadeSlideIn(
                        delay: Stagger.at(i.clamp(0, 10), baseMs: 0, stepMs: 35),
                        child: _UserTile(
                          user: users[i],
                          onTap: () async {
                            await showUserSheet(context, widget.api, users[i].id);
                            _reload();
                          },
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.onTap});
  final AdminUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      radius: 18,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: user.isAdmin ? AppColors.blue : AppColors.navy,
            child: Text(Fmt.initials(user.fullName),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(user.fullName,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    if (user.isAdmin) ...[const SizedBox(width: 6), const GradientTag('Admin', gradient: AppGradients.primary, textColor: Colors.white)],
                    if (user.pinLocked) ...[const SizedBox(width: 6), const GradientTag('Locked')],
                  ],
                ),
                const SizedBox(height: 2),
                Text(user.email.isNotEmpty ? user.email : user.phone,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(Fmt.naira(user.balance.round()), style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// User detail: balance, credit / debit, unlock PIN, recent activity.
Future<void> showUserSheet(BuildContext context, AdminApi api, String userId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => _UserSheet(api: api, userId: userId, scroll: scroll, hostContext: context),
    ),
  );
}

class _UserSheet extends StatefulWidget {
  const _UserSheet({required this.api, required this.userId, required this.scroll, required this.hostContext});
  final AdminApi api;
  final String userId;
  final ScrollController scroll;
  final BuildContext hostContext;

  @override
  State<_UserSheet> createState() => _UserSheetState();
}

class _UserSheetState extends State<_UserSheet> {
  late Future<(AdminUser, List<AdminTx>)> _future = widget.api.user(widget.userId);
  bool _busy = false;

  void _reload() => setState(() => _future = widget.api.user(widget.userId));

  Future<void> _adjust(AdminUser u, {required bool credit}) async {
    final messenger = ScaffoldMessenger.of(widget.hostContext);
    final result = await showDialog<(double, String)>(
      context: context,
      builder: (_) => _AmountDialog(credit: credit, user: u),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final updated = credit
          ? await widget.api.credit(u.id, result.$1, result.$2)
          : await widget.api.debit(u.id, result.$1, result.$2);
      HapticFeedback.mediumImpact();
      messenger.showSnackBar(SnackBar(
        content: Text(
          '${credit ? 'Credited' : 'Debited'} ${Fmt.naira(result.$1.round())}. '
          'New balance ${Fmt.naira(updated.balance.round())}',
        ),
      ));
      if (mounted) _reload();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlock(AdminUser u) async {
    final messenger = ScaffoldMessenger.of(widget.hostContext);
    setState(() => _busy = true);
    try {
      await widget.api.unlockPin(u.id);
      messenger.showSnackBar(SnackBar(content: Text('PIN unlocked for ${u.fullName}')));
      if (mounted) _reload();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Loader<(AdminUser, List<AdminTx>)>(
      future: _future,
      onRetry: _reload,
      builder: (data) {
        final (u, txs) = data;
        return ListView(
          controller: widget.scroll,
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.navy,
                  child: Text(Fmt.initials(u.fullName),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.fullName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                      if (u.email.isNotEmpty)
                        Text(u.email, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                      Text(u.phone, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(gradient: AppGradients.hero, borderRadius: BorderRadius.circular(22)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Wallet balance', style: TextStyle(color: AppColors.onNavyMuted, fontSize: 12)),
                        const SizedBox(height: 4),
                        AnimatedAmount(
                          value: u.balance,
                          duration: const Duration(milliseconds: 700),
                          format: (v) => Fmt.naira(v, kobo: true),
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(u.hasPin ? 'PIN set' : 'No PIN yet',
                          style: const TextStyle(color: AppColors.onNavyMuted, fontSize: 12)),
                      if (u.createdAt != null)
                        Text('Joined ${Fmt.date(u.createdAt!)}',
                            style: const TextStyle(color: AppColors.onNavyMuted, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Credit',
                    icon: Icons.add_rounded,
                    height: 50,
                    loading: _busy,
                    onPressed: () => _adjust(u, credit: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: 'Debit',
                    icon: Icons.remove_rounded,
                    tone: ButtonTone.danger,
                    height: 50,
                    onPressed: _busy || u.balance <= 0 ? null : () => _adjust(u, credit: false),
                  ),
                ),
              ],
            ),
            if (u.pinLocked) ...[
              const SizedBox(height: 10),
              PrimaryButton(
                label: 'Unlock PIN',
                icon: Icons.lock_open_rounded,
                tone: ButtonTone.soft,
                height: 50,
                onPressed: _busy ? null : () => _unlock(u),
              ),
            ],
            const SizedBox(height: 22),
            const Text('Recent activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (txs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No transactions yet', style: TextStyle(color: AppColors.muted)),
              ),
            for (final t in txs) ...[
              _TxRow(tx: t, showUser: false),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _AmountDialog extends StatefulWidget {
  const _AmountDialog({required this.credit, required this.user});
  final bool credit;
  final AdminUser user;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  final _amount = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = double.tryParse(_amount.text) ?? 0;
    final over = !widget.credit && value > widget.user.balance;
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(widget.credit ? 'Credit wallet' : 'Debit wallet', style: const TextStyle(fontWeight: FontWeight.w800)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.user.fullName, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 14),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              prefixText: '₦ ',
              hintText: '0',
              errorText: over ? 'More than the balance (${Fmt.naira(widget.user.balance.round())})' : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLength: 100,
            decoration: InputDecoration(hintText: widget.credit ? 'Note, e.g. Bank transfer ref' : 'Reason'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: widget.credit ? AppColors.blue : AppColors.danger),
          onPressed: value > 0 && !over
              ? () => Navigator.pop(context, (value, _note.text.trim().isEmpty ? (widget.credit ? 'Wallet credit' : 'Wallet correction') : _note.text.trim()))
              : null,
          child: Text(widget.credit ? 'Credit ${value > 0 ? Fmt.naira(value.round()) : ''}' : 'Debit ${value > 0 ? Fmt.naira(value.round()) : ''}'),
        ),
      ],
    );
  }
}
// ---------------------------------------------------------------------------
// Payments
// ---------------------------------------------------------------------------

class _PaymentsTab extends StatefulWidget {
  const _PaymentsTab({super.key, required this.api});
  final AdminApi api;

  @override
  State<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<_PaymentsTab> {
  static const _filters = [null, 'pending', 'failed', 'success'];
  int _filter = 0;
  final Set<String> _checking = {};

  Future<List<AdminTx>> _load(int filter) => widget.api.transactions(status: _filters[filter]);

  Future<void> _requery(AdminTx t, _LiveInfo live) async {
    setState(() => _checking.add(t.id));
    try {
      final r = await widget.api.requery(t.id);
      if (!mounted) return;
      _toast(context, r.status == 'pending' ? 'Still processing at VTPass' : 'Updated: ${r.status}');
      await live.refresh();
    } on ApiException catch (e) {
      if (mounted) _toast(context, e.message);
    } finally {
      if (mounted) setState(() => _checking.remove(t.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: SlidingSegments(
            height: 42,
            background: Colors.white,
            fontSize: 12,
            labels: const ['All', 'Pending', 'Failed', 'Success'],
            index: _filter,
            onChanged: (i) => setState(() => _filter = i),
          ),
        ),
        Expanded(
          // A new key per filter restarts the live feed with that filter.
          child: _Live<List<AdminTx>>(
            key: ValueKey(_filter),
            load: () => _load(_filter),
            builder: (context, list, live) => RefreshIndicator(
              onRefresh: live.refresh,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                itemCount: list.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LiveBadge(live),
                        if (list.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 80),
                            child: Center(child: Text('Nothing here', style: TextStyle(fontWeight: FontWeight.w700))),
                          ),
                      ],
                    );
                  }
                  final t = list[i - 1];
                  return _TxRow(
                    key: ValueKey(t.id),
                    tx: t,
                    checking: _checking.contains(t.id),
                    onRequery: t.isCable && t.status == 'pending' ? () => _requery(t, live) : null,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({super.key, required this.tx, this.showUser = true, this.onRequery, this.checking = false});
  final AdminTx tx;
  final bool showUser;
  final VoidCallback? onRequery;
  final bool checking;

  @override
  Widget build(BuildContext context) {
    final provider = Catalog.byServiceID(tx.serviceID);
    final sign = tx.isCable || tx.isDebit ? '-' : '+';
    return AppCard(
      radius: 18,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              if (provider != null)
                ProviderBadge(provider: provider, width: 42, height: 42, fontSize: 10, radius: 14, short: true)
              else
                IconTile(
                  icon: tx.isDebit ? Icons.north_east_rounded : Icons.south_west_rounded,
                  size: 42,
                  radius: 14,
                  active: !tx.isDebit,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (showUser && tx.userName != null) tx.userName!,
                        if (tx.billersCode != null) Fmt.smartcard(tx.billersCode!),
                        Fmt.shortDateTime(tx.createdAt),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$sign${Fmt.naira(tx.amount.round())}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  StatusPill(
                    success: tx.status == 'success',
                    pending: tx.status == 'pending',
                    label: tx.isCable ? null : (tx.status == 'success' ? 'Done' : null),
                  ),
                ],
              ),
            ],
          ),
          if (tx.status == 'failed' && (tx.message ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(tx.message!, style: const TextStyle(fontSize: 11.5, color: AppColors.danger)),
              ),
            ),
          if (onRequery != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: PrimaryButton(
                label: 'Check status with VTPass',
                icon: Icons.refresh_rounded,
                tone: ButtonTone.soft,
                height: 42,
                loading: checking,
                onPressed: onRequery,
              ),
            ),
        ],
      ),
    );
  }
}
