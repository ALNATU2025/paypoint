import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import 'common.dart';

/// Bottom sheet to type an amount in whole naira. Returns null when dismissed.
Future<int?> showAmountSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  int? initial,
  required int min,
  required int max,
  List<int> quick = const [5000, 10000, 20000, 50000],
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _AmountSheet(title: title, subtitle: subtitle, initial: initial, min: min, max: max, quick: quick),
  );
}

class _AmountSheet extends StatefulWidget {
  const _AmountSheet({
    required this.title,
    required this.subtitle,
    required this.initial,
    required this.min,
    required this.max,
    required this.quick,
  });
  final String title;
  final String? subtitle;
  final int? initial;
  final int min;
  final int max;
  final List<int> quick;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  late final _ctrl = TextEditingController(text: widget.initial?.toString() ?? '');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int get _value => int.tryParse(_ctrl.text) ?? 0;

  String? get _error {
    if (_ctrl.text.isEmpty) return null;
    if (_value < widget.min) return 'Minimum is ${Fmt.naira(widget.min)}';
    if (_value > widget.max) return 'Maximum is ${Fmt.naira(widget.max)}';
    return null;
  }

  void _set(int v) => setState(() {
        _ctrl.text = '$v';
        _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
      });

  @override
  Widget build(BuildContext context) {
    final valid = _ctrl.text.isNotEmpty && _error == null;
    final chips = <int>{if (widget.initial != null) widget.initial!, ...widget.quick}
        .where((v) => v >= widget.min && v <= widget.max)
        .toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(22, 14, 22, MediaQuery.viewInsetsOf(context).bottom + 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          Text(widget.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(widget.subtitle!, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          ],
          const SizedBox(height: 18),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8),
            decoration: InputDecoration(
              prefixText: '₦ ',
              prefixStyle: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.ink),
              hintText: '0',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in chips)
                ChoiceChip(
                  label: Text(Fmt.naira(v)),
                  selected: _value == v,
                  onSelected: (_) => _set(v),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _value == v ? Colors.white : AppColors.label,
                  ),
                  selectedColor: AppColors.blue,
                  backgroundColor: AppColors.skySoft,
                  side: BorderSide.none,
                  showCheckmark: false,
                ),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: valid ? 'Pay ${Fmt.naira(_value)}' : 'Enter an amount',
            icon: Icons.arrow_forward_rounded,
            onPressed: valid ? () => Navigator.pop(context, _value) : null,
          ),
        ],
      ),
    );
  }
}
