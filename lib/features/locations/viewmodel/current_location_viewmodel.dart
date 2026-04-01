import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class CurrentLocationState {
  const CurrentLocationState({
    this.latitude,
    this.longitude,
    this.title = 'Where are you now?',
    this.subtitle = 'Tap to center on your live spot.',
    this.isLoading = false,
    this.isPermissionGranted = false,
    this.errorMessage,
  });

  final double? latitude;
  final double? longitude;
  final String title;
  final String subtitle;
  final bool isLoading;
  final bool isPermissionGranted;
  final String? errorMessage;

  bool get hasCoordinates => latitude != null && longitude != null;

  CurrentLocationState copyWith({
    double? latitude,
    double? longitude,
    String? title,
    String? subtitle,
    bool? isLoading,
    bool? isPermissionGranted,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CurrentLocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      isLoading: isLoading ?? this.isLoading,
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CurrentLocationNotifier extends Notifier<CurrentLocationState> {
  @override
  CurrentLocationState build() => const CurrentLocationState();

  Future<void> locate() async {
    if (state.isLoading) return;

    final previous = state;
    state = state.copyWith(
      isLoading: true,
      subtitle: 'Finding your live spot...',
      clearError: true,
    );

    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        state = previous.copyWith(
          isLoading: false,
          isPermissionGranted: false,
          title: 'Location is off',
          subtitle: 'Turn on location services to jump back to your spot.',
          errorMessage: 'Location services are off.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final isGranted =
          permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      if (!isGranted) {
        final isDeniedForever = permission == LocationPermission.deniedForever;
        state = previous.copyWith(
          isLoading: false,
          isPermissionGranted: false,
          title: isDeniedForever ? 'Location locked' : 'Location access needed',
          subtitle: isDeniedForever
              ? 'Enable location access in settings to center the map on you.'
              : 'Allow location access to jump to where you are.',
          errorMessage: isDeniedForever
              ? 'Location permission is permanently denied.'
              : 'Location permission was denied.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      final label = await _resolveLocationLabel(position);
      state = CurrentLocationState(
        latitude: position.latitude,
        longitude: position.longitude,
        title: label,
        subtitle: 'Tap again anytime to recenter on your live spot.',
        isLoading: false,
        isPermissionGranted: true,
      );
    } catch (_) {
      state = previous.copyWith(
        isLoading: false,
        title: previous.hasCoordinates ? previous.title : 'Could not locate you',
        subtitle: 'Try again in a moment.',
        errorMessage: 'We could not fetch your live location right now.',
      );
    }
  }

  Future<String> _resolveLocationLabel(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) {
        return 'Near your current spot';
      }

      final placemark = placemarks.first;
      final primary = [
        placemark.thoroughfare,
        placemark.subLocality,
        placemark.locality,
        placemark.administrativeArea,
      ].where((value) => value != null && value.trim().isNotEmpty).map((value) => value!.trim()).toList(growable: false);

      if (primary.isEmpty) {
        return 'Near your current spot';
      }

      final label = primary.first;
      return label.toLowerCase() == 'unnamed road' ? 'Near your current spot' : 'Near $label';
    } catch (_) {
      return 'Near your current spot';
    }
  }
}

final currentLocationProvider =
    NotifierProvider<CurrentLocationNotifier, CurrentLocationState>(
      CurrentLocationNotifier.new,
    );
