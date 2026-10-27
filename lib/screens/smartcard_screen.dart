import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formatters.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../data/catalog.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

class SmartcardScreen extends StatefulWidget {
  const SmartcardScreen({super.key});

  @override
  State<SmartcardScreen> createState() => _SmartcardScreenState();
}

class _SmartcardScreenState extends State<SmartcardScreen> {
  late final TextEditingController _number;
  bool _checking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _number = TextEditingController(text: AppScope.read(context).draft.number);
  }

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final s = AppScope.read(context);
    setState(() {
      _checking = true;
      _error = null;
    });
    // Warm the package list while the number is checked.
    s.loadPackages(s.draft.provider).catchError((_) => <TvPackage>[]);
    try {
      await s.verifyCustomer();
      HapticFeedback.lightImpact();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _onChanged(String v, TvProvider p) {
    final s = AppScope.read(context);
    s.setNumber(v);
    setState(() => _error = null);
    if (s.draft.number.length == p.idLength) _lookup();
  }

  void _pickSaved(AppState s) {
    final saved = s.decoders.where((d) => d.provider.id == s.draft.provider.id).toList();
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
              Text('Saved ${s.draft.provider.name} decoders',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              if (saved.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No saved decoders for this provider yet.', style: TextStyle(color: AppColors.body)),
                ),
              for (final d in saved)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ProviderBadge(provider: d.provider, width: 44, height: 44, fontSize: 11, radius: 14, short: true),
                  title: Text(d.nickname, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(Fmt.smartcard(d.number)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _number.text = d.number;
                    _onChanged(d.number, d.provider);
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
    final d = s.draft;
    final p = d.provider;
    final customer = d.customer;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  const FlowHeader(title: 'Cable TV subscription'),
                  const SizedBox(height: 22),
                  const StepProgress(step: 1, total: 3, label: 'Decoder details'),
                  const SizedBox(height: 22),
                  FadeSlideIn(
                    delay: Stagger.at(1),
                    child: _DecoderPreview(provider: p, number: d.number, verified: customer != null),
                  ),
                  const SizedBox(height: 22),
                  const Text('Provider',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.label)),
                  const SizedBox(height: 10),
                  FadeSlideIn(
                    delay: Stagger.at(2),
                    child: SlidingSegments(
                      height: 54,
                      fontSize: 15,
                      labels: [for (final x in Catalog.providers) x.name],
                      italic: [for (final x in Catalog.providers) x.italicWordmark],
                      indicatorColors: [for (final x in Catalog.providers) x.color],
                      background: Colors.white,
                      unselectedText: AppColors.label,
                      index: Catalog.providers.indexWhere((x) => x.id == p.id),
                      onChanged: (i) {
                        s.setProvider(Catalog.providers[i]);
                        _number.clear();
                        setState(() => _error = null);
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(p.idLabel,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.label)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _number,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(p.idLength),
                    ],
                    onChanged: (v) => _onChanged(v, p),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 1),
                    decoration: InputDecoration(
                      hintText: 'Enter ${p.idLength}-digit number',
                      hintStyle: const TextStyle(fontSize: 15, letterSpacing: 0, fontWeight: FontWeight.w500, color: AppColors.faint),
                      errorText: _error,
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _checking
                            ? const SizedBox(
                                width: 42,
                                height: 42,
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2.4),
                                  ),
                                ),
                              )
                            : RoundIconButton(
                                icon: Icons.tv_rounded,
                                tooltip: 'Choose from saved decoders',
                                size: 42,
                                onPressed: () => _pickSaved(s),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Found on the sticker under your decoder.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    child: customer == null
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: FadeSlideIn(
                              key: ValueKey(customer.accountName + d.number),
                              scaleFrom: 0.94,
                              curve: Curves.easeOutBack,
                              child: _VerifiedCard(customer: customer),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: customer == null
                  ? PrimaryButton(
                      label: _checking ? 'Checking number…' : 'Verify number',
                      icon: Icons.verified_user_outlined,
                      loading: _checking,
                      onPressed: d.number.length >= 8 && !_checking ? _lookup : null,
                    )
                  : PrimaryButton(
                      label: 'Choose package',
                      trailingIcon: Icons.arrow_forward_rounded,
                      shimmer: true,
                      onPressed: () => Navigator.of(context).pushNamed(Routes.packages),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifiedCard extends StatelessWidget {
  const _VerifiedCard({required this.customer});
  final CustomerLookup customer;

  @override
  Widget build(BuildContext context) {
    final due = customer.dueDate;
    final days = due == null ? 999 : due.difference(DateTime.now()).inDays;
    return AppCard(
      border: Border.all(color: const Color(0xFFCDEFD8), width: 1.5),
      shadow: const [BoxShadow(color: Color(0x1A1E9A3E), blurRadius: 22, offset: Offset(0, 10))],
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.success,
                  boxShadow: [BoxShadow(color: Color(0x4D1E9A3E), blurRadius: 14, offset: Offset(0, 6))],
                ),
                alignment: Alignment.center,
                child: const DrawnCheck(size: 26, strokeWidth: 3.4, delay: Duration(milliseconds: 180)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Account verified',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
                    const SizedBox(height: 2),
                    Text(customer.accountName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          Row(
            children: [
              Expanded(
                child: _Kv(label: 'Current package', value: customer.currentBouquet ?? '—'),
              ),
              Expanded(
                child: _Kv(
                  label: 'Due date',
                  value: due == null ? '—' : Fmt.date(due),
                  color: days <= 5 ? AppColors.warning : AppColors.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Kv extends StatelessWidget {
  const _Kv({required this.label, required this.value, this.color = AppColors.ink});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ],
      );
}

/// A card-shaped preview of the decoder being paid for, tinted with the
/// provider's colour. Digits fill in as they're typed.
class _DecoderPreview extends StatelessWidget {
  const _DecoderPreview({required this.provider, required this.number, required this.verified});
  final TvProvider provider;
  final String number;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final shown = number.padRight(provider.idLength, '•');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      height: 150,
      decoration: BoxDecoration(
        gradient: AppGradients.of(provider.color),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: provider.color.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 14))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ShimmerSweep(
          opacity: 0.14,
          period: const Duration(milliseconds: 4800),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -50,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              Positioned(
                right: 30,
                bottom: -70,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            provider.name,
                            key: ValueKey(provider.id),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              fontStyle: provider.italicWordmark ? FontStyle.italic : FontStyle.normal,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        const Spacer(),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                          child: verified
                              ? const Glass(
                                  key: ValueKey('ok'),
                                  radius: 12,
                                  tint: Color(0x26FFFFFF),
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text('Verified',
                                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                                    ],
                                  ),
                                )
                              : const Icon(Icons.wifi_tethering_rounded, key: ValueKey('wait'), color: Colors.white70),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      provider.idLabel.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Fmt.smartcard(shown),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.2,
                        fontFeatures: [FontFeature.tabularFigures()],
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
