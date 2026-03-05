import 'package:sponti/features/locations/domain/entities/location.dart';

class LocationModel extends Location {
  const LocationModel({
    required super.id,
    required super.name,
    required super.description,
    required super.category,
    required super.coordinates,
    required super.address,
    required super.priceRange,
    required super.photoUrls,
    required super.createdAt,
    super.landmark,
    super.tags,
    super.rating,
    super.reviewCount,
    super.checkInCount,
    super.isHiddenGem,
    super.isVerified,
    super.hasWifi,
    super.isPetFriendly,
    super.hasParking,
    super.operatingHours,
    super.contactNumber,
    super.websiteUrl,
    super.instagramHandle,
    super.distanceKm,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    // Parse photos which stored as jsonb array of strings in Supabase
    final rawPhotos = json['photos'] as List<dynamic>? ?? [];
    final photos = rawPhotos.map((e) => e.toString()).toList();

    // Parse tags
    final rawTags = json['tags'] as List<dynamic>? ?? [];
    final tags = rawTags.map((e) => e.toString()).toList();

    // Parse operating hours if present
    OperatingHours? hours;
    if (json['open_time'] != null && json['close_time'] != null) {
      final rawDays = json['days_open'] as List<dynamic>? ?? [];
      hours = OperatingHours(
        openTime: json['open_time'] as String,
        closeTime: json['close_time'] as String,
        daysOpen: rawDays.map((e) => e as int).toList(),
        specialNote: json['special_notes'] as String?,
      );
    }

    return LocationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: _parseCategory(json['category'] as String? ?? 'food'),
      coordinates: LocationCoordinates(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      ),
      address: json['address'] as String? ?? '',
      landmark: json['landmark'] as String?,
      priceRange: _parsePriceRange(json['price_range'] as String? ?? 'budget'),
      photoUrls: photos,
      tags: tags,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      checkInCount: json['check_in_count'] as int? ?? 0,
      isHiddenGem: json['is_hidden_gem'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      hasWifi: json['has_wifi'] as bool? ?? false,
      isPetFriendly: json['is_pet_friendly'] as bool? ?? false,
      hasParking: json['has_parking'] as bool? ?? false,
      operatingHours: hours,
      contactNumber: json['contact_number'] as String?,
      websiteUrl: json['website_url'] as String?,
      instagramHandle: json['instagram_handle'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      // From RPC nearby query, may be present
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category.name,
    'latitude': coordinates.latitude,
    'longitude': coordinates.longitude,
    'address': address,
    'landmark': landmark,
    'price_range': priceRange.name,
    'photos': photoUrls,
    'tags': tags,
    'is_hidden_gem': isHiddenGem,
    'has_wifi': hasWifi,
    'is_pet_friendly': isPetFriendly,
    'has_parking': hasParking,
    'contact_number': contactNumber,
    'website_url': websiteUrl,
    'instagram_handle': instagramHandle,
    if (operatingHours != null) ...{
      'open_time': operatingHours!.openTime,
      'close_time': operatingHours!.closeTime,
      'days_open': operatingHours!.daysOpen,
      'special_hours_note': operatingHours!.specialNote,
    },
  };

  static LocationCategory _parseCategory(String raw) {
    return LocationCategory.values.firstWhere(
      (c) => c.name == raw,
      orElse: () => LocationCategory.food,
    );
  }

  static PriceRange _parsePriceRange(String raw) {
    return PriceRange.values.firstWhere(
      (p) => p.name == raw,
      orElse: () => PriceRange.budget,
    );
  }
}
