part of 'explore_filter_sheets.dart';

Future<_CategorySheetResult?> _showCategoryExploreSheet({
  required BuildContext context,
  required LocationCategory? initialValue,
}) {
  return showModalBottomSheet<_CategorySheetResult>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return _CategoryExploreSheet(initialValue: initialValue);
    },
  );
}

class _CategoryExploreSheet extends StatefulWidget {
  const _CategoryExploreSheet({required this.initialValue});

  final LocationCategory? initialValue;

  @override
  State<_CategoryExploreSheet> createState() => _CategoryExploreSheetState();
}

class _CategoryExploreSheetState extends State<_CategoryExploreSheet> {
  late LocationCategory? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
  }

  List<_CategorySheetOption> get _options => [
    const _CategorySheetOption(
      label: 'All',
      color: SpontiColors.primary,
      fallbackIcon: Icons.grid_view_rounded,
    ),
    ...LocationCategory.values.map(
      (category) => _CategorySheetOption(
        label: category.label,
        category: category,
        emoji: category.emoji,
        color: Color(category.colorValue),
        fallbackIcon: category.icon,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Category',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final option = _options[index];
                return _CategorySheetRow(
                  option: option,
                  selected: _selected == option.category,
                  onTap: () => setState(() => _selected = option.category),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Apply',
            onPressed: () => Navigator.of(
              context,
            ).pop(_CategorySheetResult(_selected)),
          ),
        ],
      ),
    );
  }
}

class _CategorySheetResult {
  const _CategorySheetResult(this.value);

  final LocationCategory? value;
}

class _CategorySheetOption {
  const _CategorySheetOption({
    required this.label,
    required this.color,
    required this.fallbackIcon,
    this.category,
    this.emoji,
  });

  final String label;
  final LocationCategory? category;
  final String? emoji;
  final Color color;
  final IconData fallbackIcon;
}

class _CategorySheetRow extends StatelessWidget {
  const _CategorySheetRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _CategorySheetOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? option.color.withValues(alpha: 0.14)
                : SpontiColors.surfaceVariant.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? option.color : SpontiColors.outline,
            ),
          ),
          child: Row(
            children: [
              _CategoryPreviewChip(
                option: option,
                isSelected: selected,
              ),
              const Spacer(),
              RadioGroup<bool>(
                groupValue: selected,
                onChanged: (_) => onTap(),
                child: Radio<bool>(
                  value: true,
                  activeColor: option.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPreviewChip extends StatelessWidget {
  const _CategoryPreviewChip({
    required this.option,
    required this.isSelected,
  });

  final _CategorySheetOption option;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? option.color : SpontiColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isSelected
            ? option.color.withValues(alpha: 0.14)
            : SpontiColors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isSelected ? option.color : SpontiColors.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (option.emoji != null) ...[
            Text(option.emoji!, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
          ],
          LocationCategoryIcon(
            category: option.category,
            fallbackIcon: option.fallbackIcon,
            color: foreground,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            option.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
