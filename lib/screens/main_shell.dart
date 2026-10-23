import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../data/catalog.dart';
import '../state/app_state.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// Bottom-navigation shell: Home · Pay TV · History · Profile.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialTab = 0});

  /// 0 = Home, 1 = History, 2 = Profile.
  final int initialTab;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _tab = widget.initialTab;

  void go(int tab) => setState(() => _tab = tab);

  void _payTv() {
    AppScope.read(context).startFlow(Catalog.dstv);
    Navigator.of(context).pushNamed(Routes.smartcard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(onOpenHistory: () => go(1), onOpenProfile: () => go(2)),
          const HistoryScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        current: _tab,
        onHome: () => go(0),
        onPay: _payTv,
        onHistory: () => go(1),
        onProfile: () => go(2),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.current,
    required this.onHome,
    required this.onPay,
    required this.onHistory,
    required this.onProfile,
  });

  final int current;
  final VoidCallback onHome;
  final VoidCallback onPay;
  final VoidCallback onHistory;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE6EAF3))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Home', active: current == 0, onTap: onHome),
              _NavItem(icon: Icons.tv_rounded, label: 'Pay TV', active: false, onTap: onPay),
              _NavItem(icon: Icons.schedule_rounded, label: 'History', active: current == 1, onTap: onHistory),
              _NavItem(icon: Icons.person_outline_rounded, label: 'Profile', active: current == 2, onTap: onProfile),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.blue : AppColors.muted;
    return Expanded(
      child: Semantics(
        selected: active,
        button: true,
        child: InkResponse(
          onTap: onTap,
          radius: 36,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                decoration: BoxDecoration(
                  color: active ? AppColors.skySoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
