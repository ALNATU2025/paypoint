import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formatters.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../data/catalog.dart';
import '../models/models.dart';
import '../services/billing_service.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

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
    try {
      await s.verifyCustomer();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
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
                  const SizedBox(height: 26),
                  const Text('Provider',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.label)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final x in Catalog.providers) ...[
                        Expanded(
                          child: _ProviderSegment(
                            provider: x,
                            selected: x.id == p.id,
                            onTap: () {
                              s.setProvider(x);
                              _number.clear();
                              setState(() => _error = null);
                            },
                          ),
                        ),
                        if (x != Catalog.providers.last) const SizedBox(width: 10),
                      ],
                    ],
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
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    child: customer == null
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: _VerifiedCard(customer: customer),
                          ),
                  ),
                  if (customer != null) ...[
                    const SizedBox(height: 10),
                    SwitchRow(label: 'Save this decoder', value: d.saveDecoder, onChanged: s.setSaveDecoder),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: PrimaryButton(
                label: 'Choose package',
                onPressed: customer == null ? null : () => Navigator.of(context).pushNamed(Routes.packages),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderSegment extends StatelessWidget {
  const _ProviderSegment({required this.provider, required this.selected, required this.onTap});
  final TvProvider provider;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: provider.name,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          color: selected ? provider.color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? provider.color : AppColors.border, width: selected ? 2 : 1.5),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x2E0B1A55), blurRadius: 22, offset: Offset(0, 10))]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: Text(
                provider.name,
                style: TextStyle(
                  fontSize: provider.name.length > 5 ? 14 : 15,
                  fontWeight: FontWeight.w800,
                  fontStyle: provider.italicWordmark ? FontStyle.italic : FontStyle.normal,
                  color: selected ? Colors.white : AppColors.label,
                ),
              ),
            ),
          ),
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
    final days = customer.dueDate.difference(DateTime.now()).inDays;
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.successBg,
                child: Icon(Icons.check_rounded, color: AppColors.success, size: 22),
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
                child: _Kv(label: 'Current package', value: customer.currentPackage.name),
              ),
              Expanded(
                child: _Kv(
                  label: 'Due date',
                  value: Fmt.date(customer.dueDate),
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
