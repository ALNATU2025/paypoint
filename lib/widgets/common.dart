import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../models/models.dart';
import 'motion.dart';

enum ButtonTone { primary, soft, light, dark, danger }

/// Pill-shaped button used across the app. The primary tone is a brand
/// gradient with a glow and an optional shimmer; every tone scales on press.
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
    this.shimmer = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final ButtonTone tone;
  final bool loading;
  final bool expand;
  final double height;

  /// A light sweep across the button — use on the one key action per screen.
  final bool shimmer;

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
    final live = enabled || loading;
    final effectiveFg = live ? fg : AppColors.body;
    final radius = BorderRadius.circular(height / 2);
    final gradient = tone == ButtonTone.primary && live ? AppGradients.primary : null;

    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (c, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: a, child: c)),
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: effectiveFg),
            )
          : Row(
              key: ValueKey(label),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 19, color: effectiveFg), const SizedBox(width: 8)],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: effectiveFg, letterSpacing: 0.1),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 10),
                  Icon(trailingIcon, size: 19, color: effectiveFg),
                ],
              ],
            ),
    );

    Widget button = AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      height: height,
      width: expand ? double.infinity : null,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: gradient == null ? (live ? bg : const Color(0xFFDDE3F1)) : null,
        gradient: gradient,
        boxShadow: tone == ButtonTone.primary && enabled ? AppShadows.button : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                }
              : null,
          splashColor: Colors.white.withValues(alpha: 0.12),
          highlightColor: Colors.white.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Center(widthFactor: 1, child: content),
          ),
        ),
      ),
    );

    if (shimmer && enabled) {
      button = ClipRRect(borderRadius: radius, child: ShimmerSweep(opacity: 0.22, child: button));
      // Keep the glow outside the clip.
      button = DecoratedBox(decoration: BoxDecoration(borderRadius: radius, boxShadow: AppShadows.button), child: button);
    }

    return PressScale(enabled: enabled, child: button);
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
      child: PressScale(
        scale: 0.9,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: onDark ? null : AppShadows.card,
            border: onDark ? Border.all(color: Colors.white.withValues(alpha: 0.14)) : null,
          ),
          child: Material(
            color: onDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, size: 20, color: onDark ? Colors.white : AppColors.navy),
                  if (badge)
                    Positioned(
                      top: size * 0.2,
                      right: size * 0.2,
                      child: const PulseDot(size: 7),
                    ),
                ],
              ),
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
    return FadeSlideIn(
      offset: const Offset(0, -10),
      duration: const Duration(milliseconds: 420),
      child: Row(
        children: [
          BackRoundButton(onDark: onDark),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: onDark ? Colors.white : AppColors.ink,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Provider wordmark on its brand gradient (text only — no third-party logos).
class ProviderBadge extends StatelessWidget {
  const ProviderBadge({
    super.key,
    required this.provider,
    this.width,
    this.height = 40,
    this.fontSize = 16,
    this.radius = 12,
    this.short = false,
    this.glow = false,
  });

  final TvProvider provider;
  final double? width;
  final double height;
  final double fontSize;
  final double radius;
  final bool short;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: width == null ? const EdgeInsets.symmetric(horizontal: 12) : null,
      decoration: BoxDecoration(
        gradient: AppGradients.of(provider.color),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: glow
            ? [BoxShadow(color: provider.color.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 8))]
            : null,
      ),
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

/// White rounded surface with the soft brand shadow. Tappable cards scale on press.
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
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final VoidCallback? onTap;
  final BoxBorder? border;
  final List<BoxShadow>? shadow;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: shadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return onTap == null ? card : PressScale(scale: 0.975, child: card);
  }
}

/// "Step 1 of 3 · Decoder details" + animated segmented progress.
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
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.2),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 1; i <= total; i++) ...[
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(3)),
                  alignment: Alignment.centerLeft,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: i < step ? 1.0 : 0.0, end: i <= step ? 1.0 : 0.0),
                    duration: Duration(milliseconds: i == step ? 650 : 0),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => FractionallySizedBox(
                      widthFactor: v,
                      heightFactor: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppGradients.selectedBorder,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: v > 0
                              ? const [BoxShadow(color: Color(0x553B6CFF), blurRadius: 8, offset: Offset(0, 2))]
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (i < total) const SizedBox(width: 6),
            ],
          ],
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

