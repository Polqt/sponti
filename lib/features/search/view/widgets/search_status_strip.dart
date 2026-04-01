import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/search/view/widgets/search_glass_panel.dart';

class SearchStatusStrip extends StatelessWidget {
  const SearchStatusStrip({
    super.key,
    required this.query,
    required this.committedQuery,
    required this.resultCount,
    required this.isSearching,
    required this.isPendingSearch,
  });

  final String query;
  final String committedQuery;
  final int resultCount;
  final bool isSearching;
  final bool isPendingSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = !isSearching
        ? 'Fresh around you'
        : isPendingSearch
        ? 'Searching...'
        : '$resultCount result${resultCount == 1 ? '' : 's'}';
    final subtitle = !isSearching
        ? 'Start with coffee, parks, hidden gems, or your favorite landmark.'
        : isPendingSearch
        ? 'Finding the best matches for "$query".'
        : 'Showing the closest fit for "$committedQuery".';
    final pillLabel = !isSearching
        ? 'Fresh'
        : isPendingSearch
        ? 'Live'
        : 'Ready';
    final pillColor = !isSearching
        ? SpontiColors.dark
        : isPendingSearch
        ? SpontiColors.primary
        : SpontiColors.secondary;

    return SearchGlassPanel(
      radius: 30,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      gradientColors: [
        Colors.white.withValues(alpha: 0.72),
        const Color(0xFFF6EFE8).withValues(alpha: 0.56),
        const Color(0xFFE9F4F0).withValues(alpha: 0.46),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  pillColor.withValues(alpha: 0.22),
                  pillColor.withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              !isSearching
                  ? Icons.bolt_rounded
                  : isPendingSearch
                  ? Icons.radar_rounded
                  : Icons.check_circle_rounded,
              color: pillColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: SpontiColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: SpontiColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: pillColor,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: pillColor.withValues(alpha: 0.20),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              pillLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
