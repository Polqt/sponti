import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_empty_state.dart';
import 'package:sponti/features/locations/model/location.dart';
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
    required this.onLocationTap,
  });

  final String draftQuery;
  final String committedQuery;
  final AsyncValue<List<Location>> resultsAsync;
  final List<Location> results;
  final ValueChanged<Location> onLocationTap;

  @override
  Widget build(BuildContext context) {
    final normalizedDraft = normalizeSearchQuery(draftQuery);
    final isSearching = normalizedDraft.length >= searchMinQueryLength;
    final isPendingSearch = isSearching && normalizedDraft != committedQuery;

    if (!isSearching) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: SearchWelcomeState(),
      );
    }

    if (isPendingSearch || (resultsAsync.isLoading && results.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(color: SpontiColors.primary),
      );
    }

    if (resultsAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: AppEmptyState(
          emoji: '\u{1F615}',
          title: 'Search failed',
          subtitle: resultsAsync.error.toString(),
        ),
      );
    }

    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: AppEmptyState(
          emoji: '\u{1FAE5}',
          title: 'No matches found',
          subtitle: 'Try a shorter name, a category, or a nearby landmark.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final location = results[index];
        return SearchResultCard(
          location: location,
          index: index,
          onTap: () => onLocationTap(location),
        );
      },
    );
  }
}
