import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/location_comparison/viewmodel/location_comparison_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/location_card.dart';

class FavoriteListItem extends ConsumerStatefulWidget {
  const FavoriteListItem({required this.location, super.key});

  final Location location;

  @override
  ConsumerState<FavoriteListItem> createState() => _FavoriteListItemState();
}

class _FavoriteListItemState extends ConsumerState<FavoriteListItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final pinnedIds = ref.watch(pinnedComparisonIdSetProvider);
    final isPinned = pinnedIds.contains(widget.location.id);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () => context.push(RouteName.locationDetailPath(widget.location.id)),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: SpontiColors.shadow.withValues(alpha: _isPressed ? 0.03 : 0.05),
                blurRadius: _isPressed ? 12 : 20,
                offset: Offset(0, _isPressed ? 2 : 4),
              ),
              BoxShadow(
                color: SpontiColors.shadow.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: LocationCard(
            key: ValueKey(widget.location.id),
            location: widget.location,
            variant: LocationCardVariant.fullWidth,
            onTap: null,
            isPinnedForComparison: isPinned,
            onComparisonToggle: () async {
              final success = await ref
                  .read(pinnedComparisonIdsProvider.notifier)
                  .togglePin(widget.location.id);
              if (!context.mounted) return;

              if (!success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You can compare up to 3 locations only.'),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
