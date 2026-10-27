import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/formatters.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../data/catalog.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/paypoint_logo.dart';
import 'main_shell.dart' show kFloatingNavClearance;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenHistory, required this.onOpenProfile});

  final VoidCallback onOpenHistory;
  final VoidCallback onOpenProfile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hideBalance = false;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final expiring = (s.decoders.where((d) => d.daysLeft() <= 5).toList()
      ..sort((a, b) => a.daysLeft().compareTo(b.daysLeft())));

    var i = 0;
    Widget enter(Widget child) => FadeSlideIn(delay: Stagger.at(i++), child: child);

    return Stack(
      children: [
        // Soft brand glow at the top of the page.
        Positioned(
          top: -160,
          left: -80,
          right: -80,
          child: IgnorePointer(
            child: Container(
              height: 380,
              decoration: const BoxDecoration(
                gradient: RadialGradient(colors: [Color(0x263B6CFF), Color(0x003B6CFF)]),
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.blue,
            onRefresh: () => s.refresh().catchError((Object e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            }),
            child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, kFloatingNavClearance + 12),
            children: [
              enter(_Header(name: s.fullName)),
              const SizedBox(height: 22),
              enter(_WalletCard(
                balance: s.walletBalance,
                hidden: _hideBalance,
                onToggle: () => setState(() => _hideBalance = !_hideBalance),
                onHistory: widget.onOpenHistory,
              )),
              if (expiring.isNotEmpty) ...[
                const SizedBox(height: 16),
                enter(_ExpiryBanner(decoder: expiring.first)),
              ],
              const SizedBox(height: 26),
              enter(const SectionTitle('Pay for cable TV', hint: 'Choose provider')),
              const SizedBox(height: 14),
              enter(Row(
                children: [
                  for (final p in Catalog.providers) ...[
                    Expanded(child: _ProviderTile(provider: p)),
                    if (p != Catalog.providers.last) const SizedBox(width: 12),
                  ],
                ],
              )),
              const SizedBox(height: 22),
              enter(SectionTitle('Saved decoders', action: 'See all', onAction: widget.onOpenProfile)),
              const SizedBox(height: 4),
              if (s.decoders.isEmpty && s.loadingHistory)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
                )
              else if (s.decoders.isEmpty)
                enter(const AppCard(
                  child: Text('Decoders you pay for will appear here for one-tap renewal.',
                      style: TextStyle(color: AppColors.body, fontSize: 13)),
                ))
              else
                for (final d in s.decoders.take(4)) ...[
                  enter(_DecoderTile(decoder: d)),
                  const SizedBox(height: 12),
                ],
            ],
          ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.selectedBorder),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.bg),
            child: CircleAvatar(
              radius: 21,
              backgroundColor: AppColors.navy,
              child: Text(Fmt.initials(name),
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Fmt.greeting(),
                  style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(Fmt.firstName(name),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            ],
          ),
        ),
        RoundIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifications',
          badge: true,
          size: 46,
          onPressed: () {
            final s = AppScope.read(context);
            final soon = s.decoders.where((d) => d.daysLeft() <= 5).toList();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(soon.isEmpty
                  ? 'You are all caught up.'
                  : '${soon.first.nickname} ${soon.first.provider.name} expires in ${soon.first.daysLeft()} days.'),
            ));
          },
        ),
      ],
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.balance,
    required this.hidden,
    required this.onToggle,
    required this.onHistory,
  });

  final double balance;
  final bool hidden;
  final VoidCallback onToggle;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    const amountStyle = TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.2);

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), boxShadow: AppShadows.hero),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: ShimmerSweep(
          opacity: 0.1,
          period: const Duration(milliseconds: 5200),
          child: Container(
            decoration: const BoxDecoration(gradient: AppGradients.hero),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: RingsPainter(
                      center: const Offset(330, 30),
                      radii: const [70, 110, 150],
                      opacities: const [0.45, 0.25, 0.12],
                    ),
                  ),
                ),
                const Positioned(
                  right: -20,
                  bottom: -26,
                  child: Opacity(opacity: 0.07, child: PaypointMark(size: 150, onDark: true)),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Wallet balance',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onNavyMuted)),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              onToggle();
                            },
                            tooltip: hidden ? 'Show balance' : 'Hide balance',
                            visualDensity: VisualDensity.compact,
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                key: ValueKey(hidden),
                                size: 18,
                                color: AppColors.onNavyMuted,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Glass(
                            radius: 12,
                            tint: Color(0x1AFFFFFF),
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: Text('NGN',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFD6DFFF))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (c, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                            position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(a),
                            child: c,
                          ),
                        ),
                        child: hidden
                            ? const Text('₦ ••••••', key: ValueKey('hidden'), style: amountStyle)
                            : AnimatedAmount(
                                key: const ValueKey('shown'),
                                value: balance,
                                format: (v) => Fmt.naira(v, kobo: true),
                                style: amountStyle,
                              ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Fund wallet',
                              icon: Icons.add_rounded,
                              tone: ButtonTone.light,
                              height: 48,
                              onPressed: () => showFundWalletSheet(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Glass(
                              radius: 24,
                              tint: const Color(0x1FFFFFFF),
                              child: Material(
                                type: MaterialType.transparency,
                                child: InkWell(
                                  onTap: onHistory,
                                  child: const SizedBox(
                                    height: 46,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.receipt_long_rounded, size: 18, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('History',
                                            style: TextStyle(
                                                fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Real reminder from saved decoders that expire within five days.
class _ExpiryBanner extends StatelessWidget {
  const _ExpiryBanner({required this.decoder});
  final SavedDecoder decoder;

  @override
  Widget build(BuildContext context) {
    final days = decoder.daysLeft();
    final when = days <= 0 ? 'has expired' : 'expires in $days day${days == 1 ? '' : 's'}';
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      color: const Color(0xFFFFF8EC),
      border: Border.all(color: const Color(0xFFFFE2B3)),
      shadow: const [BoxShadow(color: Color(0x1AF28C1B), blurRadius: 18, offset: Offset(0, 8))],
      onTap: () {
        AppScope.read(context).startRenewal(decoder);
        Navigator.of(context).pushNamed(Routes.packages);
      },
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(gradient: AppGradients.warm, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.timer_outlined, color: AppColors.navy, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const PulseDot(size: 6),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text('${decoder.nickname} ${decoder.provider.name} $when',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.warningText)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('Renew ${decoder.package.name} now to keep watching',
                    style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.warning),
        ],
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({required this.provider});
  final TvProvider provider;

  @override
  Widget build(BuildContext context) {
    final c = provider.color;
    return PressScale(
      scale: 0.94,
      child: Container(
        height: 118,
        decoration: BoxDecoration(
          gradient: AppGradients.of(c),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: c.withValues(alpha: 0.32), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              AppScope.read(context).startFlow(provider);
              Navigator.of(context).pushNamed(Routes.smartcard);
            },
            child: Stack(
              children: [
                Positioned(
                  right: -26,
                  top: -26,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
                Positioned(
                  left: -18,
                  bottom: -30,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.live_tv_rounded, color: Colors.white, size: 17),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          if (provider.accentDot != null) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: provider.accentDot, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              provider.name,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: provider.name.length > 5 ? 14 : 18,
                                fontWeight: FontWeight.w800,
                                fontStyle: provider.italicWordmark ? FontStyle.italic : FontStyle.normal,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        provider.idLabel.replaceAll(' number', ''),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DecoderTile extends StatelessWidget {
  const _DecoderTile({required this.decoder});
  final SavedDecoder decoder;

  @override
  Widget build(BuildContext context) {
    final days = decoder.daysLeft();
    final soon = days <= 5;
    final status = days < 0
        ? 'Expired ${-days} days ago'
        : soon
            ? 'Expires in $days day${days == 1 ? '' : 's'}'
            : 'Active · $days days left';

    return AppCard(
      padding: const EdgeInsets.all(12),
      radius: 22,
      child: Row(
        children: [
          DaysRing(
            daysLeft: days,
            size: 44,
            child: ProviderBadge(provider: decoder.provider, width: 44, height: 44, fontSize: 11, radius: 22, short: true),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${decoder.nickname} · ${decoder.package.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: soon ? AppColors.warning : AppColors.success,
                    )),
              ],
            ),
          ),
          PrimaryButton(
            label: 'Renew',
            tone: soon ? ButtonTone.primary : ButtonTone.soft,
            expand: false,
            height: 40,
            onPressed: () {
              AppScope.read(context).startRenewal(decoder);
              Navigator.of(context).pushNamed(Routes.packages);
            },
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet to top up the wallet through Paystack checkout.
Future<void> showFundWalletSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _FundWalletSheet(hostContext: context),
    ),
  );
}

class _FundWalletSheet extends StatefulWidget {
  const _FundWalletSheet({required this.hostContext});

  /// The page that opened the sheet, used for snack bars after it closes.
  final BuildContext hostContext;

  @override
  State<_FundWalletSheet> createState() => _FundWalletSheetState();
}

class _FundWalletSheetState extends State<_FundWalletSheet> with WidgetsBindingObserver {
  static const _amounts = [2000, 5000, 10000, 20000];
  final _custom = TextEditingController();
  int? _picked = 5000;
  String? _reference;
  bool _busy = false;
  String? _note;

  int? get _amount {
    final typed = int.tryParse(_custom.text.replaceAll(RegExp(r'\D'), ''));
    return typed ?? _picked;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _custom.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _custom.dispose();
    super.dispose();
  }

  /// When the user comes back from the browser, check the payment.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _reference != null && !_busy) _verify(auto: true);
  }

  Future<void> _start() async {
    final amount = _amount;
    if (amount == null || amount < 100) {
      setState(() => _note = 'Enter at least ₦100');
      return;
    }
    setState(() {
      _busy = true;
      _note = null;
    });
    try {
      final (url, reference) = await AppScope.read(context).startFunding(amount);
      _reference = reference;
      final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!opened) throw ApiException('Could not open the payment page.');
      if (mounted) setState(() => _note = 'Complete the payment in your browser, then come back here.');
    } on ApiException catch (e) {
      if (mounted) setState(() => _note = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify({bool auto = false}) async {
    final ref = _reference;
    if (ref == null) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(widget.hostContext);
    try {
      final status = await AppScope.read(context).verifyFunding(ref);
      if (!mounted) return;
      switch (status) {
        case TxStatus.success:
          final amount = _amount ?? 0;
          Navigator.of(context).pop();
          messenger.showSnackBar(
            SnackBar(content: Text('${Fmt.naira(amount)} added to your wallet')),
          );
          return;
        case TxStatus.failed:
          setState(() {
            _note = 'That payment was not completed. You can try again.';
            _reference = null;
          });
        case TxStatus.pending:
          if (!auto) setState(() => _note = "We haven't received confirmation yet. If you've paid, wait a moment and check again.");
      }
    } on ApiException catch (e) {
      if (mounted && !auto) setState(() => _note = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final waiting = _reference != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                IconTile(icon: Icons.account_balance_wallet_rounded, active: true),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fund wallet', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                      SizedBox(height: 2),
                      Text('Card, bank transfer or USSD via Paystack',
                          style: TextStyle(fontSize: 13, color: AppColors.body)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (!waiting) ...[
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.8,
                children: [
                  for (final (idx, a) in _amounts.indexed)
                    FadeSlideIn(
                      delay: Stagger.at(idx, baseMs: 80, stepMs: 50),
                      child: _AmountChip(
                        label: Fmt.naira(a),
                        selected: _custom.text.isEmpty && _picked == a,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _custom.clear();
                          setState(() => _picked = a);
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _custom,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                decoration: const InputDecoration(prefixText: '₦ ', hintText: 'Or enter another amount'),
              ),
            ] else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.skySoft, borderRadius: BorderRadius.circular(18)),
                child: Row(
                  children: [
                    const PulseDot(color: AppColors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Waiting for your ${Fmt.naira(_amount ?? 0)} payment…',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
                      ),
                    ),
                  ],
                ),
              ),
            if (_note != null) ...[
              const SizedBox(height: 12),
              Text(_note!, style: const TextStyle(fontSize: 13, color: AppColors.body, height: 1.4)),
            ],
            const SizedBox(height: 20),
            if (waiting) ...[
              PrimaryButton(
                label: "I've paid — check now",
                icon: Icons.refresh_rounded,
                loading: _busy,
                onPressed: () => _verify(),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _busy ? null : _start,
                  child: const Text('Open payment page again', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ] else
              PrimaryButton(
                label: 'Pay ${Fmt.naira(_amount ?? 0)} with Paystack',
                icon: Icons.lock_rounded,
                shimmer: true,
                loading: _busy,
                onPressed: (_amount ?? 0) >= 100 ? _start : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? AppGradients.primary : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? Colors.transparent : AppColors.border, width: 1.5),
            boxShadow: selected ? AppShadows.glowBlue : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : AppColors.label,
            ),
          ),
        ),
      ),
    );
  }
}
