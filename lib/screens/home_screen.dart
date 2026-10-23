import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../data/catalog.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/paypoint_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenHistory, required this.onOpenProfile});

  final VoidCallback onOpenHistory;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          _Header(name: s.fullName),
          const SizedBox(height: 22),
          _WalletCard(balance: s.walletBalance, onHistory: onOpenHistory),
          const SizedBox(height: 26),
          const SectionTitle('Pay for cable TV', hint: 'Choose provider'),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final p in Catalog.providers) ...[
                Expanded(child: _ProviderTile(provider: p)),
                if (p != Catalog.providers.last) const SizedBox(width: 12),
              ],
            ],
          ),
          const SizedBox(height: 22),
          SectionTitle('Saved decoders', action: 'See all', onAction: onOpenProfile),
          const SizedBox(height: 4),
          if (s.decoders.isEmpty)
            const AppCard(
              child: Text('Decoders you pay for will appear here for one-tap renewal.',
                  style: TextStyle(color: AppColors.body, fontSize: 13)),
            )
          else
            for (final d in s.decoders) ...[
              _DecoderTile(decoder: d),
              const SizedBox(height: 12),
            ],
        ],
      ),
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
        CircleAvatar(
          radius: 23,
          backgroundColor: AppColors.navy,
          child: Text(Fmt.initials(name),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Fmt.greeting(),
                  style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(Fmt.firstName(name), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        RoundIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifications',
          badge: true,
          size: 46,
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your Living room DStv expires in 3 days.')),
          ),
        ),
      ],
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.balance, required this.onHistory});
  final double balance;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final whole = Fmt.naira(balance);
    final kobo = Fmt.naira(balance, kobo: true).split('.').last;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [BoxShadow(color: Color(0x470B1A55), blurRadius: 40, offset: Offset(0, 20))],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: RingsPainter(center: const Offset(330, 40), radii: const [70, 105], opacities: const [0.4, 0.22]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Wallet balance',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.onNavyMuted)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.navy2, borderRadius: BorderRadius.circular(12)),
                      child: const Text('NGN',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFD6DFFF))),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text.rich(
                    key: ValueKey(balance),
                    TextSpan(children: [
                      TextSpan(text: whole),
                      TextSpan(text: '.$kobo', style: const TextStyle(fontSize: 20, color: AppColors.onNavyFaint)),
                    ]),
                    style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Fund wallet',
                        icon: Icons.add_rounded,
                        tone: ButtonTone.light,
                        height: 46,
                        onPressed: () => showFundWalletSheet(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PrimaryButton(
                        label: 'History',
                        icon: Icons.schedule_rounded,
                        tone: ButtonTone.dark,
                        height: 46,
                        onPressed: onHistory,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      onTap: () {
        AppScope.read(context).startFlow(provider);
        Navigator.of(context).pushNamed(Routes.smartcard);
      },
      child: Column(
        children: [
          ProviderBadge(provider: provider, width: 76, height: 40, fontSize: provider.accentDot != null ? 11.5 : 16),
          const SizedBox(height: 10),
          Text(
            provider.idLabel.replaceAll(' number', ''),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.body),
          ),
        ],
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
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ProviderBadge(provider: decoder.provider, width: 44, height: 44, fontSize: 11, radius: 14, short: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${decoder.nickname} · ${decoder.package.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
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
            tone: ButtonTone.soft,
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

/// Bottom sheet to top up the wallet (demo: credits instantly).
Future<void> showFundWalletSheet(BuildContext context) {
  final amounts = [5000, 10000, 20000, 50000];
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) {
      int? picked = amounts[1];
      return StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fund wallet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('Choose an amount to add to your Paypoint wallet.',
                    style: TextStyle(fontSize: 14, color: AppColors.body)),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final a in amounts)
                      ChoiceChip(
                        label: Text(Fmt.naira(a)),
                        selected: picked == a,
                        onSelected: (_) => setSheet(() => picked = a),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: picked == a ? Colors.white : AppColors.label,
                        ),
                        selectedColor: AppColors.blue,
                        backgroundColor: Colors.white,
                        showCheckmark: false,
                        side: BorderSide(color: picked == a ? AppColors.blue : AppColors.border, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Add ${Fmt.naira(picked ?? 0)}',
                  onPressed: picked == null
                      ? null
                      : () {
                          AppScope.read(context).fundWallet(picked!.toDouble());
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${Fmt.naira(picked!)} added to your wallet')),
                          );
                        },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
