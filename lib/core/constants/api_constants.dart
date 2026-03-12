abstract final class ApiConstants {
  // Tables 
  static const String locationsTable = 'locations';
  static const String categoriesTable = 'categories';
  static const String reviewsTable = 'reviews';
  static const String checkInsTable = 'check_ins';
  static const String favoritesTable = 'favorites';
  static const String profilesTable = 'profiles';
  static const String suggestionsTable = 'suggestions';
  static const String locationPhotosTable = 'location_photos';

  // RPC Functions 
  static const String rpcGetNearbyLocations = 'get_nearby_locations';
  static const String rpcGetTrendingLocations = 'get_trending_locations';
  static const String rpcSearchLocations = 'search_locations';
  static const String rpcGetLocationWithStats = 'get_location_with_stats';

  // Storage buckets
  static const String locationPhotosBucket = 'location-photos';

  // Realtime channels
  static const String channelLocations = 'locations-channel';
}
