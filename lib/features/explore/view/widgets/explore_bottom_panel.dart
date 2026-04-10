import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/explore/view/widgets/explore_amenity_filters.dart';
import 'package:sponti/features/explore/view/widgets/explore_bottom_panel_frame.dart';
import 'package:sponti/features/explore/view/widgets/explore_bottom_panel_list.dart';
import 'package:sponti/features/explore/viewmodel/explore_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';

class ExploreBottomPanel extends ConsumerStatefulWidget {
  const ExploreBottomPanel({
    super.key,
    required this.locationsAsync,
    required this.locations,
    required this.selectedIndex,
    required this.onExpandChanged,
    required this.onSelectLocation,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.filter,
    this.onRankingChanged,
    this.onPriceChanged,
    this.onWifiChanged,
    this.onPetFriendlyChanged,
    this.onParkingChanged,
    this.onLocationTap,
    this.onSheetProgressChanged,
    this.onDismissed,
    this.edgeToEdge = false,
    this.isExpanded = false,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
  });

  final AsyncValue<List<Location>> locationsAsync;
  final List<Location> locations;
  final int selectedIndex;
  final bool isExpanded;
  final ExploreFilter filter;
  final ValueChanged<bool> onExpandChanged;
  final ValueChanged<Location> onSelectLocation;
  final ValueChanged<ExploreRanking?>? onRankingChanged;
  final ValueChanged<PriceRange?>? onPriceChanged;
  final ValueChanged<bool>? onWifiChanged;
  final ValueChanged<bool>? onPetFriendlyChanged;
  final ValueChanged<bool>? onParkingChanged;
  final ValueChanged<Location>? onLocationTap;
  final LocationCategory? selectedCategory;
  final ValueChanged<LocationCategory?> onCategoryChanged;
  final ValueChanged<double>? onSheetProgressChanged;
  final VoidCallback? onDismissed;
  final bool edgeToEdge;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

  @override
  ConsumerState<ExploreBottomPanel> createState() => _ExploreBottomPanelState();
}

class _ExploreBottomPanelState extends ConsumerState<ExploreBottomPanel> {
  static const double _minSize = 0.25;
  static const double _midSize = 0.50;
  static const double _maxSize = 0.92;
  static const double _expandThreshold = 0.35;

  late final DraggableScrollableController _sheetController;
  late final ScrollController _listScrollController;

