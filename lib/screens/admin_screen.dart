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

/// Admin dashboard: overview, users (credit / debit / unlock PIN) and every
/// user's payments (requery pending ones). Only reachable by admin accounts;
/// the backend enforces it too.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tab = 0;
  late final AdminApi _api = AdminApi(AppScope.read(context).api);

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
                    title: 'Admin dashboard',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(10)),
                      child: const Text('ADMIN',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SlidingSegments(
                    labels: const ['Overview', 'Users', 'Payments'],
                    index: _tab,
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
                  0 => _OverviewTab(key: const ValueKey(0), api: _api),
                  1 => _UsersTab(key: const ValueKey(1), api: _api),
                  _ => _PaymentsTab(key: const ValueKey(2), api: _api),
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
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const IconTile(icon: Icons.cloud_off_rounded, size: 60, radius: 20, iconSize: 28),
                  const SizedBox(height: 12),
                  Text(snap.error.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  PrimaryButton(label: 'Try again', icon: Icons.refresh_rounded, expand: false, onPressed: onRetry),
                ],
              ),
            ),
          );
        }
        return builder(snap.data as T);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Overview
// ---------------------------------------------------------------------------

class _OverviewTab extends StatefulWidget {
  const _OverviewTab({super.key, required this.api});
  final AdminApi api;

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  late Future<AdminStats> _future = widget.api.stats();

  Future<void> _reload() async {
    final f = widget.api.stats();
    setState(() => _future = f);
    await f.catchError((_) => AdminStats(const {}));
  }

  @override
  Widget build(BuildContext context) {
    return _Loader<AdminStats>(
      future: _future,
      onRetry: _reload,
      builder: (st) => RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            FadeSlideIn(child: _SalesHero(stats: st)),
            const SizedBox(height: 14),
            if (!st.vtpassConfigured)
              FadeSlideIn(
                delay: Stagger.at(1),
                child: const _Banner(
                  icon: Icons.warning_amber_rounded,
                  text: 'Cable TV is off: VTPass keys are missing on the server.',
                ),
              ),
            if (st.pending > 0)
              FadeSlideIn(
                delay: Stagger.at(1),
                child: _Banner(
                  icon: Icons.schedule_rounded,
                  text: '${st.pending} payment${st.pending == 1 ? '' : 's'} still processing. See Payments → Pending.',
                ),
              ),
            const SizedBox(height: 6),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: [
                _StatTile(i: 2, icon: Icons.people_alt_rounded, label: 'Users', value: '${st.users}',
                    sub: '+${st.newUsersToday} today'),
                _StatTile(i: 3, icon: Icons.account_balance_wallet_rounded, label: 'In user wallets',
                    value: Fmt.naira(st.walletBalances.round())),
                _StatTile(i: 4, icon: Icons.savings_rounded, label: 'VTPass balance',
                    value: st.vtpassBalance == null ? '—' : Fmt.naira(st.vtpassBalance!.round()),
                    sub: st.vtpassMode == 'sandbox' ? 'Sandbox' : 'Live'),
                _StatTile(i: 5, icon: Icons.error_outline_rounded, label: 'Failed today', value: '${st.failedToday}',
                    sub: 'auto-refunded'),
              ],
            ),
            const SizedBox(height: 22),
            const SectionTitle('Sales by provider'),
            const SizedBox(height: 10),
            for (final (i, p) in Catalog.providers.indexed)
              FadeSlideIn(
                delay: Stagger.at(i + 6),
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
  const _Banner({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.warningBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFE2B3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.warningText, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
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
      if (mounted) {
        _toast(widget.hostContext,
            '${credit ? 'Credited' : 'Debited'} ${Fmt.naira(result.$1.round())}. New balance ${Fmt.naira(updated.balance.round())}');
        _reload();
      }
    } on ApiException catch (e) {
      if (mounted) _toast(widget.hostContext, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlock(AdminUser u) async {
    setState(() => _busy = true);
    try {
      await widget.api.unlockPin(u.id);
      if (mounted) {
        _toast(widget.hostContext, 'PIN unlocked for ${u.fullName}');
        _reload();
      }
    } on ApiException catch (e) {
      if (mounted) _toast(widget.hostContext, e.message);
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
  late Future<List<AdminTx>> _future = _load();
  final Set<String> _checking = {};

  Future<List<AdminTx>> _load() => widget.api.transactions(status: _filters[_filter]);

  Future<void> _reload() async {
    final f = _load();
    setState(() => _future = f);
    await f.catchError((_) => <AdminTx>[]);
  }

  Future<void> _requery(AdminTx t) async {
    setState(() => _checking.add(t.id));
    try {
      final r = await widget.api.requery(t.id);
      if (!mounted) return;
      _toast(context, r.status == 'pending' ? 'Still processing at VTPass' : 'Updated: ${r.status}');
      _reload();
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
            onChanged: (i) {
              setState(() {
                _filter = i;
                _future = _load();
              });
            },
          ),
        ),
        Expanded(
          child: _Loader<List<AdminTx>>(
            future: _future,
            onRetry: _reload,
            builder: (list) => RefreshIndicator(
              onRefresh: _reload,
              child: list.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('Nothing here', style: TextStyle(fontWeight: FontWeight.w700))),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => FadeSlideIn(
                        delay: Stagger.at(i.clamp(0, 10), baseMs: 0, stepMs: 35),
                        child: _TxRow(
                          tx: list[i],
                          checking: _checking.contains(list[i].id),
                          onRequery: list[i].isCable && list[i].status == 'pending' ? () => _requery(list[i]) : null,
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

class _TxRow extends StatelessWidget {
  const _TxRow({required this.tx, this.showUser = true, this.onRequery, this.checking = false});
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
