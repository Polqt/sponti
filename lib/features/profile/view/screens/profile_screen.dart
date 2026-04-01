import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/config/shell/shell_provider.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_empty_state.dart';
import 'package:sponti/core/widgets/app_shimmer.dart';
import 'package:sponti/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:sponti/features/profile/model/user_profile.dart';
import 'package:sponti/features/profile/view/widgets/profile_header.dart';
import 'package:sponti/features/profile/view/widgets/profile_photo_picker.dart';
import 'package:sponti/features/profile/view/widgets/profile_stats_card.dart';
import 'package:sponti/features/profile/viewmodel/profile_viewmodel.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(currentUserProvider);
    final viewedUserId = userId ?? authUser?.id;
    final isOwnProfile = viewedUserId != null && viewedUserId == authUser?.id;

    final profileAsync = viewedUserId == null || viewedUserId.isEmpty
        ? const AsyncValue<UserProfile?>.data(null)
        : isOwnProfile
            ? ref.watch(profileProvider)
            : ref.watch(userProfileProvider(viewedUserId));

    final statsAsync = viewedUserId == null || viewedUserId.isEmpty
        ? const AsyncValue<UserStats?>.data(null)
        : ref.watch(userStatsProvider(viewedUserId));

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      body: profileAsync.when(
        loading: () => const _ProfileShimmer(),
        error: (_, _) => AppErrorState(
          message: 'Could not load profile.',
          onRetry: () => _refreshProfile(ref, viewedUserId, isOwnProfile),
        ),
        data: (profile) {
          if (profile == null) {
            return AppErrorState(
              message: 'Profile not found.',
              onRetry: () => _refreshProfile(ref, viewedUserId, isOwnProfile),
            );
          }
          return _ProfileBody(
            profile: _mergeStats(profile, statsAsync.valueOrNull),
            isOwnProfile: isOwnProfile,
            onAvatarTap: isOwnProfile && authUser != null
                ? () => _pickAndUploadPhoto(context, ref, authUser.id)
                : null,
          );
        },
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    required this.isOwnProfile,
    required this.onAvatarTap,
  });

  final UserProfile profile;
  final bool isOwnProfile;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final dockBottomInset = bottomInset > 0 ? bottomInset : 6.0;
    final bottomPadding = kShellBottomBarHeight + dockBottomInset;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (!isOwnProfile)
          SliverAppBar(
            backgroundColor: SpontiColors.surface,
            elevation: 0,
            pinned: false,
            title: const Text('Profile'),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Column(
              children: [
                const SizedBox(height: 12),
                _FadeSlideIn(
                  delay: Duration.zero,
                  child: ProfileHeader(profile: profile, onAvatarTap: onAvatarTap),
                ),
                const SizedBox(height: 20),
                _FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: ProfileStatsCard(profile: profile),
                ),
                if (isOwnProfile) ...[
                  const SizedBox(height: 32),
                  _FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: _ProfileMenuSection(
                      title: 'My Activity',
                      items: _activityItems(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _FadeSlideIn(
                    delay: const Duration(milliseconds: 300),
                    child: Consumer(
                      builder: (context, ref, _) => _ProfileMenuSection(
                        title: 'Settings',
                        items: _settingsItems(context, ref),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<_MenuItemData> _activityItems(BuildContext context) => [
        _MenuItemData(
          icon: Icons.location_on_rounded,
          iconColor: SpontiColors.primary,
          label: 'My Check-ins',
          onTap: () => context.push(RouteName.myCheckIns),
        ),
        _MenuItemData(
          icon: Icons.bookmark_rounded,
          iconColor: SpontiColors.primary,
          label: 'Saved Spots',
          onTap: () => context.go(RouteName.favorites),
        ),
        _MenuItemData(
          icon: Icons.add_location_alt_rounded,
          iconColor: SpontiColors.secondary,
          label: 'Suggested Spots',
          onTap: () => context.push(RouteName.suggestSpot),
        ),
      ];

  List<_MenuItemData> _settingsItems(BuildContext context, WidgetRef ref) => [
        _MenuItemData(
          icon: Icons.edit_rounded,
          iconColor: SpontiColors.secondary,
          label: 'Edit Profile',
          onTap: () => context.push(RouteName.editProfile),
        ),
        _MenuItemData(
          icon: Icons.logout_rounded,
          iconColor: SpontiColors.error,
          label: 'Sign Out',
          onTap: () => _confirmSignOut(context, ref),
        ),
      ];
}

// ── Menu section ──────────────────────────────────────────────────────────────

class _ProfileMenuSection extends StatelessWidget {
  const _ProfileMenuSection({required this.title, required this.items});

  final String title;
  final List<_MenuItemData> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: SpontiColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: SpontiColors.shadow.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _MenuTile(item: items[i]),
                  if (i < items.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 0,
                      endIndent: 0,
                      color: SpontiColors.outline.withValues(alpha: 0.3),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItemData {
  const _MenuItemData({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item});

  final _MenuItemData item;

  @override
  Widget build(BuildContext context) {
    final color = item.iconColor ?? SpontiColors.primary;
    return InkWell(
      onTap: item.onTap,
      splashColor: color.withValues(alpha: 0.05),
      highlightColor: color.withValues(alpha: 0.02),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(item.icon, size: 24, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: SpontiColors.textMuted.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fade + slide animation ────────────────────────────────────────────────────

class _FadeSlideIn extends StatefulWidget {
  const _FadeSlideIn({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    duration: const Duration(milliseconds: 600),
    vsync: this,
  );

  late final Animation<double> _opacity = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.15),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _opacity,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

// ── Shimmer ───────────────────────────────────────────────────────────────────

class _ProfileShimmer extends StatelessWidget {
  const _ProfileShimmer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Center(child: AppShimmer.circle(size: 96)),
          const SizedBox(height: 16),
          Center(child: AppShimmer(height: 20, width: 160)),
          const SizedBox(height: 8),
          Center(child: AppShimmer(height: 14, width: 100)),
          const SizedBox(height: 24),
          AppShimmer(height: 76, borderRadius: 16),
          const SizedBox(height: 28),
          for (int i = 0; i < 5; i++) ...[
            AppShimmer(height: 56, borderRadius: 14),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

UserProfile _mergeStats(UserProfile profile, UserStats? stats) {
  if (stats == null) return profile;
  return profile.copyWith(
    checkInCount: stats.checkInCount,
    favoritesCount: stats.favoritesCount,
    spotsSuggested: stats.spotsSuggested,
  );
}

void _refreshProfile(WidgetRef ref, String? userId, bool isOwnProfile) {
  if (isOwnProfile) {
    ref.invalidate(profileProvider);
  } else if (userId != null && userId.isNotEmpty) {
    ref.invalidate(userProfileProvider(userId));
  }
  if (userId != null && userId.isNotEmpty) {
    ref.invalidate(userStatsProvider(userId));
  }
}

Future<void> _pickAndUploadPhoto(
  BuildContext context,
  WidgetRef ref,
  String userId,
) async {
  final picked = await ProfilePhotoPicker.show(context);
  if (picked == null) return;

  final errorMessage = await ref.read(profileProvider.notifier).uploadPhoto(
    userId: userId,
    bytes: picked.bytes,
    extension: picked.extension,
    contentType: picked.contentType,
  );

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(errorMessage ?? 'Profile photo updated successfully.'),
    ),
  );
}

Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Sign Out',
                style: TextStyle(color: SpontiColors.error),
              ),
            ),
          ],
        ),
      ) ??
      false;

  if (!confirmed || !context.mounted) return;

  final signedOut = await ref.read(authProvider.notifier).signOut();
  if (!context.mounted) return;

  if (!signedOut) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign out failed. Please try again.')),
    );
    return;
  }

  ref.invalidate(authProvider);
  ref.invalidate(profileProvider);
  context.go(RouteName.signin);
}