  final _itemKeys = <String, GlobalKey>{};
  int? _lastScrolledIndex;
  bool _scrollScheduled = false;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
    _listScrollController = ScrollController()
      ..addListener(_onListScroll);
    _scheduleScrollSelectedIntoView();
  }

  void _onListScroll() {
    if (!_listScrollController.hasClients) return;
    final pos = _listScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      widget.onLoadMore?.call();
    }
  }

  @override
  void didUpdateWidget(covariant ExploreBottomPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _pruneItemKeys();

    if (oldWidget.isExpanded != widget.isExpanded) {
      _animateTo(widget.isExpanded ? _midSize : _minSize);
    }

    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.locations.length != widget.locations.length) {
      _scheduleScrollSelectedIntoView();
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  void _pruneItemKeys() {
    if (_itemKeys.isEmpty) return;
    final activeIds = widget.locations.map((location) => location.id).toSet();
    _itemKeys.removeWhere((id, _) => !activeIds.contains(id));
  }

  void _scheduleScrollSelectedIntoView() {
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      _scrollSelectedIntoView();
    });
  }

  void _scrollSelectedIntoView() {
    if (!mounted || widget.locations.isEmpty) return;

    final index = widget.selectedIndex.clamp(0, widget.locations.length - 1);
    if (_lastScrolledIndex == index) return;
    _lastScrolledIndex = index;

    final key = _itemKeys[widget.locations[index].id];
    final itemContext = key?.currentContext;
    if (itemContext == null) {
      _scheduleScrollSelectedIntoView();
      return;
    }

    final renderObject = itemContext.findRenderObject();
    if (renderObject == null || !_listScrollController.hasClients) {
      _scheduleScrollSelectedIntoView();
      return;
    }

    _listScrollController.position.ensureVisible(
      renderObject,
      alignment: 0.18,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _animateTo(double target) async {
    if (!_sheetController.isAttached) return;

    try {
      await _sheetController.animateTo(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {}
  }

  void _snapToNearest({double velocity = 0}) {
    if (!_sheetController.isAttached) return;

    final size = _sheetController.size;
    final target = _resolveSnapTarget(size: size, velocity: velocity);

    if (target == _minSize && widget.onDismissed != null) {
      _animateTo(_minSize).then((_) {
        if (mounted) widget.onDismissed!();
      });
      return;
    }

    _animateTo(target);
  }

  double _resolveSnapTarget({required double size, required double velocity}) {
    if (velocity < -600) {
      return size < _midSize ? _midSize : _maxSize;
    }

    if (velocity > 600) {
      return size > _midSize ? _midSize : _minSize;
    }

    final distMin = (size - _minSize).abs();
    final distMid = (size - _midSize).abs();
    final distMax = (size - _maxSize).abs();

    if (distMin <= distMid && distMin <= distMax) {
      return _minSize;
    }
    if (distMid <= distMax) {
      return _midSize;
    }
    return _maxSize;
  }

  void _onSheetNotification(DraggableScrollableNotification notification) {
    final progress = ((notification.extent - _minSize) / (_maxSize - _minSize))
        .clamp(0.0, 1.0);
    widget.onSheetProgressChanged?.call(progress);

    final expandedNow = notification.extent >= _expandThreshold;
    if (expandedNow != widget.isExpanded) {
      widget.onExpandChanged(expandedNow);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final horizontalPadding = widget.edgeToEdge ? 0.0 : 12.0;
    final radius = widget.edgeToEdge
        ? const BorderRadius.vertical(top: Radius.circular(30))
        : BorderRadius.circular(28);
    final amenityFilters =
        widget.isExpanded &&
            widget.onWifiChanged != null &&
            widget.onPetFriendlyChanged != null &&
            widget.onParkingChanged != null
        ? ExploreAmenityFilters(
            hasWifi: widget.filter.hasWifi,
            isPetFriendly: widget.filter.petFriendly,
            hasParking: widget.filter.hasParking,
            onWifiChanged: widget.onWifiChanged!,
            onPetFriendlyChanged: widget.onPetFriendlyChanged!,
            onParkingChanged: widget.onParkingChanged!,
          )
        : null;

    return Positioned.fill(
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: (notification) {
          _onSheetNotification(notification);
          return false;
        },
        child: DraggableScrollableSheet(
          controller: _sheetController,
          minChildSize: _minSize,
          maxChildSize: _maxSize,
          initialChildSize: widget.isExpanded ? _midSize : _minSize,
          snap: true,
          snapSizes: const [_minSize, _midSize, _maxSize],
          snapAnimationDuration: const Duration(milliseconds: 320),
          builder: (context, sheetScrollController) {
            return Stack(
              children: [
                SizedBox.shrink(
                  child: ListView(
                    controller: sheetScrollController,
                    physics: const NeverScrollableScrollPhysics(),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    0,
                  ),
                  child: ExploreBottomPanelFrame(
                    radius: radius,
                    screenHeight: screenHeight,
                    controller: _sheetController,
                    minSize: _minSize,
                    maxSize: _maxSize,
                    countText: '${widget.locations.length} spots found',
                    filter: widget.filter,
                    isExpanded: widget.isExpanded,
                    selectedCategory: widget.selectedCategory,
                    onCategoryChanged: widget.onCategoryChanged,
                    onSnapNearest: _snapToNearest,
                    onRankingChanged: widget.onRankingChanged,
                    onPriceChanged: widget.onPriceChanged,
                    amenityFilters: amenityFilters,
                    child: ExploreBottomPanelList(
                      locationsAsync: widget.locationsAsync,
                      locations: widget.locations,
                      selectedIndex: widget.selectedIndex,
                      listScrollController: _listScrollController,
                      itemKeys: _itemKeys,
                      onSelectLocation: widget.onSelectLocation,
                      onLocationTap: widget.onLocationTap,
                      hasMore: widget.hasMore,
                      isLoadingMore: widget.isLoadingMore,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
