import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../data/catalog.dart';
import '../state/app_state.dart';
import '../widgets/motion.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// Space tab content must leave at the bottom for the floating nav bar.
const double kFloatingNavClearance = 118;

/// Shell with a floating glass navigation bar: Home · History · Profile,
/// plus a raised gradient "Pay TV" action.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialTab = 0});

  /// 0 = Home, 1 = History, 2 = Profile.
  final int initialTab;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _tab = widget.initialTab;

  void go(int tab) {
    if (tab == _tab) return;
    HapticFeedback.selectionClick();
    setState(() => _tab = tab);
  }

  void _payTv() {
    HapticFeedback.mediumImpact();
    AppScope.read(context).startFlow(Catalog.dstv);
    Navigator.of(context).pushNamed(Routes.smartcard);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onOpenHistory: () => go(1), onOpenProfile: () => go(2)),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 360),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(a),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(_tab), child: pages[_tab]),
      ),
      bottomNavigationBar: _FloatingNav(current: _tab, onTab: go, onPay: _payTv),
    );
  }
}

class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.current, required this.onTab, required this.onPay});

  final int current;
  final ValueChanged<int> onTab;
  final VoidCallback onPay;

  static const _items = [
    (Icons.home_rounded, Icons.home_outlined, 'Home'),
    (Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'History'),
    (Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 12),
      child: SizedBox(
        height: 72,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [BoxShadow(color: Color(0x240B1A55), blurRadius: 34, offset: Offset(0, 14))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Stack(
                        children: [
                          // Sliding highlight pill.
                          AnimatedAlign(
                            alignment: Alignment(-1 + current * 1.0, 0),
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.easeOutBack,
                            child: FractionallySizedBox(
                              widthFactor: 1 / _items.length,
                              heightFactor: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.skySoft,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              for (var i = 0; i < _items.length; i++)
                                Expanded(
                                  child: _NavItem(
                                    active: current == i,
                                    icon: _items[i].$1,
                                    iconOff: _items[i].$2,
                                    label: _items[i].$3,
                                    onTap: () => onTab(i),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _PayButton(onTap: onPay),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.active,
    required this.icon,
    required this.iconOff,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final IconData icon;
  final IconData iconOff;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.blue : AppColors.muted;
    return Semantics(
      selected: active,
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: PressScale(
          scale: 0.9,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: Icon(active ? icon : iconOff, key: ValueKey(active), size: 23, color: color),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: DefaultTextStyle.of(context).style.copyWith(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      color: color,
                    ),
                child: Text(label, excludeFromSemantics: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Raised gradient action with a soft breathing glow.
class _PayButton extends StatelessWidget {
  const _PayButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Pay for cable TV',
      child: PressScale(
        scale: 0.9,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: AppGradients.primary,
            border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
            boxShadow: const [BoxShadow(color: Color(0x661840C8), blurRadius: 28, offset: Offset(0, 12))],
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: BorderRadius.circular(26),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: const ShimmerSweep(
                opacity: 0.25,
                child: SizedBox.expand(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.live_tv_rounded, color: Colors.white, size: 24),
                      SizedBox(height: 3),
                      Text('Pay TV',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                    ],
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
