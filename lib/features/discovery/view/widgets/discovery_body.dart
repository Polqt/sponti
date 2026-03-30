import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/discovery/view/widgets/discovery_category_accordions_section.dart';
import 'package:sponti/features/discovery/view/widgets/discovery_column_switcher.dart';
import 'package:sponti/features/discovery/view/widgets/discovery_for_you_grid.dart';
import 'package:sponti/features/discovery/view/widgets/discovery_friends_placeholder.dart';
import 'package:sponti/features/discovery/view/widgets/discovery_top_curators_placeholder.dart';
import 'package:sponti/features/discovery/viewmodel/discovery_viewmodel.dart';

class DiscoveryBody extends ConsumerWidget {
  const DiscoveryBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(discoveryViewModelProvider);
    final notifier = ref.read(discoveryViewModelProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: DiscoveryColumnSwitcher(
              activeColumn: state.activeColumn,
              onChanged: notifier.setActiveColumn,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            state.sectionTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: state.activeColumn == DiscoveryColumn.forYou
                ? const DiscoveryForYouGrid(cards: discoveryTopPicks)
                : const DiscoveryFriendsPlaceholder(),
          ),
          if (state.activeColumn == DiscoveryColumn.forYou) ...[
            const SizedBox(height: 32),
            const DiscoveryCategoryAccordionsSection(),
            const SizedBox(height: 32),
            Text(
              'TOP CURATORS',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 16),
            const DiscoveryTopCuratorsPlaceholder(),
          ],
        ],
      ),
    );
  }
}
