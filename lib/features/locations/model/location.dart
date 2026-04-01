import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:sponti/features/locations/model/coordinates.dart';

enum LocationCategory {
  food('Munch', '🍴', 0xFFE8612C, Icons.restaurant_rounded),
  coffee('Cafés', '☕', 0xFF7B4F2E, Icons.local_cafe_rounded),
  nature('Stroll', '🌿', 0xFF3A7D44, Icons.park_rounded),
  nightlife('Nightlife', '🌙', 0xFF4A3B8C, Icons.nightlife_rounded),
  arts('Arts', '🎨', 0xFFD4458C, Icons.palette_rounded),
  activities('Fun', '⚡', 0xFF2C8C8E, Icons.sports_esports_rounded);

  const LocationCategory(this.label, this.emoji, this.colorValue, this.icon);

  final String label;
  final String emoji;
  final int colorValue;
  final IconData icon;

  static LocationCategory fromString(String category) =>
      LocationCategory.values.firstWhere(
        (c) => c.name == category,
        orElse: () => LocationCategory.food,
      );
}

enum PriceRange {
  free(0, 'Free', '✦', 0xFF2C8C8E),
  budget(1, 'Budget', '₱', 0xFFE8612C),
  moderate(2, 'Moderate', '₱₱', 0xFFFFB830),
  expensive(3, 'Premium', '₱₱₱', 0xFF7B4F2E);

  const PriceRange(this.level, this.label, this.symbol, this.accentColorValue);

  final int level;
  final String label;
  final String symbol;
  final int accentColorValue;

  Color get accentColor => Color(accentColorValue);

  static PriceRange fromString(String price) => PriceRange.values.firstWhere(
    (p) => p.name == price,
    orElse: () => PriceRange.budget,
  );
}

class OperatingHours extends Equatable {
  const OperatingHours({
    required this.openTime,
    required this.closeTime,
    required this.daysOpen,
    this.specialNote,
  });

  final String openTime;
  final String closeTime;
  final List<int> daysOpen;
  final String? specialNote;

  bool get isOpenNow {
    final now = DateTime.now();
    if (!daysOpen.contains(now.weekday)) return false;

    final opMin = _toMinutes(openTime);
    final clMin = _toMinutes(closeTime);
    final curMin = now.hour * 60 + now.minute;

    return clMin < opMin
        ? curMin >= opMin || curMin < clMin
        : curMin >= opMin && curMin <= clMin;
  }

  static int _toMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  @override
  List<Object?> get props => [openTime, closeTime, daysOpen, specialNote];
}

class Location extends Equatable {
  const Location({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.coordinates,
    required this.address,
    required this.priceRange,
    required this.photoUrls,
    required this.createdAt,
    this.landmark,
    this.tags = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.checkInCount = 0,
    this.isHiddenGem = false,
    this.isVerified = false,
    this.hasWifi = false,
    this.isPetFriendly = false,
    this.hasParking = false,
    this.operatingHours,
    this.contactNumber,
    this.websiteUrl,
    this.instagramHandle,
    this.submittedBy,
    this.updatedAt,
    this.distanceKm,
    this.isSeeded = false,
    this.seededAt,
  });

  final String id;
  final String name;
  final String description;
  final LocationCategory category;
  final Coordinates coordinates;
  final String address;
  final PriceRange priceRange;
  final List<String> photoUrls;
  final String? landmark;
  final List<String> tags;
  final double rating;
  final int reviewCount;
  final int checkInCount;
  final bool isHiddenGem;
  final bool isVerified;
  final bool hasWifi;
  final bool isPetFriendly;
  final bool hasParking;
  final OperatingHours? operatingHours;
  final String? contactNumber;
  final String? websiteUrl;
  final String? instagramHandle;
  final String? submittedBy;
  final double? distanceKm;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSeeded;
  final DateTime? seededAt;

  bool get isOpenNow => operatingHours?.isOpenNow ?? false;
  String get primaryPhoto => photoUrls.isNotEmpty ? photoUrls.first : '';
  bool get hasPhotos => photoUrls.isNotEmpty;
  bool get hasContact =>
      contactNumber != null || websiteUrl != null || instagramHandle != null;

  Location copyWith({
    String? name,
    String? description,
    LocationCategory? category,
    Coordinates? coordinates,
    String? address,
    PriceRange? priceRange,
    List<String>? photoUrls,
    String? landmark,
    List<String>? tags,
    double? rating,
    int? reviewCount,
    int? checkInCount,
    bool? isHiddenGem,
    bool? isVerified,
    bool? hasWifi,
    bool? isPetFriendly,
    bool? hasParking,
    OperatingHours? operatingHours,
    String? contactNumber,
    String? websiteUrl,
    String? instagramHandle,
    String? submittedBy,
    double? distanceKm,
    bool? isSeeded,
    DateTime? seededAt,
  }) => Location(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    category: category ?? this.category,
    coordinates: coordinates ?? this.coordinates,
    address: address ?? this.address,
    priceRange: priceRange ?? this.priceRange,
    photoUrls: photoUrls ?? this.photoUrls,
    landmark: landmark ?? this.landmark,
    tags: tags ?? this.tags,
    rating: rating ?? this.rating,
    reviewCount: reviewCount ?? this.reviewCount,
    checkInCount: checkInCount ?? this.checkInCount,
    isHiddenGem: isHiddenGem ?? this.isHiddenGem,
    isVerified: isVerified ?? this.isVerified,
    hasWifi: hasWifi ?? this.hasWifi,
    isPetFriendly: isPetFriendly ?? this.isPetFriendly,
    hasParking: hasParking ?? this.hasParking,
    operatingHours: operatingHours ?? this.operatingHours,
    contactNumber: contactNumber ?? this.contactNumber,
    websiteUrl: websiteUrl ?? this.websiteUrl,
    instagramHandle: instagramHandle ?? this.instagramHandle,
    submittedBy: submittedBy ?? this.submittedBy,
    distanceKm: distanceKm ?? this.distanceKm,
    createdAt: createdAt,
    isSeeded: isSeeded ?? this.isSeeded,
    seededAt: seededAt ?? this.seededAt,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    category,
    coordinates,
    priceRange,
    photoUrls,
    landmark,
    tags,
    rating,
    reviewCount,
    checkInCount,
    isHiddenGem,
    isVerified,
    hasWifi,
    isPetFriendly,
    hasParking,
    operatingHours,
    contactNumber,
    websiteUrl,
    instagramHandle,
    submittedBy,
    distanceKm,
    createdAt,
    updatedAt,
    isSeeded,
    seededAt,
  ];
}
