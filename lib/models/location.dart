import 'package:flutter/material.dart';

class SavedLocation {
  final String id;
  final String? userPhone;
  final String? label; // Custom label (e.g., 'Gym', 'Mom's House')
  final String locationType; // 'home', 'work', 'other'
  final String locationTypeDisplay; // 'Home', 'Work', 'Other'
  final String address;
  final double latitude;
  final double longitude;
  final String? landmark;
  final String? instructions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavedLocation({
    required this.id,
    this.userPhone,
    this.label,
    required this.locationType,
    required this.locationTypeDisplay,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.landmark,
    this.instructions,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    return SavedLocation(
      id: json['id'].toString(),
      userPhone: json['user_phone'],
      label: json['label'],
      locationType: json['location_type'] ?? 'other',
      locationTypeDisplay: json['location_type_display'] ?? 'Other',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      landmark: json['landmark'],
      instructions: json['instructions'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'location_type': locationType,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      if (landmark != null) 'landmark': landmark,
      if (instructions != null) 'instructions': instructions,
    };
  }

  // Helper getters for UI
  String get displayName {
    if (label != null && label!.isNotEmpty) return label!;
    return locationTypeDisplay;
  }

  IconData get icon {
    switch (locationType) {
      case 'home':
        return Icons.home_outlined;
      case 'work':
        return Icons.work_outline;
      default:
        return Icons.location_on;
    }
  }
}

class RecentLocation {
  final String id;
  final String? userPhone;
  final String address;
  final double latitude;
  final double longitude;
  final int searchCount;
  final DateTime lastUsed;
  final DateTime createdAt;

  RecentLocation({
    required this.id,
    this.userPhone,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.searchCount = 1,
    required this.lastUsed,
    required this.createdAt,
  });

  factory RecentLocation.fromJson(Map<String, dynamic> json) {
  return RecentLocation(
    id: json['id']?.toString() ?? '',
    userPhone: json['user_phone'],
    address: json['address'] ?? '',
    latitude: json['latitude'] != null 
        ? (json['latitude'] as num).toDouble() 
        : 0.0, // ✅ Handle null
    longitude: json['longitude'] != null 
        ? (json['longitude'] as num).toDouble() 
        : 0.0, // ✅ Handle null
    searchCount: json['search_count'] ?? 1,
    lastUsed: json['last_used'] != null
        ? DateTime.parse(json['last_used'])
        : DateTime.now(), // ✅ Simplified
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'])
        : DateTime.now(), // ✅ Simplified
  );
}

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Helper to extract place name from address (first part before comma)
  String get placeName {
    if (address.contains(',')) {
      return address.split(',').first.trim();
    }
    return address;
  }

  // Helper to get subtitle (rest of address)
  String get subtitle {
    if (address.contains(',')) {
      return address.split(',').skip(1).join(',').trim();
    }
    return '';
  }
}
