import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_empty_state.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/search/view/widgets/search_glass_panel.dart';
import 'package:sponti/features/search/view/widgets/search_result_card.dart';
import 'package:sponti/features/search/view/widgets/search_welcome_state.dart';
import 'package:sponti/features/search/viewmodel/search_viewmodel.dart';

class SearchResultsContent extends StatelessWidget {
  const SearchResultsContent({
    super.key,
    required this.draftQuery,
    required this.committedQuery,
    required this.resultsAsync,
    required this.results,
    required this.onSuggestionTap,
    required this.onLocationTap,
  });

  final String draftQuery;
  final String committedQuery;
  final AsyncValue<List<Location>> resultsAsync;
  final List<Location> results;
  final ValueChanged<String> onSuggestionTap;
  final ValueChanged<Location> onLocationTap;

  @override
  Widget build(BuildContext context) {
    final normalizedDraft = normalizeSearchQuery(draftQuery);
    final isSearching = normalizedDraft.length >= searchMinQueryLength;
    final isPendingSearch = isSearching && normalizedDraft != committedQuery;

    if (!isSearching) {
      return SearchWelcomeState(onSuggestionTap: onSuggestionTap);
    }

    if (isPendingSearch || (resultsAsync.isLoading && results.isEmpty)) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 28),
        child: _SearchLoadingState(),
      );
    }

    if (resultsAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        child: AppEmptyState(
          emoji: '\u{1F615}',
          title: 'Search failed',
          subtitle: searchErrorMessage(resultsAsync.error!),
        ),
      );
    }

    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 28),
        child: AppEmptyState(
          emoji: '\u{1FAE5}',
          title: 'No matches found',
          subtitle: 'Try a shorter name, a category, or a nearby landmark.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      cacheExtent: 720,
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final location = results[index];
        return SearchResultCard(
          location: location,
          index: index,
          isPrimary: index == 0,
          onTap: () => onLocationTap(location),
        );
      },
    );
  }
}

class _SearchLoadingState extends StatelessWidget {
  const _SearchLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _SearchLoadingCard(height: 244),
        SizedBox(height: 16),
        _SearchLoadingCard(height: 152),
        SizedBox(height: 16),
        _SearchLoadingCard(height: 152),
      ],
    );
  }
}

class _SearchLoadingCard extends StatelessWidget {
  const _SearchLoadingCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SearchGlassPanel(
      radius: 30,
      padding: EdgeInsets.zero,
      gradientColors: [
        Colors.white.withValues(alpha: 0.64),
        const Color(0xFFF5EEE6).withValues(alpha: 0.44),
      ],
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.24),
                Colors.white.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: SpontiColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
