import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/config/shell/shell_provider.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/discovery/view/widgets/discovery_category_accordions_section.dart';
import 'package:sponti/features/discovery/view/widgets/discovery_column_switcher.dart';
import 'package:sponti/features/discovery/view/widgets/discovery_for_you_grid.dart';
import 'package:sponti/features/discovery/view/widgets/discovery_top_curators_section.dart';
import 'package:sponti/features/discovery/viewmodel/discovery_viewmodel.dart';
import 'package:sponti/features/friends/view/widgets/friend_activity_feed.dart';

class DiscoveryBody extends ConsumerWidget {
  const DiscoveryBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(discoveryViewModelProvider);
    final notifier = ref.read(discoveryViewModelProvider.notifier);

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final dockBottomInset = bottomInset > 0 ? bottomInset : 6.0;
    final bottomPadding = kShellBottomBarHeight + dockBottomInset;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: DiscoveryColumnSwitcher(
              activeColumn: state.activeColumn,
              onChanged: notifier.setActiveColumn,
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader(
            title: state.sectionTitle,
            subtitle: switch (state.activeColumn) {
              DiscoveryColumn.forYou => 'Curated spots just for you',
              DiscoveryColumn.friends => 'What your friends are exploring',
              DiscoveryColumn.leaderboards => 'Top community members',
            },
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: switch (state.activeColumn) {
              DiscoveryColumn.forYou => const _ForYouContent(),
              DiscoveryColumn.friends => const FriendActivityFeed(),
              DiscoveryColumn.leaderboards => const DiscoveryTopCuratorsSection(),
            },
          ),
        ],
      ),
    );
  }
}

class _ForYouContent extends StatelessWidget {
  const _ForYouContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        DiscoveryForYouGrid(cards: discoveryTopPicks),
        SizedBox(height: 20),
        _SectionHeader(title: 'Browse', subtitle: 'Explore by category'),
        SizedBox(height: 12),
        DiscoveryCategoryAccordionsSection(),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: SpontiColors.textPrimary,
            letterSpacing: -0.4,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: SpontiColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
