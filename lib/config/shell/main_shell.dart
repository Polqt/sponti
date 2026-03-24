import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/config/shell/shell_provider.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:sponti/features/locations/view/screens/surprise_me_modal.dart';
import 'package:sponti/features/profile/viewmodel/profile_viewmodel.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = GoRouterState.of(context).matchedLocation;
    final activeIndex = _resolveActiveIndex(route);
    ref.watch(shellChromeProgressProvider).clamp(0.0, 1.0);
    final isBarHidden = ref.watch(shellBarHiddenProvider);

    if (activeIndex != null) {
      final tabState = ref.watch(activeTabProvider);
      if (tabState != activeIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(activeTabProvider.notifier).state = activeIndex;
        });
      }
    }

    final authUser = ref.watch(currentUserProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final avatarUrl = profile?.avatarUrl ?? authUser?.avatarUrl;

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
        offset: isBarHidden ? const Offset(0, 1.5) : Offset.zero,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: isBarHidden ? 0.0 : 1.0,
          child: _SpontiBottomBar(
            activeRoute: route,
            avatarUrl: avatarUrl,
            onTapExplore: () => context.go(RouteName.discovery),
            onTapMap: () => context.go(RouteName.location),
            onTapSurprise: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const SurpriseMeModal(),
              );
            },
            onTapSaved: () => context.go(RouteName.favorites),
            onTapProfile: () => context.go(RouteName.profile),
          ),
        ),
      ),
    );
  }

  int? _resolveActiveIndex(String route) {
    if (route.startsWith(RouteName.discovery)) return 0;
    if (route.startsWith(RouteName.location)) return 1;
    if (route.startsWith(RouteName.favorites)) return 2;
    if (route.startsWith(RouteName.profile)) return 3;
    return null;
  }
}

class _SpontiBottomBar extends StatelessWidget {
  const _SpontiBottomBar({
    required this.activeRoute,
    required this.avatarUrl,
    required this.onTapExplore,
    required this.onTapMap,
    required this.onTapSurprise,
    required this.onTapSaved,
    required this.onTapProfile,
  });

  final String activeRoute;
  final String? avatarUrl;
  final VoidCallback onTapExplore;
  final VoidCallback onTapMap;
  final VoidCallback onTapSurprise;
  final VoidCallback onTapSaved;
  final VoidCallback onTapProfile;

  bool get _isExploreActive => activeRoute.startsWith(RouteName.discovery);
  bool get _isMapActive => activeRoute.startsWith(RouteName.location);
  bool get _isSavedActive => activeRoute.startsWith(RouteName.favorites);
  bool get _isProfileActive => activeRoute.startsWith(RouteName.profile);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 78,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F6F1).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _TabIcon(
                  icon: Icons.groups_2_outlined,
                  activeIcon: Icons.groups_2_rounded,
                  isActive: _isExploreActive,
                  onTap: onTapExplore,
                ),
                _TabIcon(
                  icon: Icons.map_outlined,
                  activeIcon: Icons.map_rounded,
                  isActive: _isMapActive,
                  onTap: onTapMap,
                ),
                Expanded(child: _CenterSurpriseButton(onTap: onTapSurprise)),
                _TabIcon(
                  icon: Icons.local_offer_outlined,
                  activeIcon: Icons.local_offer_rounded,
                  isActive: _isSavedActive,
                  onTap: onTapSaved,
                ),
                _ProfileTab(
                  avatarUrl: avatarUrl,
                  isActive: _isProfileActive,
                  onTap: onTapProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabIcon extends StatelessWidget {
  const _TabIcon({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive
                  ? SpontiColors.textPrimary.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive
                  ? SpontiColors.textPrimary
                  : SpontiColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterSurpriseButton extends StatelessWidget {
  const _CenterSurpriseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [SpontiColors.primary, SpontiColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: SpontiColors.primary.withValues(alpha: 0.45),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'surprise me',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.avatarUrl,
    required this.isActive,
    required this.onTap,
  });

  final String? avatarUrl;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = avatarUrl;
    final hasAvatar = avatar != null && avatar.isNotEmpty;

    return SizedBox(
      width: 52,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: isActive ? 36 : 32,
            height: isActive ? 36 : 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? SpontiColors.primary : SpontiColors.outline,
                width: isActive ? 2.2 : 1.4,
              ),
            ),
            child: ClipOval(
              child: hasAvatar
                  ? Image.network(
                      avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _avatarFallback(),
                    )
                  : _avatarFallback(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: SpontiColors.surfaceVariant,
      child: const Icon(
        Icons.person_rounded,
        size: 18,
        color: SpontiColors.textMuted,
      ),
    );
  }
}
