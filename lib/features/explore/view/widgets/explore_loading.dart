import 'package:flutter/material.dart';
import 'package:sponti/core/widgets/app_shimmer.dart';

class LoadingList extends StatelessWidget {
  const LoadingList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 6),
      itemCount: 4,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: LoadingCard(),
      ),
    );
  }
}

class LoadingCard extends StatelessWidget {
  const LoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppShimmer(height: 120, width: double.infinity, borderRadius: 18),
          const SizedBox(height: 10),
          const AppShimmer(height: 14, width: 180, borderRadius: 8),
          const SizedBox(height: 8),
          const AppShimmer(height: 12, width: 220, borderRadius: 8),
          const SizedBox(height: 8),
          const AppShimmer(height: 12, width: 96, borderRadius: 8),
        ],
      ),
    );
  }
}
