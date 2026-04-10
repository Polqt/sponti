import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/config/shell/shell_provider.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_empty_state.dart';
import 'package:sponti/core/widgets/fade_slide_in.dart';
import 'package:sponti/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:sponti/features/friends/view/widgets/add_friend_button.dart';
import 'package:sponti/features/profile/model/user_profile.dart';
import 'package:sponti/features/profile/view/widgets/profile_header.dart';
import 'package:sponti/features/profile/view/widgets/profile_menu_section.dart';
import 'package:sponti/features/profile/view/widgets/profile_photo_picker.dart';
import 'package:sponti/features/profile/view/widgets/profile_shimmer.dart';
import 'package:sponti/features/profile/view/widgets/profile_stats_card.dart';
import 'package:sponti/features/profile/view/widgets/sign_out_dialog.dart';
import 'package:sponti/features/profile/viewmodel/profile_viewmodel.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(currentUserProvider);
    final viewingOwnProfile = userId == null;
    if (viewingOwnProfile && authUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go(RouteName.signin);
      });
      return const Scaffold(
        backgroundColor: SpontiColors.surface,
        body: SizedBox.shrink(),
      );
    }

    final viewedUserId = userId ?? authUser?.id;
    final isOwnProfile = viewedUserId != null && viewedUserId == authUser?.id;

    final profileAsync = _watchProfile(ref, viewedUserId, isOwnProfile);
    final statsAsync = _watchStats(ref, viewedUserId);

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      body: profileAsync.when(
        loading: () => const ProfileShimmer(),
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

  AsyncValue<UserProfile?> _watchProfile(
    WidgetRef ref,
    String? viewedUserId,
    bool isOwnProfile,
  ) {
    if (viewedUserId == null || viewedUserId.isEmpty) {
      return const AsyncValue<UserProfile?>.data(null);
    }
    return isOwnProfile
        ? ref.watch(profileProvider)
        : ref.watch(userProfileProvider(viewedUserId));
  }

  AsyncValue<UserStats?> _watchStats(WidgetRef ref, String? viewedUserId) {
    if (viewedUserId == null || viewedUserId.isEmpty) {
      return const AsyncValue<UserStats?>.data(null);
    }
    return ref.watch(userStatsProvider(viewedUserId));
  }
}

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
    // Match the bottom bar's dynamic height calculation
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final dockBottomInset = bottomInset > 0 ? bottomInset : 6.0;
    final bottomPadding = kShellBottomBarHeight + dockBottomInset;

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        if (!isOwnProfile)
          SliverAppBar(
            backgroundColor: SpontiColors.surface,
            elevation: 0,
            pinned: true,
            title: Text(
              profile.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (isOwnProfile)
          // Transparent pinned app bar — zero height, just occupies the status bar
          // so content can never scroll behind it.
          SliverAppBar(
            backgroundColor: SpontiColors.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            pinned: true,
            toolbarHeight: 0,
            automaticallyImplyLeading: false,
          ),
        if (isOwnProfile)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: 16,
                bottom: bottomPadding,
              ),
              child: Column(
                children: [
                  FadeSlideIn(
                    child: ProfileHeader(
                      profile: profile,
                      onAvatarTap: onAvatarTap,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: ProfileStatsCard(profile: profile),
                  ),
                  const SizedBox(height: 32),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: ProfileMenuSection(
                      title: 'My Activity',
                      items: _activityItems(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 300),
                    child: Consumer(
                      builder: (context, ref, _) => ProfileMenuSection(
                        title: 'Settings',
                        items: _settingsItems(context, ref),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          // Other profile: top-aligned, scrollable
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, 24, 0, bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FadeSlideIn(
                    child: ProfileHeader(
                      profile: profile,
                      onAvatarTap: null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: ProfileStatsCard(profile: profile),
                  ),
                  const SizedBox(height: 20),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 150),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: AddFriendButton(userId: profile.id),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  List<ProfileMenuItem> _activityItems(BuildContext context) => [
    ProfileMenuItem(
      icon: Icons.people_rounded,
      iconColor: SpontiColors.secondary,
      label: 'Friends',
      onTap: () => context.push(RouteName.friends),
    ),
    ProfileMenuItem(
      icon: Icons.location_on_rounded,
      iconColor: SpontiColors.primary,
      label: 'My Check-ins',
      onTap: () => context.push(RouteName.myCheckIns),
    ),
    ProfileMenuItem(
      icon: Icons.groups_2_rounded,
      iconColor: SpontiColors.info,
      label: "Let's Go Plans",
      onTap: () => context.push(RouteName.groupPlans),
    ),
    ProfileMenuItem(
      icon: Icons.compare_arrows_rounded,
      iconColor: SpontiColors.accent,
      label: 'Compare Locations',
      onTap: () => context.push(RouteName.locationComparisonPath()),
    ),
    ProfileMenuItem(
      icon: Icons.add_location_alt_rounded,
      iconColor: SpontiColors.secondary,
      label: 'Suggested Spots',
      onTap: () => context.push(RouteName.suggestSpot),
    ),
  ];

  List<ProfileMenuItem> _settingsItems(BuildContext context, WidgetRef ref) => [
    ProfileMenuItem(
      icon: Icons.edit_rounded,
      iconColor: SpontiColors.secondary,
      label: 'Edit Profile',
      onTap: () => context.push(RouteName.editProfile),
    ),
    ProfileMenuItem(
      icon: Icons.logout_rounded,
      iconColor: SpontiColors.error,
      label: 'Sign Out',
      onTap: () => showSignOutDialog(context, ref),
    ),
  ];
}

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

  final errorMessage = await ref
      .read(profileProvider.notifier)
      .uploadPhoto(
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
