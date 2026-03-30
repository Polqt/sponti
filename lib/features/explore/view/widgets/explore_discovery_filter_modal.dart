import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/explore/viewmodel/explore_viewmodel.dart';

/// Returns the selected [ExploreRanking], or `null` if the user chose "None".
Future<ExploreRanking?> showDiscoveryFilterModal({
  required BuildContext context,
  required ExploreRanking? initialValue,
}) {
  return showModalBottomSheet<ExploreRanking?>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    // Side margins so the sheet matches the panel's floating card width.
    constraints: BoxConstraints(
      maxWidth: MediaQuery.sizeOf(context).width - 24,
    ),
    builder: (_) => _DiscoveryFilterModal(initialValue: initialValue),
  );
}

class _DiscoveryFilterModal extends StatefulWidget {
  const _DiscoveryFilterModal({required this.initialValue});
  final ExploreRanking? initialValue;

  @override
  State<_DiscoveryFilterModal> createState() => _DiscoveryFilterModalState();
}

class _DiscoveryFilterModalState extends State<_DiscoveryFilterModal> {
  late ExploreRanking? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
  }

  void _pick(ExploreRanking? ranking) {
    setState(() => _selected = ranking);
    Navigator.of(context, rootNavigator: true).pop(ranking);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    const radius = BorderRadius.all(Radius.circular(28));

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F6F1).withValues(alpha: 0.97),
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 2),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: SpontiColors.textMuted.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Sort by',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: SpontiColors.textPrimary,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pop(widget.initialValue),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: SpontiColors.textMuted.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: SpontiColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0x14A68F7B)),
              // None
              _OptionRow(
                icon: Icons.remove_rounded,
                label: 'None',
                description: 'Show all spots unfiltered',
                color: SpontiColors.textSecondary,
                isSelected: _selected == null,
                onTap: () => _pick(null),
              ),
              for (final ranking in ExploreRanking.values) ...[
                const Divider(
                  height: 1,
                  indent: 64,
                  endIndent: 20,
                  color: Color(0x0CA68F7B),
                ),
                _OptionRow(
                  icon: _rankingIcon(ranking),
                  label: ranking.label,
                  description: ranking.subtitle,
                  color: _rankingColor(ranking),
                  isSelected: _selected == ranking,
                  onTap: () => _pick(ranking),
                ),
              ],
              SizedBox(height: bottomInset + 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.12)
                      : SpontiColors.textMuted.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 17,
                  color: isSelected ? color : SpontiColors.textMuted,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? color : SpontiColors.textPrimary,
                      ),
                    ),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SpontiColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? color : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? color : SpontiColors.outline,
                    width: isSelected ? 0 : 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _rankingIcon(ExploreRanking r) => switch (r) {
  ExploreRanking.trending => Icons.local_fire_department_rounded,
  ExploreRanking.popular => Icons.favorite_rounded,
  ExploreRanking.lowkey => Icons.visibility_off_rounded,
  ExploreRanking.newest => Icons.auto_awesome_rounded,
};

Color _rankingColor(ExploreRanking r) => switch (r) {
  ExploreRanking.trending => SpontiColors.primary,
  ExploreRanking.popular => const Color(0xFFE07A15),
  ExploreRanking.lowkey => const Color(0xFF3A7D44),
  ExploreRanking.newest => SpontiColors.accent,
};
