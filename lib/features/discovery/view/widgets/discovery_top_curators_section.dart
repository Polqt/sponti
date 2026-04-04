import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:sponti/features/discovery/view/widgets/discovery_curator_lane.dart';
import 'package:sponti/features/discovery/view/widgets/discovery_curator_loading.dart';
import 'package:sponti/features/discovery/viewmodel/discovery_viewmodel.dart';

class DiscoveryTopCuratorsSection extends ConsumerWidget {
  const DiscoveryTopCuratorsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final leaderboardsAsync = ref.watch(curatorLeaderboardsProvider);

    return leaderboardsAsync.when(
      loading: () => const DiscoveryCuratorSectionsLoading(),
      error: (_, _) => const DiscoveryCuratorMessage(
        icon: Icons.wifi_tethering_error_rounded,
        message: 'Could not load curators right now.',
      ),
      data: (leaderboards) {
        if (leaderboards.isEmpty) {
          return const DiscoveryCuratorMessage(
            icon: Icons.auto_awesome_rounded,
            message: 'Curators will appear here once reviews and visits roll in.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DiscoveryCuratorLane(
              title: 'Top curators',
              subtitle: 'Most reviews and check-ins combined.',
              curators: leaderboards.topCurators,
              kind: CuratorLaneKind.overall,
              currentUserId: currentUserId,
            ),
            const SizedBox(height: 20),
            DiscoveryCuratorLane(
              title: 'Top reviewers',
              subtitle: 'People writing the most reviews.',
              curators: leaderboards.topReviewers,
              kind: CuratorLaneKind.reviewers,
              currentUserId: currentUserId,
            ),
            const SizedBox(height: 20),
            DiscoveryCuratorLane(
              title: 'Top visitors',
              subtitle: 'People checking in the most.',
              curators: leaderboards.topVisitors,
              kind: CuratorLaneKind.visitors,
              currentUserId: currentUserId,
            ),
          ],
        );
      },
    );
  }
}
