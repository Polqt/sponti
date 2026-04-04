import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/config/shell/shell_provider.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/location_map_floating_controls.dart';
import 'package:sponti/features/locations/viewmodel/current_location_viewmodel.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

class LocationScreenMapControls extends ConsumerWidget {
  const LocationScreenMapControls({
    super.key,
    required this.bottomInset,
    required this.locationsLoading,
    required this.onCategoryChanged,
    required this.onLocateMe,
    required this.onRefresh,
  });

  final double bottomInset;
  final bool locationsLoading;
  final ValueChanged<LocationCategory?> onCategoryChanged;
  final VoidCallback onLocateMe;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(locationFilterProvider);
    final filterNotifier = ref.read(locationFilterProvider.notifier);
    final currentLocation = ref.watch(currentLocationProvider);

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomInset + kShellBottomBarClearance + 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          LocationMapActionButtons(
            isLocating: currentLocation.isLoading,
            isRefreshing: locationsLoading,
            onLocateMe: onLocateMe,
            onRefresh: onRefresh,
          ),
          const SizedBox(height: 10),
          LocationMapFloatingControls(
            selectedCategory: filter.selectedCategory,
            selectedRanking: filter.selectedRanking,
            selectedPrice: filter.selectedPrice,
            hasWifiFilter: filter.hasWifi,
            hasPetFriendlyFilter: filter.isPetFriendly,
            hasParkingFilter: filter.hasParking,
            onCategoryChanged: onCategoryChanged,
            onWifiFilterChanged: filterNotifier.setWifi,
            onPetFriendlyFilterChanged: filterNotifier.setPetFriendly,
            onParkingFilterChanged: filterNotifier.setParking,
            onClearRanking: () => filterNotifier.setRanking(null),
            onClearPrice: () => filterNotifier.setPrice(null),
          ),
        ],
      ),
    );
  }
}
