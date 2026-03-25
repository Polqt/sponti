part of 'explore_filter_sheets.dart';

class _SelectableExploreSheet<T> extends StatefulWidget {
  const _SelectableExploreSheet({
    required this.title,
    required this.initialValue,
    required this.options,
  });

  final String title;
  final T initialValue;
  final List<_ExploreSheetOption<T>> options;

  @override
  State<_SelectableExploreSheet<T>> createState() =>
      _SelectableExploreSheetState<T>();
}

class _SelectableExploreSheetState<T>
    extends State<_SelectableExploreSheet<T>> {
  late T _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.options;
    return _SheetScaffold(
      title: widget.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final option = options[index];
                final selected = _selected == option.value;
                return _ExploreRadioRow<T>(
                  option: option,
                  selected: selected,
                  onTap: () => setState(() => _selected = option.value),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Apply',
            onPressed: () => Navigator.of(context).pop(_selected),
          ),
        ],
      ),
    );
  }
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset + 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: const BoxDecoration(
            color: SpontiColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SpontiColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SpontiColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreRadioRow<T> extends StatelessWidget {
  const _ExploreRadioRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _ExploreSheetOption<T> option;
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? SpontiColors.primary.withValues(alpha: 0.08)
                : SpontiColors.surfaceVariant.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? SpontiColors.primary : SpontiColors.outline,
            ),
          ),
          child: RadioGroup<T>(
            groupValue: selected ? option.value : null,
            onChanged: (_) => onTap(),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  Radio<T>(
                    value: option.value,
                    activeColor: SpontiColors.primary,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.label,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: SpontiColors.textPrimary,
                          ),
                        ),
                        if (option.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            option.subtitle!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: SpontiColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExploreSheetOption<T> {
  const _ExploreSheetOption({
    required this.value,
    required this.label,
    this.subtitle,
  });

  final T value;
  final String label;
  final String? subtitle;
}
