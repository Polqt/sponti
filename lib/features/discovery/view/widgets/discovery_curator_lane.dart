import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_network_image.dart';
import 'package:sponti/features/discovery/model/discovery_curator.dart';

enum CuratorLaneKind { overall, reviewers, visitors }

class DiscoveryCuratorLane extends StatelessWidget {
  const DiscoveryCuratorLane({
    super.key,
    required this.title,
    required this.subtitle,
    required this.curators,
    required this.kind,
    required this.currentUserId,
  });

  final String title;
  final String subtitle;
  final List<DiscoveryCurator> curators;
  final CuratorLaneKind kind;
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
            'No leaderboard activity yet.',
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
              itemBuilder: (context, index) => DiscoveryCuratorAvatarTile(
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
}

class DiscoveryCuratorAvatarTile extends StatelessWidget {
  const DiscoveryCuratorAvatarTile({
    super.key,
    required this.curator,
    required this.rank,
    required this.kind,
    required this.isCurrentUser,
    required this.onTap,
  });

  final DiscoveryCurator curator;
  final int rank;
  final CuratorLaneKind kind;
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
                    maxLines: kind == CuratorLaneKind.overall ? 2 : 1,
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
    CuratorLaneKind.overall => 'Top curator',
    CuratorLaneKind.reviewers => 'Top reviewer',
    CuratorLaneKind.visitors => 'Top visitor',
  };

  String get _metric => switch (kind) {
    CuratorLaneKind.overall =>
      '${curator.totalReviews} reviews + ${curator.totalCheckIns} visits',
    CuratorLaneKind.reviewers => '${curator.totalReviews} reviews',
    CuratorLaneKind.visitors => '${curator.totalCheckIns} visits',
  };
}

class DiscoveryCuratorMessage extends StatelessWidget {
  const DiscoveryCuratorMessage({
    super.key,
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
