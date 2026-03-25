import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/discovery/viewmodel/discovery_viewmodel.dart';

class DiscoveryColumnSwitcher extends StatelessWidget {
  const DiscoveryColumnSwitcher({
    super.key,
    required this.activeColumn,
    required this.onChanged,
  });

  final DiscoveryColumn activeColumn;
  final ValueChanged<DiscoveryColumn> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DiscoveryColumnTab(
            label: 'for you',
            isSelected: activeColumn == DiscoveryColumn.forYou,
            onTap: () => onChanged(DiscoveryColumn.forYou),
          ),
          const SizedBox(width: 20),
          DiscoveryColumnTab(
            label: 'friends',
            isSelected: activeColumn == DiscoveryColumn.friends,
            onTap: () => onChanged(DiscoveryColumn.friends),
          ),
        ],
      ),
    );
  }
}

class DiscoveryColumnTab extends StatelessWidget {
  const DiscoveryColumnTab({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      color: isSelected
          ? SpontiColors.textPrimary
          : SpontiColors.textSecondary,
      letterSpacing: -0.2,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: textStyle),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: 2,
              width: isSelected ? 54 : 0,
              decoration: BoxDecoration(
                color: SpontiColors.textPrimary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
