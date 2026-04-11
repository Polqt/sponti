import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_empty_state.dart';
import 'package:sponti/features/check_in/models/checkins.dart';
import 'package:sponti/features/check_in/viewmodel/checkins_viewmodel.dart';
import 'package:sponti/features/location_comparison/viewmodel/location_comparison_viewmodel.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';
import 'package:sponti/features/locations/view/widgets/location_card.dart';
import 'package:sponti/features/streaks/view/widgets/checkin_streak_card.dart';
import 'package:sponti/features/streaks/viewmodel/checkin_streak_viewmodel.dart';

class MyCheckInsScreen extends ConsumerWidget {
  const MyCheckInsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkInsAsync = ref.watch(myCheckInsProvider);
    final notifier = ref.read(myCheckInsProvider.notifier);
    final streakAsync = ref.watch(checkInStreakProvider);

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      appBar: AppBar(
        backgroundColor: SpontiColors.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text('My Check-ins'),
      ),
      body: checkInsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: SpontiColors.primary),
        ),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(myCheckInsProvider),
        ),
        data: (checkIns) {
          final streakWidget = streakAsync.maybeWhen(
            data: (streak) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: CheckInStreakCard(streak: streak),
            ),
            orElse: () => const SizedBox.shrink(),
          );

          if (checkIns.isEmpty) {
            return Column(
              children: [
                streakWidget,
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: AppEmptyState(
                    emoji: '📍',
                    title: 'No check-ins yet',
                    subtitle: 'Places you mark as visited will show up here.',
                  ),
                ),
              ],
            );
          }

          final showFooter = notifier.hasMore;
          return Column(
            children: [
              streakWidget,
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: checkIns.length + (showFooter ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    if (index == checkIns.length) {
                      return _LoadMoreCheckInsButton(
                        onTap: notifier.fetchNextPage,
                      );
                    }
                    return _MyCheckInItem(
                      key: ValueKey(checkIns[index].id),
                      checkIn: checkIns[index],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoadMoreCheckInsButton extends StatefulWidget {
  const _LoadMoreCheckInsButton({required this.onTap});

  final Future<String?> Function() onTap;

  @override
  State<_LoadMoreCheckInsButton> createState() =>
      _LoadMoreCheckInsButtonState();
}

class _LoadMoreCheckInsButtonState extends State<_LoadMoreCheckInsButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: _loading
            ? null
            : () async {
                final messenger = ScaffoldMessenger.of(context);
                setState(() => _loading = true);
                final error = await widget.onTap();
                if (!mounted) return;
                setState(() => _loading = false);
                if (error != null) {
                  messenger.showSnackBar(SnackBar(content: Text(error)));
                }
              },
        child: _loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: SpontiColors.primary,
                ),
              )
            : const Text(
                'Load more',
                style: TextStyle(
                  color: SpontiColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }
}

class _MyCheckInItem extends ConsumerWidget {
  const _MyCheckInItem({
    required this.checkIn,
    super.key,
  });

  final CheckIn checkIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(locationDetailProvider(checkIn.locationId));
    final pinnedIds = ref.watch(pinnedComparisonIdSetProvider);
    final formattedDate = DateFormat.yMMMd().format(checkIn.createdAt);
    final note = checkIn.note?.trim();
    final hasVisibleNote =
        note != null && note.isNotEmpty && !note.startsWith('__seed_beta__');

    return locationAsync.when(
      loading: () => const SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(color: SpontiColors.primary),
        ),
      ),
      error: (error, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SpontiColors.outline),
        ),
        child: Text(
          'Could not load this location.\n$error',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      data: (location) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocationCard(
            key: ValueKey(location.id),
            location: location,
            variant: LocationCardVariant.fullWidth,
            onTap: () => context.push(RouteName.locationDetailPath(location.id)),
            isPinnedForComparison: pinnedIds.contains(location.id),
            onComparisonToggle: () async {
              final success = await ref
                  .read(pinnedComparisonIdsProvider.notifier)
                  .togglePin(location.id);
              if (!context.mounted || success) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You can compare up to 3 locations only.'),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: SpontiColors.info,
                ),
                const SizedBox(width: 8),
                Text(
                  'Checked in on $formattedDate',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SpontiColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (checkIn.photos.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Text(
                    '${checkIn.photos.length} photo${checkIn.photos.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SpontiColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasVisibleNote) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                note,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: SpontiColors.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
