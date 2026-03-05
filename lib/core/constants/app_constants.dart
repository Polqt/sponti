abstract final class AppConstants {
  // App info
  static const String appName = 'Sponti';
  static const String appDescription =
      'Discover and share spontaneous places around you!';
  static const String appVersion = '1.0.0';

  // Bacolod City Default Center
  // May change the lat and lon if it's not accurate
  static const double defaultLatitude = 10.6762;
  static const double defaultLongitude = 122.9548;

  // Map
  static const double defaultZoom = 13.0;
  static const double detailMapZoom = 16.0;
  static const double nearbyRadiusKm = 2.0;
  static const double defaultSearchRadiusKm = 5.0;
  static const double maxSearchRadiusKm = 50.0;

  // Pagination
  static const int itemsPerPage = 20;
  static const int maxItemsPerPage = 100;

  // Network
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  static const Duration cacheExpiry = Duration(hours: 2);

  // Animation
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 400);
  static const Duration animSlow = Duration(milliseconds: 600);

  // Local Storage
  static const String hiveBoxLocations = 'locations_cache';
  static const String hiveBoxUserPrefs = 'user_preferences';
  static const String hiveBoxFavorites = 'favorites_cache';
  static const String hiveKeyFavoriteIds = 'favorite_ids';
  static const String hiveKeyOnboardingDone = 'onboarding_done';
}
