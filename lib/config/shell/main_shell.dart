import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/config/shell/shell_provider.dart';
import 'package:sponti/core/theme/app_colors.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    (
      icon: Icons.location_on_rounded,
      label: 'Spots',
      route: RouteName.location,
    ),
    (
      icon: Icons.explore_rounded,
      label: 'Discover',
      route: RouteName.discovery,
    ),
    (icon: Icons.map_rounded, label: 'Explore', route: RouteName.explore),
    (icon: Icons.bookmark_rounded, label: 'Saved', route: RouteName.favorites),
    (icon: Icons.person_rounded, label: 'Profile', route: RouteName.profile),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeTabProvider);

    return Scaffold(
      body: child,
      floatingActionButton: _SurpriseFab(
        onTap: () => context.push(RouteName.surprise),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _SpontiBottomBar(
        activeTab: activeTab,
        tabs: _tabs,
        onTap: (index) {
          ref.read(activeTabProvider.notifier).state = index;
          context.go(_tabs[index].route);
        },
      ),
    );
  }
}

class _SpontiBottomBar extends StatelessWidget {
  const _SpontiBottomBar({
    required this.activeTab,
    required this.tabs,
    required this.onTap,
  });

  final int activeTab;
  final List<({IconData icon, String label, String route})> tabs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: SpontiColors.outline)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              // Tabs 0, 1 — left of FAB
              ..._buildTabs(0, 2),
              // Gap for the centred FAB
              const SizedBox(width: 80),
              // Tabs 2, 3, 4 — right of FAB
              ..._buildTabs(2, 5),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTabs(int from, int to) => [
    for (int i = from; i < to; i++)
      Expanded(
        child: _NavItem(
          icon: tabs[i].icon,
          label: tabs[i].label,
          isActive: activeTab == i,
          onTap: () => onTap(i),
        ),
      ),
  ];
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? SpontiColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isActive ? SpontiColors.primary : SpontiColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              color: isActive ? SpontiColors.primary : SpontiColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SurpriseFab extends StatelessWidget {
  const _SurpriseFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [SpontiColors.primary, SpontiColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: SpontiColors.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.shuffle_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
