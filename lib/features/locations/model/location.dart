import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:sponti/features/locations/model/coordinates.dart';

enum LocationCategory {
  food('Munch', 'ðŸ´', 0xFFE8612C),
  coffee('CafÃ©s', 'â˜•', 0xFF7B4F2E),
  nature('Stroll', 'ðŸŒ¿', 0xFF3A7D44),
  nightlife('Nightlife', 'ðŸŒ™', 0xFF4A3B8C),
  arts('Arts', 'ðŸŽ¨', 0xFFD4458C),
  activities('Fun', 'âš¡', 0xFF2C8C8E);

  const LocationCategory(this.label, this.emoji, this.colorValue);

  final String label;
  final String emoji;
  final int colorValue;

  static LocationCategory fromString(String category) =>
      LocationCategory.values.firstWhere(
        (c) => c.name == category,
        orElse: () => LocationCategory.food,
      );
}

enum PriceRange {
  free(0, 'Free', 'âœ¦'),
  budget(1, 'Budget', 'â‚±'),
  moderate(2, 'Moderate', 'â‚±â‚±'),
  expensive(3, 'Premium', 'â‚±â‚±â‚±');

  const PriceRange(this.level, this.label, this.symbol);

  final int level;
  final String label;
  final String symbol;

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

    final op = _parseTime(openTime);
    final cl = _parseTime(closeTime);
    final cur = TimeOfDay.fromDateTime(now);

    final opMin = op.hour * 60 + op.minute;
    final clMin = cl.hour * 60 + cl.minute;
    final curMin = cur.hour * 60 + cur.minute;

    return clMin < opMin
        ? curMin >= opMin || curMin < clMin
        : curMin >= opMin && curMin <= clMin;
  }

  static TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
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

  bool get isOpenNow => operatingHours?.isOpenNow ?? false;
  String get primaryPhoto => photoUrls.isNotEmpty ? photoUrls.first : '';
  bool get hasPhotos => photoUrls.isNotEmpty;

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
  );

  @override
  List<Object?> get props => [
    id,
    name,
    category,
    coordinates,
    rating,
    distanceKm,
  ];
}
