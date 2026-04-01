import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_network_image.dart';
import 'package:sponti/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:sponti/features/discovery/model/discovery_curator.dart';
import 'package:sponti/features/discovery/viewmodel/discovery_viewmodel.dart';

enum _CuratorLaneKind { overall, reviewers, visitors }

class DiscoveryTopCuratorsSection extends ConsumerWidget {
  const DiscoveryTopCuratorsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final leaderboardsAsync = ref.watch(curatorLeaderboardsProvider);

    return leaderboardsAsync.when(
      loading: () => const _CuratorSectionsLoading(),
      error: (_, _) => const _CuratorMessage(
        icon: Icons.wifi_tethering_error_rounded,
        message: 'Could not load curators right now.',
      ),
      data: (leaderboards) {
        if (leaderboards.isEmpty) {
          return const _CuratorMessage(
            icon: Icons.auto_awesome_rounded,
            message: 'Curators will appear here once reviews and visits roll in.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CuratorLane(
              title: 'Top curators',
              subtitle: 'Most reviews and check-ins combined.',
              curators: leaderboards.topCurators,
              kind: _CuratorLaneKind.overall,
              currentUserId: currentUserId,
            ),
            const SizedBox(height: 20),
            _CuratorLane(
              title: 'Top reviewers',
              subtitle: 'People writing the most reviews.',
              curators: leaderboards.topReviewers,
              kind: _CuratorLaneKind.reviewers,
              currentUserId: currentUserId,
            ),
            const SizedBox(height: 20),
            _CuratorLane(
              title: 'Top visitors',
              subtitle: 'People checking in the most.',
              curators: leaderboards.topVisitors,
              kind: _CuratorLaneKind.visitors,
              currentUserId: currentUserId,
            ),
          ],
        );
      },
    );
  }
}

class _CuratorLane extends StatelessWidget {
  const _CuratorLane({
    required this.title,
    required this.subtitle,
    required this.curators,
    required this.kind,
    required this.currentUserId,
  });

  final String title;
  final String subtitle;
  final List<DiscoveryCurator> curators;
  final _CuratorLaneKind kind;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: SpontiColors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: SpontiColors.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        if (curators.isEmpty)
          Text(
            _emptyMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: SpontiColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          )
        else
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: curators.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) => _CuratorAvatarTile(
                curator: curators[index],
                rank: index + 1,
                kind: kind,
                isCurrentUser: curators[index].id == currentUserId,
                onTap: () {
                  if (curators[index].id == currentUserId) {
                    context.go(RouteName.profile);
                    return;
                  }

                  context.push(RouteName.userProfilePath(curators[index].id));
                },
              ),
            ),
          ),
      ],
    );
  }

  static const _emptyMessage = 'No leaderboard activity yet.';
}

class _CuratorAvatarTile extends StatelessWidget {
  const _CuratorAvatarTile({
    required this.curator,
    required this.rank,
    required this.kind,
    required this.isCurrentUser,
    required this.onTap,
  });

  final DiscoveryCurator curator;
  final int rank;
  final _CuratorLaneKind kind;
  final bool isCurrentUser;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = switch (rank) {
      1 => const Color(0xFF0A8F49),
      2 => const Color(0xFFF28A60),
      3 => const Color(0xFF3F8CFF),
      _ => SpontiColors.outline,
    };

    return TweenAnimationBuilder<double>(
      key: ValueKey<String>('${kind.name}-${curator.id}'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 200 + (rank * 30)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: 100,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentColor,
                            width: rank == 1 ? 2.5 : 2,
                          ),
                        ),
                        child: AppNetworkImage.circle(
                          url: curator.avatarUrl,
                          size: 63,
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$rank',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    curator.handle ?? curator.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isCurrentUser
                          ? SpontiColors.primary
                          : SpontiColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _metric,
                    maxLines: kind == _CuratorLaneKind.overall ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: SpontiColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _label => switch (kind) {
    _CuratorLaneKind.overall => 'Top curator',
    _CuratorLaneKind.reviewers => 'Top reviewer',
    _CuratorLaneKind.visitors => 'Top visitor',
  };

  String get _metric => switch (kind) {
    _CuratorLaneKind.overall =>
      '${curator.totalReviews} reviews + ${curator.totalCheckIns} visits',
    _CuratorLaneKind.reviewers => '${curator.totalReviews} reviews',
    _CuratorLaneKind.visitors => '${curator.totalCheckIns} visits',
  };
}

class _CuratorMessage extends StatelessWidget {
  const _CuratorMessage({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: SpontiColors.textMuted),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: SpontiColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CuratorSectionsLoading extends StatelessWidget {
  const _CuratorSectionsLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CuratorLaneLoading(title: 'TOP CURATORS'),
        SizedBox(height: 20),
        _CuratorLaneLoading(title: 'TOP REVIEWERS'),
        SizedBox(height: 20),
        _CuratorLaneLoading(title: 'TOP VISITORS'),
      ],
    );
  }
}

class _CuratorLaneLoading extends StatelessWidget {
  const _CuratorLaneLoading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: SpontiColors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 160,
          height: 10,
          decoration: BoxDecoration(
            color: SpontiColors.surfaceVariant,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, _) => const _CuratorLoadingTile(),
          ),
        ),
      ],
    );
  }
}

class _CuratorLoadingTile extends StatelessWidget {
  const _CuratorLoadingTile();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: SpontiColors.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(color: SpontiColors.outline),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 64,
            height: 11,
            decoration: BoxDecoration(
              color: SpontiColors.surfaceVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: 56,
            height: 9,
            decoration: BoxDecoration(
              color: SpontiColors.surfaceVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 70,
            height: 9,
            decoration: BoxDecoration(
              color: SpontiColors.surfaceVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
