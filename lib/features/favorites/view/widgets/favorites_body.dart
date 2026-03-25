import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_empty_state.dart';
import 'package:sponti/features/favorites/view/widgets/favorite_list_item.dart';
import 'package:sponti/features/favorites/view/widgets/favorites_filter.dart';
import 'package:sponti/features/locations/model/location.dart';

class _StaggeredAnimation extends StatefulWidget {
  const _StaggeredAnimation({
    required this.child,
    required this.index,
  });

  final Widget child;
  final int index;

  @override
  State<_StaggeredAnimation> createState() => _StaggeredAnimationState();
}

class _StaggeredAnimationState extends State<_StaggeredAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

class FavoritesBody extends StatelessWidget {
  const FavoritesBody({
    required this.favoriteIdsAsync,
    required this.favoriteLocationsAsync,
    required this.searchQuery,
    required this.selectedCategory,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    super.key,
  });

  final AsyncValue<List<String>> favoriteIdsAsync;
  final AsyncValue<List<Location>> favoriteLocationsAsync;
  final String searchQuery;
  final LocationCategory? selectedCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<LocationCategory?> onCategoryChanged;

  bool get _isLoading =>
      favoriteIdsAsync.isLoading || favoriteLocationsAsync.isLoading;

  Object? get _error => favoriteIdsAsync.error ?? favoriteLocationsAsync.error;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 600;
    final horizontalPadding = isTablet ? 32.0 : 20.0;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: SpontiColors.primary),
      );
    }

    if (_error != null) {
      return AppErrorState(message: _error.toString());
    }

    final favoriteLocations =
        favoriteLocationsAsync.valueOrNull ?? const <Location>[];
    final filteredLocations = filterLocations(
      favoriteLocations,
      searchQuery,
      selectedCategory,
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StaggeredAnimation(
                  index: 0,
                  child: Text(
                    'Saved spots',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                _StaggeredAnimation(
                  index: 1,
                  child: Text(
                    'Your collection of must-visit places.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: SpontiColors.textSecondary,
                        ),
                  ),
                ),
                const SizedBox(height: 24),
                _StaggeredAnimation(
                  index: 2,
                  child: FavoritesCategoryFilters(
                    selectedCategory: selectedCategory,
                    onChanged: onCategoryChanged,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        if (favoriteLocations.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: AppEmptyState(
              emoji: '🦗',
              title: 'your list is crickets',
              subtitle:
                  "those bookmark icons aren't just decorative. "
                  'go poke some spots and start a collection.',
              actionLabel: 'find something good',
              onAction: () => context.go(RouteName.location),
            ),
          )
        else if (filteredLocations.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: AppEmptyState(
              emoji: '\u{1F50E}',
              title: 'No matches found',
              subtitle:
                  'Try a different category from your saved list.',
            ),
          )
        else ..._buildDynamicLayout(
            locations: filteredLocations,
            horizontalPadding: horizontalPadding,
            isTablet: isTablet,
          ),
      ],
    );
  }

  List<Widget> _buildDynamicLayout({
    required List<Location> locations,
    required double horizontalPadding,
    required bool isTablet,
  }) {
    if (locations.length == 1) {
      return [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 32),
          sliver: SliverToBoxAdapter(
            child: _StaggeredAnimation(
              index: 0,
              child: FavoriteListItem(location: locations.first),
            ),
          ),
        ),
      ];
    }

    if (locations.length == 2) {
      return [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _StaggeredAnimation(
                index: index,
                child: Padding(
                  padding: EdgeInsets.only(bottom: index == 0 ? 16 : 0),
                  child: FavoriteListItem(location: locations[index]),
                ),
              ),
              childCount: 2,
            ),
          ),
        ),
      ];
    }

    final featured = locations.first;
    final remaining = locations.skip(1).toList();

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 12),
        sliver: SliverToBoxAdapter(
          child: _StaggeredAnimation(
            index: 0,
            child: _FeaturedCard(location: featured),
          ),
        ),
      ),
      if (remaining.length == 1)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 32),
          sliver: SliverToBoxAdapter(
            child: _StaggeredAnimation(
              index: 1,
              child: FavoriteListItem(location: remaining.first),
            ),
          ),
        )
      else if (remaining.length == 2)
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          sliver: SliverToBoxAdapter(
            child: _StaggeredAnimation(
              index: 1,
              child: _TwoColumnRow(
                locations: remaining,
                isTablet: isTablet,
              ),
            ),
          ),
        )
      else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 32),
            sliver: isTablet
              ? SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.4,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _StaggeredAnimation(
                      index: index + 1,
                      child: FavoriteListItem(location: remaining[index]),
                    ),
                    childCount: remaining.length,
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      Widget child;
                      if (index.isEven && index + 1 < remaining.length) {
                        child = Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _TwoColumnRow(
                            locations: [remaining[index], remaining[index + 1]],
                            isTablet: false,
                          ),
                        );
                      } else if (index.isOdd) {
                        return const SizedBox.shrink();
                      } else {
                        child = Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: FavoriteListItem(location: remaining[index]),
                        );
                      }
                      return _StaggeredAnimation(
                        index: index + 1,
                        child: child,
                      );
                    },
                    childCount: remaining.length,
                  ),
                ),
        ),
    ];
  }
}

class _FeaturedCard extends StatefulWidget {
  const _FeaturedCard({required this.location});

  final Location location;

  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () => context.push(RouteName.locationDetailPath(widget.location.id)),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                Color(widget.location.category.colorValue).withValues(alpha: 0.15),
                Color(widget.location.category.colorValue).withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Color(widget.location.category.colorValue).withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(widget.location.category.colorValue).withValues(
                  alpha: _isPressed ? 0.05 : 0.1,
                ),
                blurRadius: _isPressed ? 12 : 20,
                offset: Offset(0, _isPressed ? 3 : 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Icon(
                  widget.location.category.icon,
                  size: 160,
                  color: Color(widget.location.category.colorValue).withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Color(widget.location.category.colorValue),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.location.category.emoji,
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                widget.location.category.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (widget.location.isHiddenGem)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: SpontiColors.accent.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 16,
                              color: SpontiColors.accent,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      widget.location.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: SpontiColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.location.rating}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: SpontiColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.location.priceRange.symbol,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: SpontiColors.textSecondary,
                          ),
                        ),
                        if (widget.location.isOpenNow) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: SpontiColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Open now',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: SpontiColors.success,
                              ),
                            ),
                          ),
                        ],
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

class _TwoColumnRow extends StatelessWidget {
  const _TwoColumnRow({
    required this.locations,
    required this.isTablet,
  });

  final List<Location> locations;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FavoriteListItem(location: locations[0]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FavoriteListItem(location: locations[1]),
        ),
      ],
    );
  }
}
