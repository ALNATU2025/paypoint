import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/paypoint_logo.dart';
import 'home_screen.dart' show showFundWalletSheet;
import 'main_shell.dart' show kFloatingNavClearance;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _help(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Help & support', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              SizedBox(height: 14),
              _HelpItem(
                q: 'My payment says "processing"',
                a: 'The provider is still confirming it. Open the receipt from History and tap "Check status". '
                    'If it fails, your wallet is refunded automatically.',
              ),
              _HelpItem(
                q: 'My decoder is still off after paying',
                a: 'Keep the decoder on and tuned to a channel for up to 15 minutes. '
                    'For DStv/GOtv you can also clear the error code via the provider\'s self-service.',
              ),
              _HelpItem(
                q: 'My wallet was credited but the balance did not change',
                a: 'Open Fund wallet and tap "Check for new funds", or pull down on Home to refresh.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _decoders(BuildContext context, AppState s) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Saved decoders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (s.decoders.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No decoders yet. Pay for a subscription and it will appear here.',
                      style: TextStyle(color: AppColors.body)),
                ),
              for (final SavedDecoder d in s.decoders)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ProviderBadge(provider: d.provider, width: 44, height: 44, fontSize: 11, radius: 14, short: true),
                  title: Text('${d.nickname} · ${d.package.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${Fmt.smartcard(d.number)} · expires ${Fmt.date(d.expiresOn)}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    s.startRenewal(d);
                    Navigator.of(context).pushNamed(Routes.packages);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final top = MediaQuery.paddingOf(context).top;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Stack(
          children: [
            Container(
              height: 250 + top,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
              ),
              child: AuroraBackground(
                base: AppColors.navy,
                intensity: 0.42,
                child: CustomPaint(
                  painter:
                      RingsPainter(center: const Offset(350, 30), radii: const [90, 140, 190], opacities: const [0.3, 0.16, 0.08]),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, top + 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      FadeSlideIn(
                        scaleFrom: 0.7,
                        curve: Curves.easeOutBack,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(colors: [AppColors.bright, Colors.white, AppColors.amber, AppColors.bright]),
                            boxShadow: [BoxShadow(color: Color(0x663B6CFF), blurRadius: 20, offset: Offset(0, 8))],
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white,
                            child: Text(Fmt.initials(s.fullName),
                                style: const TextStyle(color: AppColors.navy, fontSize: 22, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.fullName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                            const SizedBox(height: 3),
                            Text(s.email.isNotEmpty ? '${s.email} · ${s.phone}' : s.phone,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: AppColors.onNavyMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  FadeSlideIn(
                    delay: Stagger.at(1),
                    child: AppCard(
                    radius: 22,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shadow: const [BoxShadow(color: Color(0x1A0B1A55), blurRadius: 30, offset: Offset(0, 10))],
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(child: _Count(value: '${s.decoders.length}', label: 'Decoders', icon: Icons.live_tv_rounded)),
                          const VerticalDivider(color: AppColors.divider, width: 1),
                          Expanded(child: _Count(value: '${s.transactions.length}', label: 'Payments', icon: Icons.receipt_long_rounded)),
                          const VerticalDivider(color: AppColors.divider, width: 1),
                          Expanded(
                            child: _Count(
                              value: '${s.fundings.where((f) => f.status == TxStatus.success).length}',
                              label: 'Top-ups',
                              icon: Icons.account_balance_wallet_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, kFloatingNavClearance + 8),
          child: Column(
            children: [
              FadeSlideIn(
                delay: Stagger.at(2),
                child: AppCard(
                radius: 22,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    if (s.isAdmin)
                      _MenuRow(
                        icon: Icons.admin_panel_settings_rounded,
                        label: 'Admin dashboard',
                        highlight: true,
                        onTap: () => Navigator.of(context).pushNamed(Routes.admin),
                      ),
                    _MenuRow(icon: Icons.tv_rounded, label: 'Saved decoders', onTap: () => _decoders(context, s)),
                    _MenuRow(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Fund wallet',
                      onTap: () => showFundWalletSheet(context),
                    ),
                    _MenuRow(
                      icon: Icons.notifications_none_rounded,
                      label: 'Renewal reminders',
                      trailing: Switch(value: s.remindersOn, onChanged: s.setReminders),
                      onTap: () => s.setReminders(!s.remindersOn),
                    ),
                    _MenuRow(
                      icon: Icons.lock_outline_rounded,
                      label: 'Change transaction PIN',
                      onTap: () => Navigator.of(context).pushNamed(Routes.changePin),
                    ),
                    _MenuRow(
                      icon: Icons.help_outline_rounded,
                      label: 'Help & support',
                      last: true,
                      onTap: () => _help(context),
                    ),
                  ],
                ),
              ),
              ),
              const SizedBox(height: 14),
              FadeSlideIn(
                delay: Stagger.at(3),
                child: PrimaryButton(
                label: 'Log out',
                icon: Icons.logout_rounded,
                tone: ButtonTone.danger,
                height: 52,
                onPressed: () {
                  final state = AppScope.read(context);
                  Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (_) => false);
                  state.logout();
                },
              ),
              ),
              const SizedBox(height: 18),
              const Opacity(opacity: 0.8, child: PaypointLockup(markSize: 20, fontSize: 13)),
              const SizedBox(height: 4),
              const Text('Version 1.0.0', style: TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.value, required this.label, required this.icon});
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, size: 18, color: AppColors.bright),
          const SizedBox(height: 6),
          AnimatedAmount(
            value: double.tryParse(value) ?? 0,
            duration: const Duration(milliseconds: 900),
            format: (v) => '${v.round()}',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500)),
        ],
      );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.last = false,
    this.highlight = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool last;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            IconTile(icon: icon, size: 40, radius: 13, iconSize: 20, active: highlight),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
            trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
          ],
        ),
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({required this.q, required this.a});
  final String q;
  final String a;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 4),
            Text(a, style: const TextStyle(color: AppColors.body, fontSize: 13, height: 1.45)),
          ],
        ),
      );
}
