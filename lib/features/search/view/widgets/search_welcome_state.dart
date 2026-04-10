import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';

class SearchWelcomeState extends StatelessWidget {
  const SearchWelcomeState({
    super.key,
    required this.onSuggestionTap,
  });

  final ValueChanged<String> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Text(
          'Popular searches',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: SpontiColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Start with a place type or a nearby vibe.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: SpontiColors.textSecondary,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final suggestion in _suggestions)
              _SearchSuggestionChip(
                label: suggestion.query,
                onTap: () => onSuggestionTap(suggestion.query),
              ),
          ],
        ),
        const SizedBox(height: 22),
        ..._suggestions.map(
          (suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SearchSuggestionTile(
              suggestion: suggestion,
              onTap: () => onSuggestionTap(suggestion.query),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchSuggestionTile extends StatelessWidget {
  const _SearchSuggestionTile({
    required this.suggestion,
    required this.onTap,
  });

  final _SearchSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.92),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: suggestion.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    suggestion.icon,
                    color: suggestion.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: SpontiColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        suggestion.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: SpontiColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_outward_rounded,
                  color: suggestion.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchSuggestionChip extends StatelessWidget {
  const _SearchSuggestionChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: SpontiColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchSuggestion {
  const _SearchSuggestion({
    required this.title,
    required this.subtitle,
    required this.query,
    required this.color,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String query;
  final Color color;
  final IconData icon;
}

const List<_SearchSuggestion> _suggestions = [
  _SearchSuggestion(
    title: 'Coffee and brunch',
    subtitle: 'Soft spots for slow mornings and catch-up dates.',
    query: 'coffee',
    color: Color(0xFF9E6A45),
    icon: Icons.local_cafe_rounded,
  ),
  _SearchSuggestion(
    title: 'Parks and walks',
    subtitle: 'Open-air picks to reset your day without going far.',
    query: 'park',
    color: Color(0xFF487B53),
    icon: Icons.park_rounded,
  ),
  _SearchSuggestion(
    title: 'Hidden gems',
    subtitle: 'Quiet favorites people usually miss on a first pass.',
    query: 'hidden gem',
    color: Color(0xFF2C8C8E),
    icon: Icons.auto_awesome_rounded,
  ),
];
