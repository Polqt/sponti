import 'package:flutter/material.dart';
import 'package:sponti/features/locations/utils/map_label_layout.dart';
import 'package:sponti/features/locations/utils/map_pin_label_text.dart';

class LocationMapLabelChip extends StatelessWidget {
  const LocationMapLabelChip({
    super.key,
    required this.labelText,
    required this.placement,
    required this.opacity,
    required this.scale,
  });

  final MapPinLabelText labelText;
  final MapPinLabelPlacement placement;
  final double opacity;
  final double scale;

  static const TextStyle _textStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Color(0xFF171717),
    height: 1.14,
  );

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          alignment: _alignmentForPlacement(placement),
          child: Align(
            alignment: _alignmentForPlacement(placement),
            child: Text(
              labelText.displayText,
              style: _textStyle,
              textAlign: _textAlignForPlacement(placement),
              maxLines: labelText.lineCount,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ),
    );
  }

  Alignment _alignmentForPlacement(MapPinLabelPlacement placement) =>
      switch (placement) {
        MapPinLabelPlacement.right => Alignment.centerLeft,
        MapPinLabelPlacement.left => Alignment.centerRight,
        MapPinLabelPlacement.top => Alignment.bottomCenter,
        MapPinLabelPlacement.bottom => Alignment.topCenter,
      };

  TextAlign _textAlignForPlacement(MapPinLabelPlacement placement) =>
      switch (placement) {
        MapPinLabelPlacement.right => TextAlign.left,
        MapPinLabelPlacement.left => TextAlign.right,
        MapPinLabelPlacement.top => TextAlign.center,
        MapPinLabelPlacement.bottom => TextAlign.center,
      };
}
