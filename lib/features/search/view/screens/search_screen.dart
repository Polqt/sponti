import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/group_plans/viewmodel/group_plans_viewmodel.dart';
import 'package:sponti/features/location_comparison/viewmodel/location_comparison_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';
import 'package:sponti/features/search/view/widgets/search_results_content.dart';
import 'package:sponti/features/search/view/widgets/search_scaffold_background.dart';
import 'package:sponti/features/search/view/widgets/search_status_strip.dart';
import 'package:sponti/features/search/view/widgets/search_top_bar.dart';
import 'package:sponti/features/search/viewmodel/search_viewmodel.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({
    super.key,
    this.voteForPlanId,
    this.compareMode = false,
  });

  final String? voteForPlanId;
  final bool compareMode;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final ValueNotifier<String> _draftQuery = ValueNotifier<String>('');
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(searchQueryProvider);
    _controller.text = initialQuery;
    _draftQuery.value = initialQuery;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _draftQuery.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _draftQuery.value = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      final normalizedQuery = normalizeSearchQuery(value);
      final queryNotifier = ref.read(searchQueryProvider.notifier);
      if (queryNotifier.state == normalizedQuery) return;
      queryNotifier.state = normalizedQuery;
    });
  }

  void _commitQueryNow(String value) {
    _debounce?.cancel();
    ref.read(searchQueryProvider.notifier).state = normalizeSearchQuery(value);
  }

  void _applySuggestion(String query) {
    _controller.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    _draftQuery.value = query;
    _commitQueryNow(query);
  }

  void _clearQuery() {
    _debounce?.cancel();
    _controller.clear();
    _draftQuery.value = '';
    ref.read(searchQueryProvider.notifier).state = '';
  }

  void _openCompareMap({Location? location}) {
    ref.read(compareSelectionModeProvider.notifier).state = true;
    ref.read(pendingLocationProvider.notifier).state = location;
    context.go(RouteName.location);
  }

  Future<void> _handleLocationTap(BuildContext context, Location location) async {
    if (widget.compareMode) {
      _openCompareMap(location: location);
      return;
    }

    final planId = widget.voteForPlanId;
    if (planId != null) {
      await ref.read(groupPlanDetailProvider(planId).notifier).vote(location.id);
      if (!context.mounted) return;
      context.pop();
      return;
    }

    context.push(RouteName.locationDetailPath(location.id));
  }

  @override
  Widget build(BuildContext context) {
    final committedQuery = ref.watch(normalizedSearchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final results = resultsAsync.valueOrNull ?? const <Location>[];

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      body: SearchScaffoldBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = constraints.maxWidth < 680
                  ? constraints.maxWidth
                  : 680.0;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: SearchTopBar(
                          controller: _controller,
                          queryListenable: _draftQuery,
                          isLoading: resultsAsync.isLoading,
                          onBack: () => context.pop(),
                          onChanged: _onQueryChanged,
                          onSubmitted: _commitQueryNow,
                          onClear: _clearQuery,
                        ),
                      ),
                      if (widget.voteForPlanId != null || widget.compareMode)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: widget.compareMode ? _openCompareMap : null,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: SpontiColors.info.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: SpontiColors.info.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    widget.compareMode
                                        ? Icons.compare_arrows_rounded
                                        : Icons.how_to_vote_rounded,
                                    size: 16,
                                    color: SpontiColors.info,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.compareMode
                                          ? 'Tap a location and add it to compare'
                                          : 'Tap a location to cast your vote',
                                      style: const TextStyle(
                                        color: SpontiColors.info,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  if (widget.compareMode)
                                    const Icon(
                                      Icons.map_rounded,
                                      size: 16,
                                      color: SpontiColors.info,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ValueListenableBuilder<String>(
                        valueListenable: _draftQuery,
                        builder: (context, draftQuery, _) {
                          final normalizedDraft = normalizeSearchQuery(
                            draftQuery,
                          );
                          final isSearching =
                              normalizedDraft.length >= searchMinQueryLength;
                          final isPendingSearch =
                              isSearching &&
                              normalizedDraft != committedQuery;

                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: !isSearching
                                ? const SizedBox(height: 10)
                                : Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      14,
                                      20,
                                      12,
                                    ),
                                    child: SearchStatusStrip(
                                      query: normalizedDraft,
                                      committedQuery: committedQuery,
                                      resultCount: results.length,
                                      isSearching: isSearching,
                                      isPendingSearch: isPendingSearch,
                                    ),
                                  ),
                          );
                        },
                      ),
                      Expanded(
                        child: ValueListenableBuilder<String>(
                          valueListenable: _draftQuery,
                          builder: (context, draftQuery, _) {
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: SearchResultsContent(
                                key: ValueKey<String>(
                                  '${normalizeSearchQuery(draftQuery)}|$committedQuery|${results.length}|${resultsAsync.hasError}|${resultsAsync.isLoading}',
                                ),
                                draftQuery: draftQuery,
                                committedQuery: committedQuery,
                                resultsAsync: resultsAsync,
                                results: results,
                                onSuggestionTap: _applySuggestion,
                                onLocationTap: (location) =>
                                    _handleLocationTap(context, location),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
