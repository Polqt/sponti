import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sponti/features/locations/view/widgets/location_map_search_bar.dart';

class LocationMapHeader extends StatelessWidget {
  const LocationMapHeader({
    super.key,
    required this.sheetProgress,
  });

  final ValueListenable<double> sheetProgress;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ValueListenableBuilder<double>(
        valueListenable: sheetProgress,
        builder: (context, progress, _) {
          final clamped = progress.clamp(0.0, 1.0);
          return IgnorePointer(
            ignoring: clamped > 0.92,
            child: Opacity(
              opacity: 1.0 - clamped,
              child: Transform.translate(
                offset: Offset(-18 * clamped, 0),
                child: Transform.scale(
                  scale: 1.0 - (clamped * 0.04),
                  alignment: Alignment.topCenter,
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LocationMapSearchBar(),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
