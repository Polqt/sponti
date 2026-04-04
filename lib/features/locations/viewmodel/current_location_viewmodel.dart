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
      await _ensureLocationServiceEnabled();
      await _ensureLocationPermission();
      final position = await _fetchCurrentPosition();
      final label = await _resolveLocationLabel(position);

      state = CurrentLocationState(
        latitude: position.latitude,
        longitude: position.longitude,
        title: label,
        subtitle: 'Tap again anytime to recenter on your live spot.',
        isPermissionGranted: true,
      );
    } on _LocationServiceDisabledException {
      state = previous.copyWith(
        isLoading: false,
        isPermissionGranted: false,
        title: 'Location is off',
        subtitle: 'Turn on location services to jump back to your spot.',
        errorMessage: 'Location services are off.',
      );
    } on _LocationPermissionDeniedException catch (e) {
      state = previous.copyWith(
        isLoading: false,
        isPermissionGranted: false,
        title: e.isPermanent ? 'Location locked' : 'Location access needed',
        subtitle: e.isPermanent
            ? 'Enable location access in settings to center the map on you.'
            : 'Allow location access to jump to where you are.',
        errorMessage: e.isPermanent
            ? 'Location permission is permanently denied.'
            : 'Location permission was denied.',
      );
    } catch (_) {
      state = previous.copyWith(
        isLoading: false,
        title: previous.hasCoordinates
            ? previous.title
            : 'Could not locate you',
        subtitle: 'Try again in a moment.',
        errorMessage: 'We could not fetch your live location right now.',
      );
    }
  }

  Future<void> _ensureLocationServiceEnabled() async {
    final isEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isEnabled) throw _LocationServiceDisabledException();
  }

  Future<void> _ensureLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    final isGranted =
        permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;

    if (!isGranted) {
      throw _LocationPermissionDeniedException(
        isPermanent: permission == LocationPermission.deniedForever,
      );
    }
  }

  Future<Position> _fetchCurrentPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Location request timed out'),
    );
  }

  Future<String> _resolveLocationLabel(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) return 'Near your current spot';

      final placemark = placemarks.first;
      final candidates = [
        placemark.thoroughfare,
        placemark.subLocality,
        placemark.locality,
        placemark.administrativeArea,
      ];

      final label = candidates
          .where((v) => v != null && v.trim().isNotEmpty)
          .map((v) => v!.trim())
          .firstOrNull;

      if (label == null || label.toLowerCase() == 'unnamed road') {
        return 'Near your current spot';
      }
      return 'Near $label';
    } catch (_) {
      return 'Near your current spot';
    }
  }
}

/// Internal exception for location service disabled
class _LocationServiceDisabledException implements Exception {}

/// Internal exception for permission denied
class _LocationPermissionDeniedException implements Exception {
  const _LocationPermissionDeniedException({required this.isPermanent});
  final bool isPermanent;
}

final currentLocationProvider =
    NotifierProvider<CurrentLocationNotifier, CurrentLocationState>(
      CurrentLocationNotifier.new,
    );
