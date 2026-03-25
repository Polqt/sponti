import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/screens/location_detail.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

Future<void> showLocationDetailSheet(
  BuildContext context, {
  required Location location,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _LocationDetailSheet(location: location),
  );
}

class _LocationDetailSheet extends StatefulWidget {
  const _LocationDetailSheet({required this.location});

  final Location location;

  @override
  State<_LocationDetailSheet> createState() => _LocationDetailSheetState();
}

class _LocationDetailSheetState extends State<_LocationDetailSheet> {
  static const double _midSize = 0.76;
  static const double _maxSize = 0.96;

  late final DraggableScrollableController _controller;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = DraggableScrollableController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _snapToNearest({double velocity = 0}) {
    if (!_controller.isAttached) return;
    final size = _controller.size;
    final shouldDismiss = velocity > 500 || size < _midSize * 0.65;

    if (shouldDismiss) {
      _controller.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInCubic,
      );
      return;
    }

    if (velocity < -500) {
      _controller.animateTo(
        _maxSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    final target = (size - _midSize).abs() <= (size - _maxSize).abs()
        ? _midSize
        : _maxSize;
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topPadding = MediaQuery.viewPaddingOf(context).top;
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(top: topPadding + 12),
      child: DraggableScrollableSheet(
        controller: _controller,
        expand: false,
        initialChildSize: _midSize,
        minChildSize: 0.0,
        maxChildSize: _maxSize,
        snap: true,
        snapSizes: const [_midSize, _maxSize],
        snapAnimationDuration: const Duration(milliseconds: 300),
        builder: (context, sheetScrollController) {
          return DecoratedBox(
            decoration: const BoxDecoration(
              color: SpontiColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (details) {
                    if (!_controller.isAttached) return;
                    final delta = -details.delta.dy / screenHeight;
                    _controller.jumpTo(
                      (_controller.size + delta).clamp(0.0, _maxSize),
                    );
                  },
                  onVerticalDragEnd: (details) =>
                      _snapToNearest(velocity: details.primaryVelocity ?? 0),
                  child: const _SheetHandle(),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      SizedBox.shrink(
                        child: ListView(
                          controller: sheetScrollController,
                          physics: const NeverScrollableScrollPhysics(),
                        ),
                      ),
                      Consumer(
                        builder: (context, ref, _) {
                          final liveLocation =
                              ref.watch(locationDetailProvider(widget.location.id)).valueOrNull ??
                              widget.location;

                          return LocationDetail(
                            location: liveLocation,
                            scrollController: _scrollController,
                            bottomPadding: bottomPadding + 28,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      child: Center(
        child: Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: SpontiColors.textMuted.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