/// Radio that fills with a gradient and a check when selected.
class RadioDot extends StatelessWidget {
  const RadioDot({super.key, required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: selected ? AppGradients.selectedBorder : null,
        border: selected ? null : Border.all(color: const Color(0xFFC3CADB), width: 2),
        boxShadow: selected ? const [BoxShadow(color: Color(0x553B6CFF), blurRadius: 10, offset: Offset(0, 3))] : null,
      ),
      alignment: Alignment.center,
      child: AnimatedScale(
        scale: selected ? 1 : 0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        child: const Icon(Icons.check_rounded, size: 15, color: Colors.white),
      ),
    );
  }
}

/// A selectable option card. Selected = gradient outline, tinted fill, glow.
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
    this.badge,
  });

  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool radioFirst;
  final bool enabled;

  /// Small label shown next to the title (e.g. "Popular").
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Semantics(
      selected: selected,
      button: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: PressScale(
          scale: 0.98,
          enabled: enabled,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: selected ? AppGradients.selectedBorder : null,
              color: selected ? null : Colors.white,
              boxShadow: selected
                  ? const [BoxShadow(color: Color(0x2E1840C8), blurRadius: 26, offset: Offset(0, 12))]
                  : const [BoxShadow(color: Color(0x0D0B1A55), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFF7F9FF) : Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Material(
                type: MaterialType.transparency,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: enabled
                      ? () {
                          HapticFeedback.selectionClick();
                          onTap();
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    child: Row(
                      children: [
                        if (radioFirst) ...[RadioDot(selected: selected), const SizedBox(width: 14)],
                        if (leading != null) ...[leading!, const SizedBox(width: 14)],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(title,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                                  ),
                                  if (badge != null) ...[const SizedBox(width: 8), GradientTag(badge!)],
                                ],
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 3),
                                Text(subtitle!,
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500)),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small gradient label, e.g. "Popular".
class GradientTag extends StatelessWidget {
  const GradientTag(this.text, {super.key, this.gradient = AppGradients.warm, this.textColor = AppColors.ink});
  final String text;
  final Gradient gradient;
  final Color textColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(8)),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: textColor),
        ),
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.success, this.label});
  final bool success;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final color = success ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: success ? AppColors.successBg : AppColors.dangerBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(
            label ?? (success ? 'Successful' : 'Failed · refunded'),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

/// Soft tinted square holding an icon. With [active] it switches to the brand gradient.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.size = 46,
    this.bg = AppColors.skySoft,
    this.fg = AppColors.blue,
    this.radius = 14,
    this.iconSize = 22,
    this.active = false,
  });

  final IconData icon;
  final double size;
  final Color bg;
  final Color fg;
  final double radius;
  final double iconSize;
  final bool active;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: active ? null : bg,
          gradient: active ? AppGradients.primary : null,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: active ? AppShadows.glowBlue : null,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: iconSize, color: active ? Colors.white : fg),
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
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
        ),
        if (hint != null)
          Text(hint!, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500)),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: AppColors.blue, minimumSize: const Size(44, 44)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(action!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
      ],
    );
  }
}

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

/// Circular "days left" ring used on saved decoders.
class DaysRing extends StatelessWidget {
  const DaysRing({super.key, required this.daysLeft, this.period = 30, this.size = 46, required this.child});
  final int daysLeft;
  final int period;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final frac = (daysLeft / period).clamp(0.0, 1.0);
    final soon = daysLeft <= 5;
    return SizedBox(
      width: size + 10,
      height: size + 10,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: frac),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => SizedBox(
              width: size + 10,
              height: size + 10,
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: 3,
                strokeCap: StrokeCap.round,
                backgroundColor: AppColors.divider,
                color: soon ? AppColors.orange : AppColors.successStrong,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
