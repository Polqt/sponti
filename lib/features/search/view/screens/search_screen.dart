import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/utils/formatters.dart';
import 'package:sponti/core/widgets/app_empty_state.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/search/viewmodel/search_viewmodel.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      ref.read(searchQueryProvider.notifier).state = value;
    });
  }

  void _clearQuery() {
    _debounce?.cancel();
    _controller.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final results = resultsAsync.valueOrNull ?? const <Location>[];
    final isSearching = query.trim().length >= 2;

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFFCF7),
              const Color(0xFFF7F2EA),
              SpontiColors.surface,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              left: -40,
              child: _GlowOrb(
                size: 220,
                color: SpontiColors.primary.withValues(alpha: 0.10),
              ),
            ),
            Positioned(
              top: 120,
              right: -50,
              child: _GlowOrb(
                size: 180,
                color: SpontiColors.secondary.withValues(alpha: 0.10),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final contentWidth = constraints.maxWidth < 680
                      ? constraints.maxWidth
                      : 680.0;

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentWidth),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                            child: _SearchTopBar(
                              controller: _controller,
                              resultsAsync: resultsAsync,
                              onChanged: _onQueryChanged,
                              onClear: _clearQuery,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                            child: _SearchStatusStrip(
                              query: query,
                              resultCount: results.length,
                              isSearching: isSearching,
                            ),
                          ),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: _buildBody(
                                context: context,
                                query: query,
                                resultsAsync: resultsAsync,
                                results: results,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required String query,
    required AsyncValue<List<Location>> resultsAsync,
    required List<Location> results,
  }) {
    if (query.trim().length < 2) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: _SearchWelcomeState(),
      );
    }

    if (resultsAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: AppEmptyState(
          emoji: '\u{1F615}',
          title: 'Search failed',
          subtitle: resultsAsync.error.toString(),
        ),
      );
    }

    if (resultsAsync.isLoading && results.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: SpontiColors.primary),
      );
    }

    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: AppEmptyState(
          emoji: '\u{1FAE5}',
          title: 'No matches found',
          subtitle: 'Try a shorter name, a category, or a nearby landmark.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final location = results[index];
        return _SearchResultCard(
          location: location,
          index: index,
          onTap: () => context.push(RouteName.locationDetailPath(location.id)),
        );
      },
    );
  }
}

class _SearchTopBar extends StatelessWidget {
  const _SearchTopBar({
    required this.controller,
    required this.resultsAsync,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final AsyncValue<List<Location>> resultsAsync;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _FrostButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => context.pop(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FrostSearchField(
                controller: controller,
                resultsAsync: resultsAsync,
                onChanged: onChanged,
                onClear: onClear,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Search',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: SpontiColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Find cafes, parks, and low-key gems nearby.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: SpontiColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
      ),
    );
  }
}

class _FrostButton extends StatelessWidget {
  const _FrostButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Material(
          color: Colors.white.withValues(alpha: 0.58),
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
                boxShadow: [
                  BoxShadow(
                    color: SpontiColors.shadow.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: SpontiColors.textPrimary,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FrostSearchField extends StatelessWidget {
  const _FrostSearchField({
    required this.controller,
    required this.resultsAsync,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final AsyncValue<List<Location>> resultsAsync;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.85),
            ),
            boxShadow: [
              BoxShadow(
                color: SpontiColors.shadow.withValues(alpha: 0.035),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: SpontiColors.textSecondary.withValues(alpha: 0.85),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: 'Search spots, cafes, parks',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SpontiColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: SpontiColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  cursorColor: SpontiColors.primary,
                ),
              ),
              if (resultsAsync.isLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: SpontiColors.primary,
                    ),
                  ),
                ),
              if (controller.text.isNotEmpty)
                GestureDetector(
                  onTap: onClear,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: SpontiColors.textPrimary.withValues(alpha: 0.07),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: SpontiColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchStatusStrip extends StatelessWidget {
  const _SearchStatusStrip({
    required this.query,
    required this.resultCount,
    required this.isSearching,
  });

  final String query;
  final int resultCount;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  isSearching
                      ? '$resultCount matches for "$query"'
                      : 'Trending near you',
                  key: ValueKey<String>(isSearching ? query : 'trending'),
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: SpontiColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ),
          if (!isSearching) ...[
            const SizedBox(width: 16),
            const _MoodPill(label: 'Fresh', icon: Icons.auto_awesome),
          ],
        ],
      ),
    );
  }
}

