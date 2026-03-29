import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/locations/model/location.dart';

/// Returns the selected [PriceRange], or `null` if the user chose "Any price".
Future<PriceRange?> showBudgetFilterModal({
  required BuildContext context,
  required PriceRange? initialValue,
}) {
  return showModalBottomSheet<PriceRange?>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    // Side margins so the sheet matches the panel's floating card width.
    constraints: BoxConstraints(
      maxWidth: MediaQuery.sizeOf(context).width - 24,
    ),
    builder: (_) => _BudgetFilterModal(initialValue: initialValue),
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

  void _pick(PriceRange? price) {
    setState(() => _selected = price);
    Future.microtask(() {
      if (mounted) Navigator.of(context).pop(price);
    });
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
                        'Budget',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: SpontiColors.textPrimary,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.of(context).pop(widget.initialValue),
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
              // Any price
              _PriceRow(
                symbol: '—',
                label: 'Any price',
                description: 'Show all spots',
                color: SpontiColors.textSecondary,
                isSelected: _selected == null,
                onTap: () => _pick(null),
              ),
              for (final price in PriceRange.values) ...[
                const Divider(
                  height: 1,
                  indent: 64,
                  endIndent: 20,
                  color: Color(0x0CA68F7B),
                ),
                _PriceRow(
                  symbol: price.symbol,
                  label: price.label,
                  description: _description(price),
                  color: _color(price),
                  isSelected: _selected == price,
                  onTap: () => _pick(price),
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

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.symbol,
    required this.label,
    required this.description,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String symbol;
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
                child: Center(
                  child: Text(
                    symbol,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : SpontiColors.textMuted,
                    ),
                  ),
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
                        color: isSelected ? color : SpontiColors.textPrimary,
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

String _description(PriceRange price) => switch (price) {
  PriceRange.free => 'No entry or minimum spend',
  PriceRange.budget => 'Under ₱200 per person',
  PriceRange.moderate => '₱200 – ₱600 per person',
  PriceRange.expensive => 'Above ₱600 per person',
};

Color _color(PriceRange price) => switch (price) {
  PriceRange.free => SpontiColors.secondary,
  PriceRange.budget => SpontiColors.primary,
  PriceRange.moderate => SpontiColors.warning,
  PriceRange.expensive => const Color(0xFF7B4F2E),
};
