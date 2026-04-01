import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/search/view/widgets/search_glass_panel.dart';

class SearchTopBar extends StatelessWidget {
  const SearchTopBar({
    super.key,
    required this.controller,
    required this.queryListenable,
    required this.isLoading,
    required this.onBack,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueListenable<String> queryListenable;
  final bool isLoading;
  final VoidCallback onBack;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _FrostButton(
                icon: Icons.arrow_back_rounded,
                onTap: onBack,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FrostSearchField(
                  controller: controller,
                  queryListenable: queryListenable,
                  isLoading: isLoading,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  onClear: onClear,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SearchGlassPanel(
            radius: 30,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            gradientColors: [
              Colors.white.withValues(alpha: 0.70),
              const Color(0xFFF3EFE8).withValues(alpha: 0.64),
              const Color(0xFFEAF4F0).withValues(alpha: 0.56),
            ],
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: SpontiColors.textPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.travel_explore_rounded,
                    color: SpontiColors.textPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: SpontiColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Glass-smooth browsing for cafes, parks, and low-key gems.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: SpontiColors.dark.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Nearby',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FrostButton extends StatelessWidget {
  const _FrostButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SearchGlassPanel(
      radius: 22,
      padding: EdgeInsets.zero,
      gradientColors: [
        Colors.white.withValues(alpha: 0.68),
        const Color(0xFFF7F2EB).withValues(alpha: 0.54),
      ],
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 58,
            height: 58,
            child: Icon(
              icon,
              color: SpontiColors.textPrimary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _FrostSearchField extends StatelessWidget {
  const _FrostSearchField({
    required this.controller,
    required this.queryListenable,
    required this.isLoading,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueListenable<String> queryListenable;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SearchGlassPanel(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      gradientColors: [
        Colors.white.withValues(alpha: 0.72),
        const Color(0xFFF6F0E8).withValues(alpha: 0.54),
        const Color(0xFFE7F2EF).withValues(alpha: 0.48),
      ],
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.50),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_rounded,
              color: SpontiColors.textSecondary.withValues(alpha: 0.88),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: 'Search spots, cafes, parks',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: SpontiColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: SpontiColors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
              cursorColor: SpontiColors.primary,
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: SpontiColors.primary,
                ),
              ),
            ),
          ValueListenableBuilder<String>(
            valueListenable: queryListenable,
            builder: (context, value, _) {
              if (value.isEmpty) {
                return Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: SpontiColors.dark.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: SpontiColors.textSecondary,
                  ),
                );
              }

              return GestureDetector(
                onTap: onClear,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: SpontiColors.textPrimary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: SpontiColors.textSecondary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