class _SearchWelcomeState extends StatelessWidget {
  const _SearchWelcomeState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SearchSuggestionTile(
          title: 'Coffee and brunch',
          subtitle: 'Soft spots for slow mornings',
          color: Color(0xFF9E6A45),
          icon: Icons.local_cafe_rounded,
        ),
        SizedBox(height: 14),
        _SearchSuggestionTile(
          title: 'Parks and walks',
          subtitle: 'Open air picks to reset your day',
          color: Color(0xFF487B53),
          icon: Icons.park_rounded,
        ),
        SizedBox(height: 14),
        _SearchSuggestionTile(
          title: 'Hidden gems',
          subtitle: 'Quiet favorites people usually miss',
          color: Color(0xFF2C8C8E),
          icon: Icons.bolt_rounded,
        ),
      ],
      ),
    );
  }
}

class _SearchSuggestionTile extends StatelessWidget {
  const _SearchSuggestionTile({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.70),
                color.withValues(alpha: 0.10),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: SpontiColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: SpontiColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_outward_rounded,
                color: SpontiColors.textSecondary.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.location,
    required this.index,
    required this.onTap,
  });

  final Location location;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final categoryColor = Color(location.category.colorValue);

    return TweenAnimationBuilder<double>(
      key: ValueKey(location.id),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.88)),
            boxShadow: [
              BoxShadow(
                color: SpontiColors.shadow.withValues(alpha: 0.045),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 210,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (location.hasPhotos)
                      CachedNetworkImage(
                        imageUrl: location.primaryPhoto,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => _SearchImageFallback(
                          color: categoryColor,
                          icon: location.category.icon,
                        ),
                      )
                    else
                      _SearchImageFallback(
                        color: categoryColor,
                        icon: location.category.icon,
                      ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.06),
                            Colors.black.withValues(alpha: 0.10),
                            Colors.black.withValues(alpha: 0.52),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: _CategoryChip(location: location),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _GlassTag(
                        icon: location.isOpenNow
                            ? Icons.radio_button_checked_rounded
                            : Icons.schedule_rounded,
                        label: location.isOpenNow ? 'Open' : 'Closed',
                        foreground: location.isOpenNow
                            ? const Color(0xFF1E9E61)
                            : Colors.white,
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                  letterSpacing: -0.8,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _GlassTag(
                                icon: Icons.star_rounded,
                                label:
                                    '${SpontiFormatter.rating(location.rating)} (${SpontiFormatter.reviewCount(location.reviewCount)})',
                              ),
                              _GlassTag(
                                icon: Icons.payments_rounded,
                                label: location.priceRange.label,
                              ),
                              if (location.distanceKm != null)
                                _GlassTag(
                                  icon: Icons.near_me_rounded,
                                  label: SpontiFormatter.distance(
                                    location.distanceKm!,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: SpontiColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    if (location.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        location.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: SpontiColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (location.isHiddenGem)
                                _MetaPill(
                                  icon: Icons.auto_awesome_rounded,
                                  label: 'Hidden gem',
                                  color: SpontiColors.accent,
                                ),
                              if (location.hasWifi)
                                const _MetaPill(
                                  icon: Icons.wifi_rounded,
                                  label: 'Wi-Fi',
                                  color: SpontiColors.secondary,
                                ),
                              if (location.isPetFriendly)
                                const _MetaPill(
                                  icon: Icons.pets_rounded,
                                  label: 'Pet friendly',
                                  color: Color(0xFF7B4F2E),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_outward_rounded,
                            color: categoryColor,
                          ),
                        ),
                      ],
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

class _SearchImageFallback extends StatelessWidget {
  const _SearchImageFallback({
    required this.color,
    required this.icon,
  });

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.95),
            color.withValues(alpha: 0.58),
            const Color(0xFFF3E7DA),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 72,
          color: Colors.white.withValues(alpha: 0.82),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.location});

  final Location location;

  @override
  Widget build(BuildContext context) {
    final color = Color(location.category.colorValue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(location.category.icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            location.category.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassTag extends StatelessWidget {
  const _GlassTag({
    required this.icon,
    required this.label,
    this.foreground = Colors.white,
  });

  final IconData icon;
  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: foreground == Colors.white ? 0.14 : 0.72),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodPill extends StatelessWidget {
  const _MoodPill({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: SpontiColors.textPrimary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
