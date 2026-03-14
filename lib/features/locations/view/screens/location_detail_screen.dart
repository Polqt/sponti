import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_empty_state.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/hero_app_bar.dart';
import 'package:sponti/features/locations/view/widgets/detail_info.dart';
import 'package:sponti/features/locations/view/widgets/location_badges.dart';
import 'package:sponti/features/locations/view/widgets/location_header.dart';
import 'package:sponti/features/locations/view/widgets/operating_hours_widget.dart';
import 'package:sponti/features/locations/view/widgets/tags_selector.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

class LocationDetailScreen extends ConsumerWidget {
  const LocationDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(locationDetailProvider(id));

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      body: locationAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: SpontiColors.primary),
        ),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(locationDetailProvider(id)),
        ),
        data: (location) => _DetailBody(location: location),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.location});

  final Location location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = Color(location.category.colorValue);

    return CustomScrollView(
      slivers: [
        HeroAppBar(location: location, categoryColor: categoryColor),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          sliver: SliverList.list(
            children: [
              LocationNameSection(
                location: location,
                categoryColor: categoryColor,
              ),

              const SizedBox(height: 20),

              QuickInfoRow(location: location),

              if (location.description.isNotEmpty) ...[
                const SizedBox(height: 20),
                SectionCard(
                  title: 'About',
                  icon: Icons.info_outline_rounded,
                  children: [
                    Text(
                      location.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: SpontiColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ],

              if (location.operatingHours != null) ...[
                const SizedBox(height: 16),
                OperatingHoursWidget(hours: location.operatingHours!),
              ],

              const SizedBox(height: 16),
              SectionCard(
                title: 'Location',
                icon: Icons.location_on_outlined,
                children: [
                  InfoRow(
                    icon: Icons.place_outlined,
                    label: 'Address',
                    value: location.address,
                  ),
                  if (location.landmark != null) ...[
                    const SizedBox(height: 14),
                    InfoRow(
                      icon: Icons.flag_outlined,
                      label: 'Landmark',
                      value: location.landmark!,
                    ),
                  ],
                ],
              ),

              if (location.hasContact) ...[
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Contact',
                  icon: Icons.call_outlined,
                  children: [
                    if (location.contactNumber != null)
                      InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: location.contactNumber!,
                      ),
                    if (location.websiteUrl != null) ...[
                      if (location.contactNumber != null)
                        const SizedBox(height: 14),
                      InfoRow(
                        icon: Icons.language_rounded,
                        label: 'Website',
                        value: location.websiteUrl!,
                      ),
                    ],
                    if (location.instagramHandle != null) ...[
                      const SizedBox(height: 14),
                      InfoRow(
                        icon: Icons.camera_alt_outlined,
                        label: 'Instagram',
                        value: '@${location.instagramHandle}',
                      ),
                    ],
                  ],
                ),
              ],

              if (location.tags.isNotEmpty) ...[
                const SizedBox(height: 20),
                TagsDisplay(tags: location.tags),
              ],

              const SizedBox(height: 20),
              StatsRow(location: location),
            ],
          ),
        ),
      ],
    );
  }
}
