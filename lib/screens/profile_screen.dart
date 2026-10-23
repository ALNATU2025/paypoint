import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/paypoint_logo.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _soon(BuildContext context, String what) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$what — connect to your backend')));

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
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
              ),
              child: CustomPaint(
                painter: RingsPainter(center: const Offset(350, 30), radii: const [90, 140], opacities: const [0.3, 0.16]),
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
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        child: Text(Fmt.initials(s.fullName),
                            style: const TextStyle(color: AppColors.navy, fontSize: 22, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.fullName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                            const SizedBox(height: 3),
                            Text('${s.countryCode} ${s.phone}',
                                style: const TextStyle(fontSize: 13, color: AppColors.onNavyMuted)),
                          ],
                        ),
                      ),
                      PrimaryButton(
                        label: 'Edit',
                        tone: ButtonTone.dark,
                        expand: false,
                        height: 40,
                        onPressed: () => _soon(context, 'Edit profile'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  AppCard(
                    radius: 22,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shadow: const [BoxShadow(color: Color(0x1A0B1A55), blurRadius: 30, offset: Offset(0, 10))],
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(child: _Count(value: '${s.decoders.length}', label: 'Decoders')),
                          const VerticalDivider(color: AppColors.divider, width: 1),
                          Expanded(child: _Count(value: '${s.transactions.length}', label: 'Payments')),
                          const VerticalDivider(color: AppColors.divider, width: 1),
                          const Expanded(child: _Count(value: '1', label: 'Cards')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            children: [
              AppCard(
                radius: 22,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    _MenuRow(icon: Icons.tv_rounded, label: 'Saved decoders', onTap: () => _decoders(context, s)),
                    _MenuRow(icon: Icons.credit_card_rounded, label: 'Payment methods', onTap: () => _soon(context, 'Payment methods')),
                    _MenuRow(
                      icon: Icons.notifications_none_rounded,
                      label: 'Renewal reminders',
                      trailing: Switch(value: s.remindersOn, onChanged: s.setReminders),
                      onTap: () => s.setReminders(!s.remindersOn),
                    ),
                    _MenuRow(icon: Icons.lock_outline_rounded, label: 'Security & PIN', onTap: () => _soon(context, 'Security & PIN')),
                    _MenuRow(
                      icon: Icons.help_outline_rounded,
                      label: 'Help & support',
                      last: true,
                      onTap: () => _soon(context, 'Help & support'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'Log out',
                icon: Icons.logout_rounded,
                tone: ButtonTone.danger,
                height: 52,
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(Routes.signUp, (_) => false),
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
  const _Count({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, required this.onTap, this.trailing, this.last = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool last;

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
            IconTile(icon: icon, size: 38, radius: 12, iconSize: 20),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
            trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
          ],
        ),
      ),
    );
  }
}
