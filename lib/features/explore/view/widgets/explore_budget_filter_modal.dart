import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/locations/model/location.dart';

Future<PriceRange?> showBudgetFilterModal({
  required BuildContext context,
  required PriceRange? initialValue,
}) {
  return showModalBottomSheet<PriceRange?>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return _BudgetFilterModal(initialValue: initialValue);
    },
  );
}

class _BudgetFilterModal extends StatefulWidget {
  const _BudgetFilterModal({required this.initialValue});

  final PriceRange? initialValue;

  @override
  State<_BudgetFilterModal> createState() => _BudgetFilterModalState();
}

class _BudgetFilterModalState extends State<_BudgetFilterModal> {
  late PriceRange? _selected;

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
                  'filter by budget',
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
                children: [
                  _BudgetPillOption(
                    label: 'Any',
                    color: SpontiColors.textSecondary,
                    isSelected: _selected == null,
                    onTap: () {
                      setState(() => _selected = null);
                      Navigator.of(context).pop(null);
                    },
                  ),
                  ...PriceRange.values.map((price) {
                    final isSelected = _selected == price;
                    return _BudgetPillOption(
                      label: price.label,
                      color: _priceColor(price),
                      isSelected: isSelected,
                      onTap: () {
                        setState(() => _selected = price);
                        Navigator.of(context).pop(price);
                      },
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetPillOption extends StatelessWidget {
  const _BudgetPillOption({
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

Color _priceColor(PriceRange price) {
  return switch (price) {
    PriceRange.free => SpontiColors.secondary,
    PriceRange.budget => SpontiColors.primary,
    PriceRange.moderate => SpontiColors.warning,
    PriceRange.expensive => const Color(0xFF7B4F2E),
  };
}
