import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/discovery/viewmodel/discovery_viewmodel.dart';
import 'package:sponti/features/locations/utils/location_ranking.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

class DiscoveryForYouGrid extends ConsumerWidget {
  const DiscoveryForYouGrid({super.key, required this.cards});

  final List<DiscoveryCardData> cards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      key: const ValueKey('for-you-grid'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 18,
        mainAxisExtent: 262,
      ),
      itemBuilder: (context, index) => DiscoveryTopPickCard(
        card: cards[index],
        onTap: () => _onCardTap(context, ref, cards[index]),
      ),
    );
  }

  void _onCardTap(BuildContext context, WidgetRef ref, DiscoveryCardData card) {
    final ranking = LocationRanking.fromTitle(card.title);
    if (ranking != null) {
      ref.read(locationFilterProvider.notifier).setRanking(ranking);
      ref.read(locationFilterProvider.notifier).setCategory(null);
      context.go(RouteName.location);
    }
  }
}

class DiscoveryTopPickCard extends StatelessWidget {
  const DiscoveryTopPickCard({
    super.key,
    required this.card,
    required this.onTap,
  });

  final DiscoveryCardData card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFF4EFF4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SpontiColors.outline),
            boxShadow: [
              BoxShadow(
                color: SpontiColors.shadow.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: DiscoveryCardImagePlaceholder(card: card),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: card.chipColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: card.chipColor.withValues(alpha: 0.34),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            card.title.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      card.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: SpontiColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DiscoveryCardImagePlaceholder extends StatelessWidget {
  const DiscoveryCardImagePlaceholder({super.key, required this.card});

  final DiscoveryCardData card;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: card.placeholderColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.image_outlined,
                size: 18,
                color: SpontiColors.textSecondary,
              ),
            ),
          ),
          Positioned(
            right: -18,
            top: -8,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    card.icon,
                    color: Colors.white.withValues(alpha: 0.92),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
