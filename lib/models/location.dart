class SavedLocation {
  final String id;
  final String userId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String type;
  final DateTime createdAt;

  SavedLocation({
    required this.id,
    required this.userId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.createdAt,
  });

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    return SavedLocation(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      name: json['name'],
      address: json['address'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      type: json['type'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
    };
  }
}

class RecentLocation {
  final String id;
  final String address;
  final String? placeName;
  final double latitude;
  final double longitude;
  final DateTime lastUsed;

  RecentLocation({
    required this.id,
    required this.address,
    this.placeName,
    required this.latitude,
    required this.longitude,
    required this.lastUsed,
  });

  factory RecentLocation.fromJson(Map<String, dynamic> json) {
    return RecentLocation(
      id: json['id']?.toString() ?? '',
      address: json['address'] ?? '',
      placeName: json['place_name'] ?? json['placeName'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      lastUsed: DateTime.parse(json['last_used'] ?? json['lastUsed'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'place_name': placeName,
      'latitude': latitude,
      'longitude': longitude,
      'last_used': lastUsed.toIso8601String(),
    };
  }
}