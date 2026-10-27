import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/paypoint_logo.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key, required this.tx});
  final TvTransaction tx;

  String get _shareText =>
      'Paypoint receipt\n${tx.provider.name} ${tx.package.name} · ${tx.months} month(s)\n'
      'Amount: ${Fmt.naira(tx.amount)}\n${tx.provider.idLabel}: ${Fmt.smartcard(tx.smartcard)}\n'
      'Reference: ${tx.reference}\nDate: ${Fmt.date(tx.date)}, ${Fmt.time(tx.date)}';

  void _toast(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: AuroraBackground(
          base: AppColors.navy,
          intensity: 0.35,
          child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  children: [
                    const FlowHeader(title: 'Transaction receipt', onDark: true),
                    const SizedBox(height: 26),
                    FadeSlideIn(
                      offset: const Offset(0, 80),
                      duration: const Duration(milliseconds: 700),
                      child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 40, offset: Offset(0, 20))],
                      ),
                      child: Stack(
                        children: [
                          const Positioned(
                            right: -30,
                            bottom: -30,
                            child: Opacity(opacity: 0.04, child: PaypointMark(size: 200)),
                          ),
                          Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                            child: Column(
                              children: [
                                const PaypointLockup(markSize: 26, fontSize: 17),
                                const SizedBox(height: 18),
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: tx.success
                                        ? AppGradients.success
                                        : tx.pending
                                            ? AppGradients.warm
                                            : null,
                                    color: tx.failed ? AppColors.danger : null,
                                    boxShadow: const [BoxShadow(color: Color(0x401E9A3E), blurRadius: 16, offset: Offset(0, 6))],
                                  ),
                                  alignment: Alignment.center,
                                  child: tx.success
                                      ? const DrawnCheck(size: 32, strokeWidth: 4, delay: Duration(milliseconds: 500))
                                      : Icon(tx.pending ? Icons.schedule_rounded : Icons.close_rounded,
                                          color: Colors.white, size: 28),
                                ),
                                const SizedBox(height: 14),
                                AnimatedAmount(
                                  value: tx.amount.toDouble(),
                                  format: (v) => Fmt.naira(v, kobo: true),
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1),
                                ),
                                const SizedBox(height: 8),
                                StatusPill(success: tx.success, pending: tx.pending),
                              ],
                            ),
                          ),
                          const _TicketDivider(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
                            child: Column(
                              children: [
                                InfoRow(label: 'Provider', value: tx.provider.name, divider: false, padding: 10, fontSize: 13),
                                InfoRow(
                                  label: 'Package',
                                  value: '${tx.package.name} · ${tx.months} month${tx.months == 1 ? '' : 's'}',
                                  divider: false,
                                  padding: 10,
                                  fontSize: 13,
                                ),
                                InfoRow(label: 'Account name', value: tx.accountName.isEmpty ? '—' : tx.accountName, divider: false, padding: 10, fontSize: 13),
                                InfoRow(
                                  label: tx.provider.idLabel.replaceAll(' number', ''),
                                  value: Fmt.smartcard(tx.smartcard),
                                  divider: false,
                                  padding: 10,
                                  fontSize: 13,
                                ),
                                InfoRow(label: 'Paid with', value: tx.method.title, divider: false, padding: 10, fontSize: 13),
                                InfoRow(
                                  label: 'Date',
                                  value: '${Fmt.date(tx.date)}, ${Fmt.time(tx.date)}',
                                  divider: false,
                                  padding: 10,
                                  fontSize: 13,
                                ),
                                InfoRow(
                                  label: 'Active until',
                                  value: tx.success ? '~ ${Fmt.date(tx.activeUntil)}' : '—',
                                  divider: false,
                                  padding: 10,
                                  fontSize: 13,
                                ),
                                InfoRow(
                                  label: 'Reference',
                                  value: tx.reference,
                                  divider: false,
                                  padding: 6,
                                  fontSize: 13,
                                  trailing: IconButton.filledTonal(
                                    tooltip: 'Copy reference',
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: tx.reference));
                                      _toast(context, 'Reference copied');
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.skySoft,
                                      foregroundColor: AppColors.blue,
                                    ),
                                    icon: const Icon(Icons.copy_rounded, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                        ],
                      ),
                    ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Download',
                        icon: Icons.download_rounded,
                        tone: ButtonTone.dark,
                        // Hook up a PDF package (e.g. `pdf` + `printing`) to generate the file.
                        onPressed: () => _toast(context, 'Receipt saved'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Share',
                        icon: Icons.share_rounded,
                        tone: ButtonTone.light,
                        // Swap for `share_plus` to open the native share sheet.
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _shareText));
                          _toast(context, 'Receipt details copied to share');
                        },
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

/// Dashed line with punched notches, like a ticket stub.
class _TicketDivider extends StatelessWidget {
  const _TicketDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            left: 20,
            right: 20,
            child: CustomPaint(painter: _DashPainter()),
          ),
          const Positioned(left: -12, top: 0, child: _Notch()),
          const Positioned(right: -12, top: 0, child: _Notch()),
        ],
      ),
    );
  }
}

class _Notch extends StatelessWidget {
  const _Notch();
  @override
  Widget build(BuildContext context) => Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(color: AppColors.navy, shape: BoxShape.circle),
      );
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDDE3F1)
      ..strokeWidth = 2;
    final y = size.height / 2;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, y), Offset(x + 5, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
