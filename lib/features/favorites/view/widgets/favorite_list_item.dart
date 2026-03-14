import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/favorites/viewmodel/favorites_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/location_card.dart';

class FavoriteListItem extends ConsumerWidget {
  const FavoriteListItem({required this.location, super.key});

  final Location location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: SpontiColors.shadow.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          LocationCard(
            key: ValueKey(location.id),
            location: location,
            variant: LocationCardVariant.fullWidth,
            isSaved: true,
            onTap: () =>
                context.push(RouteName.locationDetailPath(location.id)),
            onSaveToggle: () =>
                ref.read(favoriteIdsProvider.notifier).remove(location.id),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            decoration: const BoxDecoration(
              color: SpontiColors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Saved for a quick plan later',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SpontiColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => ref
                      .read(favoriteIdsProvider.notifier)
                      .remove(location.id),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(
                    foregroundColor: SpontiColors.error,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
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
