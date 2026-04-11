import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

class GroupPlanDecidedBanner extends ConsumerWidget {
  const GroupPlanDecidedBanner({
    required this.winningLocationId,
    super.key,
  });

  final String? winningLocationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationName = winningLocationId != null
        ? ref.watch(locationDetailProvider(winningLocationId!)).valueOrNull?.name
        : null;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
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
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: SpontiColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: SpontiColors.success,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "You're going here!",
            style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: SpontiColors.success,
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Winning location',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: SpontiColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            locationName ?? winningLocationId ?? '-',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: SpontiColors.textPrimary,
                  letterSpacing: -0.4,
                ),
          ),
          if (winningLocationId != null) ...[
            const SizedBox(height: 16),
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
