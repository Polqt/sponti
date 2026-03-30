import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_network_image.dart';
import 'package:sponti/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:sponti/features/discovery/model/discovery_curator.dart';
import 'package:sponti/features/discovery/viewmodel/discovery_viewmodel.dart';

class DiscoveryTopCuratorsSection extends ConsumerWidget {
  const DiscoveryTopCuratorsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final curatorsAsync = ref.watch(topCuratorsProvider);

    return SizedBox(
      height: 186,
      child: curatorsAsync.when(
        loading: () => const _CuratorLoadingList(),
        error: (_, _) => const _CuratorMessage(
          icon: Icons.wifi_tethering_error_rounded,
          message: 'Could not load curators right now.',
        ),
        data: (curators) {
          if (curators.isEmpty) {
            return const _CuratorMessage(
              icon: Icons.auto_awesome_rounded,
              message: 'Curators will appear here once reviews and visits roll in.',
            );
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: curators.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) => _CuratorAvatarTile(
              curator: curators[index],
              rank: index + 1,
              isCurrentUser: curators[index].id == currentUserId,
            ),
          );
        },
      ),
    );
  }
}

class _CuratorAvatarTile extends StatelessWidget {
  const _CuratorAvatarTile({
    required this.curator,
    required this.rank,
    required this.isCurrentUser,
  });

  final DiscoveryCurator curator;
  final int rank;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarRingColor = switch (rank) {
      1 => const Color(0xFF0A8F49),
      2 => const Color(0xFFF28A60),
      3 => const Color(0xFF3F8CFF),
      _ => SpontiColors.outline,
    };

    return TweenAnimationBuilder<double>(
      key: ValueKey<String>(curator.id),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + (rank * 40)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: 104,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: avatarRingColor,
                      width: rank == 1 ? 3 : 2,
                    ),
                  ),
                  child: AppNetworkImage.circle(
                    url: curator.avatarUrl,
                    size: 72,
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: avatarRingColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              curator.handle ?? curator.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isCurrentUser
                    ? SpontiColors.primary
                    : SpontiColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _roleLabel(curator),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: avatarRingColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _metricLabel(curator),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: SpontiColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(DiscoveryCurator curator) {
    if (curator.totalReviews > curator.totalCheckIns) {
      return 'Top reviewer';
    }
    if (curator.totalCheckIns > curator.totalReviews) {
      return 'Top visitor';
    }
    return 'Top curator';
  }

  String _metricLabel(DiscoveryCurator curator) {
    if (curator.totalReviews > curator.totalCheckIns) {
      return '${curator.totalReviews} reviews';
    }
    if (curator.totalCheckIns > curator.totalReviews) {
      return '${curator.totalCheckIns} visits';
    }
    return '${curator.activityScore} moves';
  }
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

class _CuratorLoadingList extends StatelessWidget {
  const _CuratorLoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(width: 14),
      itemBuilder: (_, __) => SizedBox(
        width: 104,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: SpontiColors.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(color: SpontiColors.outline),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 70,
              height: 12,
              decoration: BoxDecoration(
                color: SpontiColors.surfaceVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 7),
            Container(
              width: 66,
              height: 10,
              decoration: BoxDecoration(
                color: SpontiColors.surfaceVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 58,
              height: 10,
              decoration: BoxDecoration(
                color: SpontiColors.surfaceVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
