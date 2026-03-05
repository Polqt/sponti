import '../../domain/entities/location.dart';
import 'coordinates_model.dart';

// Data model responsible for JSON serialization only.
/// Business logic stays in the domain [Location] entity.
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
    super.submittedBy,
    super.updatedAt,
    super.distanceKm,
  });

  // ── fromJson ──────────────────────────────────────────────────────────────

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    final rawPhotos = json['photos'] as List<dynamic>? ?? [];
    final rawTags = json['tags'] as List<dynamic>? ?? [];

    OperatingHours? hours;
    if (json['open_time'] != null && json['close_time'] != null) {
      final rawDays = json['days_open'] as List<dynamic>? ?? [];
      hours = OperatingHours(
        openTime: json['open_time'] as String,
        closeTime: json['close_time'] as String,
        daysOpen: rawDays.map((d) => (d as num).toInt()).toList(),
        specialNote: json['special_hours_note'] as String?,
      );
    }

    return LocationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      category: LocationCategory.fromString(
        json['category'] as String? ?? 'food',
      ),
      coordinates: CoordinatesModel(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      ),
      address: json['address'] as String? ?? '',
      landmark: json['landmark'] as String?,
      priceRange: PriceRange.fromString(
        json['price_range'] as String? ?? 'budget',
      ),
      photoUrls: rawPhotos.map((e) => e.toString()).toList(),
      tags: rawTags.map((e) => e.toString()).toList(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      checkInCount: (json['check_in_count'] as num?)?.toInt() ?? 0,
      isHiddenGem: json['is_hidden_gem'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      hasWifi: json['has_wifi'] as bool? ?? false,
      isPetFriendly: json['is_pet_friendly'] as bool? ?? false,
      hasParking: json['has_parking'] as bool? ?? false,
      operatingHours: hours,
      contactNumber: json['contact_number'] as String?,
      websiteUrl: json['website_url'] as String?,
      instagramHandle: json['instagram_handle'] as String?,
      submittedBy: json['submitted_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      // Injected from PostGIS RPC — not in the base table
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }

  // toJson (for INSERT / UPDATE)

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'description': description,
      'category': category.name,
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
      'address': address,
      'price_range': priceRange.name,
      'photos': photoUrls,
      'tags': tags,
      'is_hidden_gem': isHiddenGem,
      'has_wifi': hasWifi,
      'is_pet_friendly': isPetFriendly,
      'has_parking': hasParking,
    };

    if (landmark != null) map['landmark'] = landmark;
    if (contactNumber != null) map['contact_number'] = contactNumber;
    if (websiteUrl != null) map['website_url'] = websiteUrl;
    if (instagramHandle != null) map['instagram_handle'] = instagramHandle;
    if (submittedBy != null) map['submitted_by'] = submittedBy;

    if (operatingHours != null) {
      map['open_time'] = operatingHours!.openTime;
      map['close_time'] = operatingHours!.closeTime;
      map['days_open'] = operatingHours!.daysOpen;
      if (operatingHours!.specialNote != null) {
        map['special_hours_note'] = operatingHours!.specialNote;
      }
    }

    return map;
  }

  // fromEntity (for mutations)
  factory LocationModel.fromEntity(Location entity) => LocationModel(
    id: entity.id,
    name: entity.name,
    description: entity.description,
    category: entity.category,
    coordinates: entity.coordinates,
    address: entity.address,
    landmark: entity.landmark,
    priceRange: entity.priceRange,
    photoUrls: entity.photoUrls,
    tags: entity.tags,
    rating: entity.rating,
    reviewCount: entity.reviewCount,
    checkInCount: entity.checkInCount,
    isHiddenGem: entity.isHiddenGem,
    isVerified: entity.isVerified,
    hasWifi: entity.hasWifi,
    isPetFriendly: entity.isPetFriendly,
    hasParking: entity.hasParking,
    operatingHours: entity.operatingHours,
    contactNumber: entity.contactNumber,
    websiteUrl: entity.websiteUrl,
    instagramHandle: entity.instagramHandle,
    submittedBy: entity.submittedBy,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
    distanceKm: entity.distanceKm,
  );
}
