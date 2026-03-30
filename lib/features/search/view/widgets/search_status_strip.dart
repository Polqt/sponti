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
    final statusLabel = !isSearching
        ? 'Trending near you'
        : isPendingSearch
        ? 'Searching for "$query"'
        : '$resultCount matches for "$committedQuery"';

    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  statusLabel,
                  key: ValueKey<String>(
                    '$statusLabel|$query|$committedQuery|$resultCount',
                  ),
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: SpontiColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ),
          if (!isSearching) ...[
            const SizedBox(width: 16),
            const _MoodPill(label: 'Fresh', icon: Icons.auto_awesome),
          ],
        ],
      ),
    );
  }
}

class _MoodPill extends StatelessWidget {
  const _MoodPill({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: SpontiColors.textPrimary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
