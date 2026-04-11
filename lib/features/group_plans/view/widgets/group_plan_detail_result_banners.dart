import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/category.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

class GroupPlanDecidedBanner extends ConsumerWidget {
  const GroupPlanDecidedBanner({
    required this.winningLocationId,
    super.key,
  });

  final String? winningLocationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = winningLocationId != null
        ? ref.watch(locationDetailProvider(winningLocationId!)).valueOrNull
        : null;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF5FFF9),
            SpontiColors.success.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: SpontiColors.success.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: SpontiColors.success.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WinningLocationHero(location: location),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: SpontiColors.success.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: SpontiColors.success,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plan decided',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: SpontiColors.success,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "You're going here!",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: SpontiColors.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  location?.name ?? winningLocationId ?? '-',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: SpontiColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                if (location != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _BannerMetaPill(
                        icon: Icons.place_rounded,
                        label: location.address,
                      ),
                      _BannerMetaPill(
                        icon: location.category.icon,
                        label: location.category.label,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                if (winningLocationId != null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.push(
                        RouteName.locationDetailPath(winningLocationId!),
                      ),
                      icon: const Icon(Icons.place_rounded, size: 16),
                      label: const Text('View location'),
                      style: FilledButton.styleFrom(
                        backgroundColor: SpontiColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
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

class GroupPlanCancelledBanner extends StatelessWidget {
  const GroupPlanCancelledBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SpontiColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SpontiColors.error.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: SpontiColors.error.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cancel_rounded,
              color: SpontiColors.error,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan cancelled',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: SpontiColors.error,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'This plan was cancelled and is no longer active.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SpontiColors.textSecondary,
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

class _WinningLocationHero extends StatelessWidget {
  const _WinningLocationHero({required this.location});

  final Location? location;

  @override
  Widget build(BuildContext context) {
    final category = location?.category ?? LocationCategory.food;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SizedBox(
        width: double.infinity,
        height: 164,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (location?.hasPhotos == true)
              Image.network(
                location!.primaryPhoto,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => CategoryGradient(category: category),
              )
            else
              CategoryGradient(category: category),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.38),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Winning pick',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerMetaPill extends StatelessWidget {
  const _BannerMetaPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: SpontiColors.success.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: SpontiColors.success),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SpontiColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
