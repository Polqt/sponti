import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/profile/model/user_profile.dart';

class ProfileStatsCard extends StatefulWidget {
  const ProfileStatsCard({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<ProfileStatsCard> createState() => _ProfileStatsCardState();
}

class _ProfileStatsCardState extends State<ProfileStatsCard> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: SpontiColors.shadow.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: SpontiColors.shadow.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              label: 'Check-ins',
              value: widget.profile.checkInCount,
              color: SpontiColors.primary,
              isHovered: _hoveredIndex == 0,
              onHover: (isHovered) =>
                  setState(() => _hoveredIndex = isHovered ? 0 : null),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: SpontiColors.outline.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _StatItem(
              label: 'Saved',
              value: widget.profile.favoritesCount,
              color: SpontiColors.accent,
              isHovered: _hoveredIndex == 1,
              onHover: (isHovered) =>
                  setState(() => _hoveredIndex = isHovered ? 1 : null),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: SpontiColors.outline.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _StatItem(
              label: 'Suggested',
              value: widget.profile.spotsSuggested,
              color: SpontiColors.secondary,
              isHovered: _hoveredIndex == 2,
              onHover: (isHovered) =>
                  setState(() => _hoveredIndex = isHovered ? 2 : null),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.isHovered,
    required this.onHover,
  });

  final String label;
  final int value;
  final Color color;
  final bool isHovered;
  final ValueChanged<bool> onHover;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: AnimatedScale(
        scale: isHovered ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SpontiColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}