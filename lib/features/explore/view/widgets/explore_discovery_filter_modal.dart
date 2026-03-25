import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/explore/viewmodel/explore_viewmodel.dart';

Future<ExploreRanking?> showDiscoveryFilterModal({
  required BuildContext context,
  required ExploreRanking initialValue,
}) {
  return showModalBottomSheet<ExploreRanking>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return _DiscoveryFilterModal(initialValue: initialValue);
    },
  );
}

class _DiscoveryFilterModal extends StatefulWidget {
  const _DiscoveryFilterModal({required this.initialValue});

  final ExploreRanking initialValue;

  @override
  State<_DiscoveryFilterModal> createState() => _DiscoveryFilterModalState();
}

class _DiscoveryFilterModalState extends State<_DiscoveryFilterModal> {
  late ExploreRanking _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset + 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
          decoration: const BoxDecoration(
            color: SpontiColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SpontiColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'filter places that are',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SpontiColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ExploreRanking.values.map((ranking) {
                  final isSelected = _selected == ranking;
                  return _DiscoveryPillOption(
                    label: ranking.label.toLowerCase(),
                    color: _rankingColor(ranking),
                    isSelected: isSelected,
                    onTap: () {
                      setState(() => _selected = ranking);
                      Navigator.of(context).pop(ranking);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoveryPillOption extends StatelessWidget {
  const _DiscoveryPillOption({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.14)
                : SpontiColors.surfaceVariant.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? color : SpontiColors.outline.withValues(alpha: 0.5),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: color,
                  ),
                ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isSelected ? color : SpontiColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _rankingColor(ExploreRanking ranking) {
  return switch (ranking) {
    ExploreRanking.popular => const Color(0xFFE07A15),
    ExploreRanking.lowkey => const Color(0xFF3A7D44),
    ExploreRanking.newest => SpontiColors.accent,
    ExploreRanking.trending => SpontiColors.primary,
  };
}
