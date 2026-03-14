import 'package:cached_network_image/cached_network_image.dart';
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

class _DetailBody extends StatefulWidget {
  const _DetailBody({required this.location});

  final Location location;

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = widget.location;
    final categoryColor = Color(location.category.colorValue);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        HeroAppBar(location: location, categoryColor: categoryColor),

        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocationNameSection(
                      location: location,
                      categoryColor: categoryColor,
                    ),

                    const SizedBox(height: 20),

                    QuickInfoRow(location: location),

                    if (location.photoUrls.length > 1) ...[
                      const SizedBox(height: 24),
                      _PhotoGallery(
                        photoUrls: location.photoUrls,
                        categoryColor: categoryColor,
                      ),
                    ],

                    if (location.description.isNotEmpty) ...[
                      const SizedBox(height: 24),
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

                    const SizedBox(height: 24),
                    _AnimatedStatsRow(location: location),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- Animated stats with Duolingo-style bounce-in counters ---

class _AnimatedStatsRow extends StatefulWidget {
  const _AnimatedStatsRow({required this.location});
  final Location location;

  @override
  State<_AnimatedStatsRow> createState() => _AnimatedStatsRowState();
}

class _AnimatedStatsRowState extends State<_AnimatedStatsRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            color: SpontiColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SpontiColors.outline),
            boxShadow: [
              BoxShadow(
                color: SpontiColors.shadow.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildStat(
                emoji: '\u{1F4AC}',
                value: widget.location.reviewCount,
                label: 'Reviews',
                delay: 0.0,
                color: SpontiColors.primary,
              ),
              _divider(),
              _buildStat(
                emoji: '\u{1F4CD}',
                value: widget.location.checkInCount,
                label: 'Check-ins',
                delay: 0.15,
                color: SpontiColors.secondary,
              ),
              _divider(),
              _buildStat(
                emoji: '\u{2B50}',
                value: (widget.location.rating * 10).round(),
                label: 'Rating',
                delay: 0.3,
                color: SpontiColors.accent,
                isRating: true,
                rating: widget.location.rating,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 44, color: SpontiColors.outline);

  Widget _buildStat({
    required String emoji,
    required int value,
    required String label,
    required double delay,
    required Color color,
    bool isRating = false,
    double rating = 0,
  }) {
    final interval = Interval(delay, delay + 0.6, curve: Curves.elasticOut);
    final scale = interval.transform(_controller.value).clamp(0.0, 1.0);

    return Expanded(
      child: Transform.scale(
        scale: 0.4 + 0.6 * scale,
        child: Opacity(
          opacity: scale,
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(
                isRating ? rating.toStringAsFixed(1) : '$value',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: SpontiColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Photo Gallery with bouncy press feedback ---

class _PhotoGallery extends StatelessWidget {
  const _PhotoGallery({required this.photoUrls, required this.categoryColor});

  final List<String> photoUrls;
  final Color categoryColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.photo_library_rounded,
                size: 16,
                color: categoryColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Photos',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: SpontiColors.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: SpontiColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${photoUrls.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SpontiColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: photoUrls.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _BouncyPhotoCard(
                url: photoUrls[index],
                categoryColor: categoryColor,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BouncyPhotoCard extends StatefulWidget {
  const _BouncyPhotoCard({required this.url, required this.categoryColor});
  final String url;
  final Color categoryColor;

  @override
  State<_BouncyPhotoCard> createState() => _BouncyPhotoCardState();
}

class _BouncyPhotoCardState extends State<_BouncyPhotoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.categoryColor.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: widget.url,
              width: 240,
              height: 180,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(
                width: 240,
                height: 180,
                color: widget.categoryColor.withValues(alpha: 0.08),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: widget.categoryColor,
                    ),
                  ),
                ),
              ),
              errorWidget: (_, _, _) => Container(
                width: 240,
                height: 180,
                color: SpontiColors.surfaceVariant,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      color: SpontiColors.textMuted,
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Couldn\'t load',
                      style: TextStyle(
                        fontSize: 11,
                        color: SpontiColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
