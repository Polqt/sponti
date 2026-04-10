import 'package:flutter/material.dart';
import 'package:sponti/core/widgets/app_shimmer.dart';

/// Loading shimmer state for the profile screen.
class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Center(child: AppShimmer.circle(size: 96)),
          const SizedBox(height: 16),
          Center(child: AppShimmer(height: 20, width: 160)),
          const SizedBox(height: 8),
          Center(child: AppShimmer(height: 14, width: 100)),
          const SizedBox(height: 24),
          AppShimmer(height: 76, borderRadius: 16),
          const SizedBox(height: 28),
          for (int i = 0; i < 5; i++) ...[
            AppShimmer(height: 56, borderRadius: 14),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
