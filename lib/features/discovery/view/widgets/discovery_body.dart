import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/discovery/view/widgets/discovery_category_accordions_section.dart';
import 'package:sponti/features/discovery/view/widgets/discovery_column_switcher.dart';
import 'package:sponti/features/discovery/view/widgets/discovery_for_you_grid.dart';
import 'package:sponti/features/discovery/view/widgets/discovery_friends_placeholder.dart';
import 'package:sponti/features/discovery/view/widgets/discovery_top_curators_section.dart';
import 'package:sponti/features/discovery/viewmodel/discovery_viewmodel.dart';

class DiscoveryBody extends ConsumerWidget {
  const DiscoveryBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(discoveryViewModelProvider);
    final notifier = ref.read(discoveryViewModelProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented control
          Center(
            child: DiscoveryColumnSwitcher(
              activeColumn: state.activeColumn,
              onChanged: notifier.setActiveColumn,
            ),
          ),
          const SizedBox(height: 20),
          
          // Section header
          _SectionHeader(
            title: state.sectionTitle,
            subtitle: state.activeColumn == DiscoveryColumn.forYou
                ? 'Curated spots just for you'
                : 'What your friends are exploring',
          ),
          const SizedBox(height: 14),
          
          // Content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: state.activeColumn == DiscoveryColumn.forYou
                ? const DiscoveryForYouGrid(cards: discoveryTopPicks)
                : const DiscoveryFriendsPlaceholder(),
          ),
          
          if (state.activeColumn == DiscoveryColumn.forYou) ...[
            const _SectionHeader(
              title: 'Browse',
              subtitle: 'Explore by category',
            ),
            const SizedBox(height: 14),
            const DiscoveryCategoryAccordionsSection(),
            const SizedBox(height: 24),
            const _SectionHeader(
              title: 'Leaderboards',
              subtitle: 'Top community members',
            ),
            const SizedBox(height: 14),
            const DiscoveryTopCuratorsSection(),
          ],
        ],
      ),
    );
  }
}

/// iOS-style section header
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
