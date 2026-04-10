import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';

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
    if (!isSearching) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final title = isPendingSearch
        ? 'Searching...'
        : '$resultCount result${resultCount == 1 ? '' : 's'}';
    final subtitle = isPendingSearch
        ? 'Finding the best matches for "$query".'
        : 'Showing the closest fit for "$committedQuery".';
    final pillLabel = isPendingSearch
        ? 'Live'
        : 'Ready';
    final pillColor = isPendingSearch
        ? SpontiColors.primary
        : SpontiColors.secondary;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.92),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: SpontiColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: SpontiColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: pillColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              pillLabel,
              style: TextStyle(
                color: pillColor,
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
