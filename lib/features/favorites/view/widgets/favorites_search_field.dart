import 'package:flutter/material.dart';

class FavoritesSearchField extends StatelessWidget {
  const FavoritesSearchField({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey(initialValue),
      initialValue: initialValue,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search saved spots',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: initialValue.isEmpty
            ? null
            : IconButton(
                onPressed: () => onChanged(''),
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }
}
