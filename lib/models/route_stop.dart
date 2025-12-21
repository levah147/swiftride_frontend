// ==================== models/route_stop.dart ====================
// Route Stop Model - For multi-stop route planning

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Represents a single stop in a multi-stop route
class RouteStop {
  final String id;
  final int order; // 0 = pickup, 1+ = waypoints/destination
  final StopType type;
  final String address;
  final double latitude;
  final double longitude;
  final String? placeId;
  final String? placeName; // Short name for display

  RouteStop({
    required this.id,
    required this.order,
    required this.type,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.placeName,
  });

  /// Create pickup stop
  factory RouteStop.pickup({
    required String address,
    required double latitude,
    required double longitude,
    String? placeId,
    String? placeName,
  }) {
    return RouteStop(
      id: 'pickup',
      order: 0,
      type: StopType.pickup,
      address: address,
      latitude: latitude,
      longitude: longitude,
      placeId: placeId,
      placeName: placeName,
    );
  }

  /// Create waypoint stop
  factory RouteStop.waypoint({
    required int order,
    required String address,
    required double latitude,
    required double longitude,
    String? placeId,
    String? placeName,
  }) {
    return RouteStop(
      id: 'waypoint_$order',
      order: order,
      type: StopType.waypoint,
      address: address,
      latitude: latitude,
      longitude: longitude,
      placeId: placeId,
      placeName: placeName,
    );
  }

  /// Create destination stop
  factory RouteStop.destination({
    required int order,
    required String address,
    required double latitude,
    required double longitude,
    String? placeId,
    String? placeName,
  }) {
    return RouteStop(
      id: 'destination',
      order: order,
      type: StopType.destination,
      address: address,
      latitude: latitude,
      longitude: longitude,
      placeId: placeId,
      placeName: placeName,
    );
  }

  /// Copy with updated fields
  RouteStop copyWith({
    String? id,
    int? order,
    StopType? type,
    String? address,
    double? latitude,
    double? longitude,
    String? placeId,
    String? placeName,
  }) {
    return RouteStop(
      id: id ?? this.id,
      order: order ?? this.order,
      type: type ?? this.type,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeId: placeId ?? this.placeId,
      placeName: placeName ?? this.placeName,
    );
  }

  /// Check if location is valid
  bool get hasValidLocation => latitude != 0 && longitude != 0;

  /// Get display name (short name or address)
  String get displayName => placeName ?? address;

  /// Get LatLng
  LatLng get latLng => LatLng(latitude, longitude);

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'type': type.name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      if (placeId != null) 'place_id': placeId,
      if (placeName != null) 'place_name': placeName,
    };
  }

  /// Create from JSON
  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      id: json['id'] ?? '',
      order: json['order'] ?? 0,
      type: StopType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => StopType.waypoint,
      ),
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      placeId: json['place_id'],
      placeName: json['place_name'],
    );
  }

  @override
  String toString() =>
      'RouteStop(order: $order, type: $type, address: $address)';
}

/// Type of stop in the route
enum StopType {
  pickup,
  waypoint,
  destination,
}
