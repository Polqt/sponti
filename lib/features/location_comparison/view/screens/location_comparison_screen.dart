import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_empty_state.dart';
import 'package:sponti/features/location_comparison/view/widgets/location_comparison_card.dart';
import 'package:sponti/features/location_comparison/viewmodel/location_comparison_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';

class LocationComparisonScreen extends ConsumerWidget {
  const LocationComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedIdsAsync = ref.watch(pinnedComparisonIdsProvider);
    final locationsAsync = ref.watch(pinnedComparisonLocationsProvider);

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      foregroundColor: SpontiColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compare Spots',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                        ),
                        pinnedIdsAsync.maybeWhen(
                          data: (ids) => Text(
                            ids.isEmpty
                                ? 'Pin spots from any location card'
                                : '${ids.length} of $kLocationComparisonMaxPins spots pinned',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: SpontiColors.textMuted),
                          ),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  pinnedIdsAsync.maybeWhen(
                    data: (ids) => ids.isNotEmpty
                        ? TextButton(
                            onPressed: () => ref
                                .read(pinnedComparisonIdsProvider.notifier)
                                .clear(),
                            style: TextButton.styleFrom(
                              foregroundColor: SpontiColors.error,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            child: const Text('Clear all'),
                          )
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: pinnedIdsAsync.when(
                loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: SpontiColors.primary),
                ),
                error: (e, _) => AppErrorState(message: e.toString()),
                data: (pinnedIds) {
                  if (pinnedIds.isEmpty) {
                    return const AppEmptyState(
                      emoji: '📌',
                      title: 'Nothing pinned yet',
                      subtitle:
                          'Tap the pin icon on any location to add it here. Pin 2–3 to compare.',
                    );
                  }

                  if (locationsAsync.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: SpontiColors.primary,
                      ),
                    );
                  }

                  if (locationsAsync.hasError) {
                    return AppErrorState(
                      message: locationsAsync.error.toString(),
                    );
                  }

                  final locations =
                      locationsAsync.valueOrNull ?? const <Location>[];

                  if (locations.length < kLocationComparisonMinPins) {
                    return const AppEmptyState(
                      emoji: '🧭',
                      title: 'Need at least 2',
                      subtitle:
                          'Pin one more location to start the comparison.',
                    );
                  }

                  return _ComparisonBody(locations: locations, ref: ref);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonBody extends StatelessWidget {
  const _ComparisonBody({
    required this.locations,
    required this.ref,
  });

  final List<Location> locations;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            itemCount: locations.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final location = locations[index];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => context.push(
                      RouteName.locationDetailPath(location.id),
                    ),
                    child: LocationComparisonCard(location: location),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => ref
                        .read(pinnedComparisonIdsProvider.notifier)
                        .togglePin(location.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: SpontiColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: SpontiColors.error.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.push_pin_outlined,
                            size: 13,
                            color: SpontiColors.error,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Unpin',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: SpontiColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => context.pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: SpontiColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
