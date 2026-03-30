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
    final width = MediaQuery.sizeOf(context).width;
    final isLargeScreen = width >= 840;
    final horizontalMargin = isLargeScreen ? 24.0 : 12.0;

    return SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(horizontalMargin, 0, horizontalMargin, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 78,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F6F1).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
                Expanded(
                  flex: 2,
                  child: _CenterSurpriseButton(onTap: onTapSurprise),
                ),
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
    return Flexible(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        splashColor: SpontiColors.textPrimary.withValues(alpha: 0.06),
        highlightColor: SpontiColors.textPrimary.withValues(alpha: 0.03),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: isActive ? 44 : 40,
            height: isActive ? 44 : 40,
            decoration: BoxDecoration(
              color: isActive
                  ? SpontiColors.textPrimary.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                size: isActive ? 26 : 24,
                color: isActive
                    ? SpontiColors.textPrimary
                    : SpontiColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterSurpriseButton extends StatefulWidget {
  const _CenterSurpriseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CenterSurpriseButton> createState() => _CenterSurpriseButtonState();
}

class _CenterSurpriseButtonState extends State<_CenterSurpriseButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: _isPressed ? 0.96 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [SpontiColors.primary, SpontiColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: SpontiColors.primary.withValues(alpha: _isPressed ? 0.3 : 0.4),
                  blurRadius: _isPressed ? 8 : 14,
                  offset: Offset(0, _isPressed ? 3 : 6),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 17, color: Colors.white),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'surprise me',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
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
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Flexible(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        splashColor: SpontiColors.primary.withValues(alpha: 0.08),
        highlightColor: SpontiColors.primary.withValues(alpha: 0.04),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: isActive ? 38 : 34,
            height: isActive ? 38 : 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? SpontiColors.primary : SpontiColors.outline,
                width: isActive ? 2.5 : 1.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: SpontiColors.primary.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: ClipOval(
              child: hasAvatar
                  ? Image.network(
                      avatarUrl!,
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
