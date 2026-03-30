class SuggestionModel {
  const SuggestionModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.address,
    required this.createdAt,
    this.description,
    this.latitude,
    this.longitude,
    this.reason,
    this.status = 'pending',
  });

  final String id;
  final String userId;
  final String name;
  final String? description;
  final String category;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? reason;
  final String status;
  final DateTime createdAt;

  factory SuggestionModel.fromJson(Map<String, dynamic> json) {
    return SuggestionModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      category: json['category'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'category': category,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'reason': reason,
      'status': status,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  SuggestionModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? category,
    String? address,
    double? latitude,
    double? longitude,
    String? reason,
    String? status,
    DateTime? createdAt,
    bool clearDescription = false,
    bool clearLatitude = false,
    bool clearLongitude = false,
    bool clearReason = false,
  }) {
    return SuggestionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      category: category ?? this.category,
      address: address ?? this.address,
      latitude: clearLatitude ? null : (latitude ?? this.latitude),
      longitude: clearLongitude ? null : (longitude ?? this.longitude),
      reason: clearReason ? null : (reason ?? this.reason),
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
