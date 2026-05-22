import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app_theme.dart';
import 'habit_provider.dart';
import 'notification_provider.dart';
import 'home_screen.dart';
import 'habit_screen.dart';
import 'report_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _navCtrl;

  static const _navItems = [
    _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home'),
    _NavItem(
        icon: Icons.track_changes_outlined,
        activeIcon: Icons.track_changes_rounded,
        label: 'Habits'),
    _NavItem(
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
        label: 'Reports'),
    _NavItem(
        icon: Icons.notifications_none_rounded,
        activeIcon: Icons.notifications_rounded,
        label: 'Alerts'),
    _NavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile'),
  ];

  static const _pages = [
    HomeScreen(),
    HabitsScreen(),
    ReportsScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _navCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Sync notifications with locally stored habits on every startup
      final habits = ref.read(habitProvider).habits;
      ref.read(notificationProvider.notifier).syncWithHabits(habits);
      if (await Permission.notification.isDenied)
        await Permission.notification.request();
      if (await Permission.scheduleExactAlarm.isDenied)
        await Permission.scheduleExactAlarm.request();
    });
  }

  @override
  void dispose() {
    _navCtrl.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    _navCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, dynamic result) {
        if (didPop) return;
        _onTabTap(0);
      },
      child: Scaffold(
        extendBody: true,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutQuad),
            child: SlideTransition(
              position:
                  Tween<Offset>(begin: const Offset(0.02, 0), end: Offset.zero)
                      .animate(anim),
              child: child,
            ),
          ),
          child: KeyedSubtree(
              key: ValueKey(_selectedIndex), child: _pages[_selectedIndex]),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark.withOpacity(0.7)
                        : Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                        color: Colors.white.withOpacity(isDark ? 0.05 : 0.6),
                        width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: isDark
                              ? Colors.black38
                              : AppColors.primary.withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10))
                    ]),
                child: Row(
                  children: List.generate(_navItems.length, (i) {
                    final item = _navItems[i];
                    final selected = i == _selectedIndex;
                    return Expanded(
                      child: _NavBarItem(
                          item: item,
                          selected: selected,
                          onTap: () => _onTabTap(i)),
                    );
                  }),
                ),
              ),
            ),
          )
              .animate()
              .slideY(begin: 1, duration: 800.ms, curve: Curves.easeOutExpo),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(
      {required this.icon, required this.activeIcon, required this.label});
}

class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavBarItem(
      {required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final inactColor = isDark ? Colors.white38 : AppColors.textLight;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 40,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color:
                    selected ? actColor.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                selected ? item.activeIcon : item.icon,
                color: selected ? actColor : inactColor,
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? actColor : inactColor,
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}
