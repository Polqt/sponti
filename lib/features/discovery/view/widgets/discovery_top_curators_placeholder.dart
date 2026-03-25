import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';

class DiscoveryTopCuratorsPlaceholder extends StatelessWidget {
  const DiscoveryTopCuratorsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) => Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: SpontiColors.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(color: SpontiColors.outline),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 32,
                color: SpontiColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 60,
              height: 10,
              decoration: BoxDecoration(
                color: SpontiColors.surfaceVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
