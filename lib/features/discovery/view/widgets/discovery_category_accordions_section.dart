import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/discovery/viewmodel/discovery_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/category.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

class DiscoveryCategoryAccordionsSection extends ConsumerWidget {
  const DiscoveryCategoryAccordionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(discoveryViewModelProvider);
    final notifier = ref.read(discoveryViewModelProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: SpontiColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SpontiColors.outline),
        boxShadow: [
          BoxShadow(
            color: SpontiColors.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int index = 0; index < discoveryCategories.length; index++) ...[
            if (index > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: SpontiColors.outline,
                indent: 72,
              ),
            DiscoveryCategoryAccordionTile(
              category: discoveryCategories[index],
              isExpanded: state.isCategoryExpanded(discoveryCategories[index]),
              isFirst: index == 0,
              isLast: index == discoveryCategories.length - 1,
              onTap: () => notifier.toggleCategory(discoveryCategories[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class DiscoveryCategoryAccordionTile extends StatelessWidget {
  const DiscoveryCategoryAccordionTile({
    super.key,
    required this.category,
    required this.isExpanded,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final LocationCategory category;
  final bool isExpanded;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    final borderRadius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(20) : Radius.zero,
      bottom: isLast && !isExpanded ? const Radius.circular(20) : Radius.zero,
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: LocationCategoryIcon(
                        category: category,
                        color: color,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      category.discoveryLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: SpontiColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: DiscoveryCategoryAccordionContent(category: category),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class DiscoveryCategoryAccordionContent extends ConsumerWidget {
  const DiscoveryCategoryAccordionContent({
    super.key,
    required this.category,
  });

  final LocationCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spotsAsync = ref.watch(categoryTopSpotsProvider(category));

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
      child: spotsAsync.when(
        loading: () => const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (e, s) => const SizedBox(
          height: 80,
          child: Center(
            child: Text(
              'Could not load spots',
              style: TextStyle(color: SpontiColors.textMuted),
            ),
          ),
        ),
        data: (spots) {
          if (spots.isEmpty) {
            return const SizedBox(
              height: 80,
              child: Center(
                child: Text(
                  'No spots yet',
                  style: TextStyle(color: SpontiColors.textMuted),
                ),
              ),
            );
          }
          return SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: spots.length,
              separatorBuilder: (_, i) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _SpotCard(
                location: spots[index],
                onTap: () {
                  ref.read(pendingLocationProvider.notifier).state =
                      spots[index];
                  context.go(RouteName.location);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SpotCard extends StatelessWidget {
  const _SpotCard({required this.location, this.onTap});

  final Location location;
  final VoidCallback? onTap;

  static const _cardWidth = 160.0;
  static const _imageHeight = 140.0;

  @override
  Widget build(BuildContext context) {
    final categoryColor = Color(location.category.colorValue);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: _cardWidth,
                height: _imageHeight,
                child: location.hasPhotos
                    ? CachedNetworkImage(
                        imageUrl: location.primaryPhoto,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) =>
                            CategoryShimmer(color: categoryColor),
                        errorWidget: (ctx, url, err) =>
                            CategoryGradient(category: location.category),
                      )
                    : CategoryGradient(category: location.category),
              ),
            ),
            const SizedBox(height: 8),
            // Name
            Text(
              location.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: SpontiColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            // Price + saves row
            Row(
              children: [
                Text(
                  location.priceRange.symbol,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: SpontiColors.textSecondary,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.favorite_rounded,
                  size: 11,
                  color: SpontiColors.primary,
                ),
                const SizedBox(width: 3),
                Text(
                  '${location.checkInCount}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: SpontiColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
