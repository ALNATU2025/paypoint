import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';

enum ButtonTone { primary, soft, light, dark, danger }

/// Pill-shaped 56px button used across the app.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.tone = ButtonTone.primary,
    this.loading = false,
    this.expand = true,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final ButtonTone tone;
  final bool loading;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final (Color bg, Color fg) = switch (tone) {
      ButtonTone.primary => (AppColors.blue, Colors.white),
      ButtonTone.soft => (AppColors.sky, AppColors.blue),
      ButtonTone.light => (Colors.white, AppColors.navy),
      ButtonTone.dark => (AppColors.navy2, Colors.white),
      ButtonTone.danger => (AppColors.dangerBg, AppColors.danger),
    };
    final effectiveBg = enabled || loading ? bg : const Color(0xFFDDE3F1);
    final effectiveFg = enabled || loading ? fg : AppColors.body;

    final child = loading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: effectiveFg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 19, color: effectiveFg), const SizedBox(width: 8)],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: effectiveFg),
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 10),
                Icon(trailingIcon, size: 19, color: effectiveFg),
              ],
            ],
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: height,
      width: expand ? double.infinity : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: tone == ButtonTone.primary && enabled ? AppShadows.button : null,
      ),
      child: Material(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(height / 2),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Center(widthFactor: 1, child: child),
          ),
        ),
      ),
    );
  }
}

/// 44px round icon button (back, close, notifications…).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.onDark = false,
    this.size = 44,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool onDark;
  final double size;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: onDark ? null : AppShadows.card,
        ),
        child: Material(
          color: onDark ? AppColors.navy2 : Colors.white,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 21, color: onDark ? Colors.white : AppColors.navy),
                if (badge)
                  Positioned(
                    top: size * 0.24,
                    right: size * 0.26,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
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

class BackRoundButton extends StatelessWidget {
  const BackRoundButton({super.key, this.onDark = false, this.onPressed, this.close = false});
  final bool onDark;
  final VoidCallback? onPressed;
  final bool close;

  @override
  Widget build(BuildContext context) => RoundIconButton(
        icon: close ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded,
        tooltip: close ? 'Close' : 'Back',
        onDark: onDark,
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      );
}

/// Back button + title row used at the top of flow screens.
class FlowHeader extends StatelessWidget {
  const FlowHeader({super.key, required this.title, this.trailing, this.onDark = false});
  final String title;
  final Widget? trailing;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BackRoundButton(onDark: onDark),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: onDark ? Colors.white : AppColors.ink,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Provider wordmark on its brand colour (text only — no third-party logos).
class ProviderBadge extends StatelessWidget {
  const ProviderBadge({
    super.key,
    required this.provider,
    this.width,
    this.height = 40,
    this.fontSize = 16,
    this.radius = 12,
    this.short = false,
  });

  final TvProvider provider;
  final double? width;
  final double height;
  final double fontSize;
  final double radius;
  final bool short;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: width == null ? const EdgeInsets.symmetric(horizontal: 12) : null,
      decoration: BoxDecoration(color: provider.color, borderRadius: BorderRadius.circular(radius)),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (provider.accentDot != null && !short) ...[
            Container(
              width: fontSize * 0.45,
              height: fontSize * 0.45,
              decoration: BoxDecoration(color: provider.accentDot, shape: BoxShape.circle),
            ),
            SizedBox(width: fontSize * 0.3),
          ],
          Flexible(
            child: Text(
              short ? provider.shortName : provider.name,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                fontStyle: provider.italicWordmark ? FontStyle.italic : FontStyle.normal,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// White rounded surface with the soft brand shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 20,
    this.color = Colors.white,
    this.onTap,
    this.border,
    this.shadow = AppShadows.card,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final VoidCallback? onTap;
  final BoxBorder? border;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: shadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// "Step 1 of 3 · Decoder details" + progress bar.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.step, required this.total, required this.label});
  final int step;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(text: 'Step $step of $total', style: const TextStyle(color: AppColors.blue)),
            TextSpan(text: '  ·  $label'),
          ]),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: step / total),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              minHeight: 6,
              color: AppColors.blue,
              backgroundColor: AppColors.border,
            ),
          ),
        ),
      ],
    );
  }
}

/// Label / value row used in summaries and receipts.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasis = false,
    this.divider = true,
    this.trailing,
    this.padding = 14,
    this.fontSize = 14,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasis;
  final bool divider;
  final Widget? trailing;
  final double padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: padding),
      decoration: BoxDecoration(
        border: divider ? const Border(bottom: BorderSide(color: AppColors.divider)) : null,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: emphasis ? fontSize + 1 : fontSize,
              color: emphasis ? AppColors.ink : AppColors.muted,
              fontWeight: emphasis ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: emphasis ? fontSize + 3 : fontSize,
                fontWeight: emphasis ? FontWeight.w800 : FontWeight.w700,
                color: valueColor ?? AppColors.ink,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class RadioDot extends StatelessWidget {
  const RadioDot({super.key, required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? AppColors.blue : const Color(0xFFC3CADB), width: 2),
      ),
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: selected ? 10 : 0,
        height: selected ? 10 : 0,
        decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
      ),
    );
  }
}

/// A selectable option card with a radio on the right/left.
class SelectTile extends StatelessWidget {
  const SelectTile({
    super.key,
    required this.selected,
    required this.onTap,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.radioFirst = false,
    this.enabled = true,
  });

  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool radioFirst;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: AppCard(
          onTap: enabled ? onTap : null,
          radius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: Border.all(color: selected ? AppColors.blue : Colors.transparent, width: 2),
          shadow: selected
              ? const [BoxShadow(color: Color(0x241840C8), blurRadius: 24, offset: Offset(0, 10))]
              : const [BoxShadow(color: Color(0x0D0B1A55), blurRadius: 12, offset: Offset(0, 4))],
          child: Row(
            children: [
              if (radioFirst) ...[RadioDot(selected: selected), const SizedBox(width: 14)],
              if (leading != null) ...[leading!, const SizedBox(width: 14)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(subtitle!,
                          style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
              if (!radioFirst) ...[const SizedBox(width: 10), RadioDot(selected: selected)],
            ],
          ),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.success, this.label});
  final bool success;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: success ? AppColors.successBg : AppColors.dangerBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label ?? (success ? 'Successful' : 'Failed · refunded'),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: success ? AppColors.success : AppColors.danger,
        ),
      ),
    );
  }
}

/// Soft tinted square holding an icon.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.size = 46,
    this.bg = AppColors.skySoft,
    this.fg = AppColors.blue,
    this.radius = 14,
    this.iconSize = 22,
  });

  final IconData icon;
  final double size;
  final Color bg;
  final Color fg;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(radius)),
        alignment: Alignment.center,
        child: Icon(icon, size: iconSize, color: fg),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.action, this.onAction, this.hint});
  final String text;
  final String? action;
  final VoidCallback? onAction;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
        if (hint != null)
          Text(hint!, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500)),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: AppColors.blue, minimumSize: const Size(44, 44)),
            child: Text(action!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}

/// Fake-toggle-free switch row.
class SwitchRow extends StatelessWidget {
  const SwitchRow({super.key, required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
