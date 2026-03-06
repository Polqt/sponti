import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';

class TagsDisplay extends StatelessWidget {
  const TagsDisplay({super.key, required this.tags, this.maxVisible});

  final List<String> tags;

  /// If [maxVisible] is provided, only show that many tags and an additional
  final int? maxVisible;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    final visible = maxVisible != null && tags.length > maxVisible!
        ? maxVisible!
        : null;
    final displayTags = visible != null ? tags.take(visible).toList() : tags;
    final overflow = visible != null ? tags.length - visible : 0;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...displayTags.map((tag) => _TagChip(label: tag)),
        if (overflow > 0) _TagChip(label: '+$overflow', isOverflow: true),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, this.isOverflow = false});
  final String label;
  final bool isOverflow;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: isOverflow
          ? SpontiColors.surfaceVariant
          : SpontiColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isOverflow
            ? SpontiColors.outline
            : SpontiColors.primary.withValues(alpha: 0.25),
      ),
    ),
    child: Text(
      '#$label',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isOverflow ? SpontiColors.textMuted : SpontiColors.primary,
      ),
    ),
  );
}

// Multiple tags selector with add/remove functionality
// Used on create/edit location screen
class TagsSelector extends StatefulWidget {
  const TagsSelector({
    super.key,
    required this.availableTags,
    required this.selectedTags,
    required this.onChanged,
    this.maxSelectable,
    this.label = 'Tags',
  });

  final List<String> availableTags;
  final List<String> selectedTags;
  final ValueChanged<List<String>> onChanged;
  final int? maxSelectable;
  final String label;

  @override
  State<TagsSelector> createState() => _TagsSelectorState();
}

class _TagsSelectorState extends State<TagsSelector> {
  late List<String> _selected;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _showInput = false;

  // Toggle tag selection
  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedTags);
  }

  // Add new tag from input
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Toggle tag selection
  void _toggle(String tag) {
    setState(() {
      if (_selected.contains(tag)) {
        _selected.remove(tag);
      } else {
        final max = widget.maxSelectable;
        if (max != null && _selected.length >= max) return; // Max limit reached
        _selected.add(tag);
      }
    });
    widget.onChanged(_selected);
  }

  void _addCustom() {
    final tag = _controller.text.trim().toLowerCase();
    if (tag.isEmpty) return;
    if (_selected.contains(tag)) {
      _controller.clear();
      return; // Already selected
    }
    final max = widget.maxSelectable;
    if (max != null && _selected.length >= max) {
      _controller.clear();
      _showInput = false;
      return; // Max limit reached
    }

    setState(() {
      _selected.add(tag);
      _controller.clear();
      _showInput = false;
    });
    widget.onChanged(_selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAddMore =
        widget.maxSelectable == null ||
        _selected.length < widget.maxSelectable!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.label, style: theme.textTheme.titleSmall),
            if (widget.maxSelectable != null) ...[
              const SizedBox(width: 6),
              Text(
                '${_selected.length}/${widget.maxSelectable}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),

        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...widget.availableTags.map((tag) {
              final isSelected = _selected.contains(tag);
              return _SelectableTagChip(
                label: tag,
                isSelected: isSelected,
                onTap: () => _toggle(tag),
              );
            }),

            if (canAddMore && !_showInput)
              GestureDetector(
                onTap: () {
                  setState(() => _showInput = true);
                  Future.delayed(
                    const Duration(milliseconds: 50),
                    _focusNode.requestFocus,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: SpontiColors.outline,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: SpontiColors.textMuted),
                      SizedBox(width: 4),
                      Text(
                        'Add Tag',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: SpontiColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_showInput)
              SizedBox(
                width: 120,
                height: 32,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'New tag',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: SpontiColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _addCustom(),
                  textInputAction: TextInputAction.done,
                ),
              ),
          ],
        ),

        if (_selected.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selected.map((tag) {
              return _RemovableTagChip(
                label: tag,
                onRemove: () => _toggle(tag),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

// Individual selectable tag chip
class _SelectableTagChip extends StatelessWidget {
  const _SelectableTagChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? SpontiColors.primary : SpontiColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? SpontiColors.primary : SpontiColors.outline,
        ),
      ),
      child: Text(
        '#$label',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : SpontiColors.textSecondary,
        ),
      ),
    ),
  );
}

class _RemovableTagChip extends StatelessWidget {
  const _RemovableTagChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(left: 10, right: 4, top: 5, bottom: 5),
    decoration: BoxDecoration(
      color: SpontiColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: SpontiColors.primary.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '#$label',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: SpontiColors.primary,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(
            Icons.close_rounded,
            size: 14,
            color: SpontiColors.primary,
          ),
        ),
      ],
    ),
  );
}
