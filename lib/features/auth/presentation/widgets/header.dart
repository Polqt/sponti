import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'Sponti',
          style: theme.textTheme.displayLarge?.copyWith(
            color: SpontiColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Discover Bacolod, spontaneously.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: SpontiColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
