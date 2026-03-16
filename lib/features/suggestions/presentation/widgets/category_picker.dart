import 'package:flutter/material.dart';

const _selectedBorderColor = Color(0xFF111111);
const _unselectedBorderColor = Color(0xFFE5E5E5);

enum SpotCategory {
  cafes('cafes', '☕'),
  munch('munch', '🌮'),
  bars('bars', '🍹'),
  fun('fun', '🎯'),
  stroll('stroll', '🌿'),
  arts('arts', '🎨');

  const SpotCategory(this.label, this.emoji);
  final String label;
  final String emoji;
}

class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final SpotCategory? selected;
  final ValueChanged<SpotCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: SpotCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = SpotCategory.values[index];
          final isSelected = category == selected;

          return InkWell(
            key: ValueKey(category.name),
            borderRadius: BorderRadius.circular(12),
            onTap: () => onSelected(category),
            child: SizedBox(
              width: 52,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? _selectedBorderColor
                            : _unselectedBorderColor,
                        width: isSelected ? 2 : 0.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
