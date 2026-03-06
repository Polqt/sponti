import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseOptions {
  SupabaseOptions._();

  static String get supabaseUrl => dotenv.env['PUBLIC_SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['PUBLIC_SUPABASE_KEY'] ?? '';
}

abstract final class SupabaseTables {
  static const String locations = 'locations';
  static const String reviews = 'reviews';
  static const String checkIns = 'check_ins';
  static const String favorites = 'favorites';
  static const String categories = 'categories';
  static const String locationPhotos = 'location_photos';
  static const String profiles = 'profiles';
  static const String suggestions = 'suggestions';
}

abstract final class SupabaseBuckets {
  static const String locationPhotos = 'location-photos';
  static const String avatars = 'avatars';
}

abstract final class SupabaseRPC {
  static const String getNearbyLocations = 'get_nearby_locations';
  static const String getLocationWithStats = 'get_location_with_stats';
  static const String searchLocations = 'search_locations';
}
