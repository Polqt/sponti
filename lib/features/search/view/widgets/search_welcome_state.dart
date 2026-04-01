import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/search/view/widgets/search_glass_panel.dart';

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
        SearchGlassPanel(
          radius: 32,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          gradientColors: [
            Colors.white.withValues(alpha: 0.74),
            const Color(0xFFF7F0E7).withValues(alpha: 0.62),
            const Color(0xFFE7F1EE).withValues(alpha: 0.56),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: SpontiColors.dark.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'TRENDING NEAR YOU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Start with a vibe, then refine from there.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: SpontiColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap a suggestion to instantly search curated spots around you.',
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
                children: const [
                  _SearchHintPill(label: 'Coffee'),
                  _SearchHintPill(label: 'Budget dates'),
                  _SearchHintPill(label: 'Sunset walks'),
                  _SearchHintPill(label: 'Late-night food'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ..._suggestions.map(
          (suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
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
    return SearchGlassPanel(
      radius: 30,
      padding: EdgeInsets.zero,
      gradientColors: [
        Colors.white.withValues(alpha: 0.70),
        suggestion.color.withValues(alpha: 0.14),
      ],
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: suggestion.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    suggestion.icon,
                    color: suggestion.color,
                    size: 26,
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
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: suggestion.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          suggestion.query,
                          style: TextStyle(
                            color: suggestion.color,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.46),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    color: suggestion.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchHintPill extends StatelessWidget {
  const _SearchHintPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: SpontiColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
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
