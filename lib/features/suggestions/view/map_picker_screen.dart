import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapPickerResult {
  const MapPickerResult({
    required this.coordinates,
  });

  final LatLng coordinates;
}

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const LatLng _bacolodCenter = LatLng(10.6713, 122.9511);
  static const double _defaultZoom = 14.0;

  final MapController _mapController = MapController();

  LatLng? _pinned;
  String? _locationLabel;
  bool _isLocatingUser = false;

  Future<void> _onTap(TapPosition tapPosition, LatLng point) async {
    await _pin(point);
  }

  Future<void> _pin(LatLng point) async {
    setState(() => _pinned = point);
    final label = await _resolveLabel(point);
    if (!mounted) return;
    setState(() => _locationLabel = label);
  }

  Future<void> _useCurrentLocation() async {
    if (_isLocatingUser) return;

    setState(() => _isLocatingUser = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _showMessage('Turn on location services to use your current location.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final granted =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (!granted) {
        _showMessage(
          permission == LocationPermission.deniedForever
              ? 'Location permission is permanently denied.'
              : 'Location permission is required to use your current location.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      if (!mounted) return;

      final point = LatLng(position.latitude, position.longitude);
      _mapController.move(point, 16);
      await _pin(point);
    } catch (_) {
      _showMessage('Unable to fetch your current location right now.');
    } finally {
      if (mounted) {
        setState(() => _isLocatingUser = false);
      }
    }
  }

  Future<String?> _resolveLabel(LatLng point) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (placemarks.isEmpty) return null;

      final placemark = placemarks.first;
      final parts = <String?>[
        placemark.street,
        placemark.subLocality,
        placemark.locality,
      ]
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty && value.toLowerCase() != 'unnamed road')
          .toList(growable: false);

      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _bacolodCenter,
                      initialZoom: _defaultZoom,
                      onTap: _onTap,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.sponti.app',
                      ),
                      MarkerLayer(
                        markers: [
                          if (_pinned != null)
                            Marker(
                              point: _pinned!,
                              width: 40,
                              height: 50,
                              child: Column(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF111111),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  Container(
                                    width: 2,
                                    height: 10,
                                    color: const Color(0xFF111111),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_left_rounded,
                              size: 18,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'tap the map or use your current location',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFAAAAAA),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 212,
                    child: FloatingActionButton.small(
                      heroTag: 'suggest_spot_locate_me',
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF111111),
                      onPressed: _isLocatingUser ? null : _useCurrentLocation,
                      child: _isLocatingUser
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF111111),
                              ),
                            )
                          : const Icon(Icons.my_location_rounded, size: 18),
                    ),
                  ),
                  if (_pinned != null)
                    Positioned(
                      bottom: 140,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFDDDDDD),
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'pinned location',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFAAAAAA),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_pinned!.latitude.toStringAsFixed(5)}, ${_pinned!.longitude.toStringAsFixed(5)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF111111),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if ((_locationLabel ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _locationLabel!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pinned == null
                        ? null
                        : () => Navigator.pop(
                            context,
                            MapPickerResult(coordinates: _pinned!),
                          ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 52,
                      decoration: BoxDecoration(
                        color: _pinned == null
                            ? const Color(0xFFCCCCCC)
                            : const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Center(
                        child: Text(
                          'confirm pin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => Navigator.pop(context, null),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: const Color(0xFFDDDDDD),
                          width: 0.5,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'cancel',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
