// ==================== models/ride_request.dart ====================
// RIDE REQUEST MODEL - Complete ride booking request
// Used when creating a new ride booking

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'vehicle_type.dart';

/// Represents a ride booking request
/// This is the data structure sent to backend when booking a ride
class RideRequest {
  // User & vehicle info
  final String userId;
  final String vehicleTypeId;
  final VehicleType? vehicleType; // Optional for display purposes
  
  // Pickup location
  final LatLng pickupCoordinates;
  final String pickupAddress;
  final String? pickupPlaceName; // e.g., "Keton Apartments"
  
  // Destination location
  final LatLng destinationCoordinates;
  final String destinationAddress;
  final String? destinationPlaceName; // e.g., "Modern Market"
  
  // Optional stops
  final List<RideStop>? stops;
  
  // Fare & pricing
  final double estimatedFare;
  final String fareHash; // From backend fare calculation
  final double? distance; // in km
  final int? estimatedDuration; // in minutes
  
  // Scheduling
  final bool isScheduled;
  final DateTime? scheduledTime;
  
  // Payment
  final String paymentMethod; // 'cash', 'wallet', 'card'
  final String? promoCode;
  
  // Additional info
  final String? specialRequests; // e.g., "Please call on arrival"
  final int? passengerCount;
  final String? cityName;

  RideRequest({
    required this.userId,
    required this.vehicleTypeId,
    this.vehicleType,
    required this.pickupCoordinates,
    required this.pickupAddress,
    this.pickupPlaceName,
    required this.destinationCoordinates,
    required this.destinationAddress,
    this.destinationPlaceName,
    this.stops,
    required this.estimatedFare,
    required this.fareHash,
    this.distance,
    this.estimatedDuration,
    this.isScheduled = false,
    this.scheduledTime,
    this.paymentMethod = 'cash',
    this.promoCode,
    this.specialRequests,
    this.passengerCount = 1,
    this.cityName,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'vehicle_type': vehicleTypeId,
      
      // Pickup
      'pickup_location': pickupAddress,
      'pickup_latitude': pickupCoordinates.latitude,
      'pickup_longitude': pickupCoordinates.longitude,
      if (pickupPlaceName != null) 'pickup_place_name': pickupPlaceName,
      
      // Destination
      'destination_location': destinationAddress,
      'destination_latitude': destinationCoordinates.latitude,
      'destination_longitude': destinationCoordinates.longitude,
      if (destinationPlaceName != null) 'destination_place_name': destinationPlaceName,
      
      // Stops
      if (stops != null && stops!.isNotEmpty)
        'stops': stops!.map((s) => s.toJson()).toList(),
      
      // Pricing
      'fare_hash': fareHash,
      'estimated_fare': estimatedFare,
      if (distance != null) 'distance': distance,
      if (estimatedDuration != null) 'estimated_duration': estimatedDuration,
      
      // Scheduling
      'ride_type': isScheduled ? 'scheduled' : 'immediate',
      if (scheduledTime != null) 'scheduled_time': scheduledTime!.toIso8601String(),
      
      // Payment
      'payment_method': paymentMethod,
      if (promoCode != null) 'promo_code': promoCode,
      
      // Additional
      if (specialRequests != null) 'special_requests': specialRequests,
      if (passengerCount != null) 'passenger_count': passengerCount,
      if (cityName != null) 'city_name': cityName,
    };
  }

  /// Create from JSON
  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      userId: json['user_id'] ?? '',
      vehicleTypeId: json['vehicle_type'] ?? '',
      pickupCoordinates: LatLng(
        json['pickup_latitude'] ?? 0.0,
        json['pickup_longitude'] ?? 0.0,
      ),
      pickupAddress: json['pickup_location'] ?? '',
      pickupPlaceName: json['pickup_place_name'],
      destinationCoordinates: LatLng(
        json['destination_latitude'] ?? 0.0,
        json['destination_longitude'] ?? 0.0,
      ),
      destinationAddress: json['destination_location'] ?? '',
      destinationPlaceName: json['destination_place_name'],
      stops: json['stops'] != null
          ? (json['stops'] as List).map((s) => RideStop.fromJson(s)).toList()
          : null,
      estimatedFare: _parseDouble(json['estimated_fare']) ?? 0.0,
      fareHash: json['fare_hash'] ?? '',
      distance: _parseDouble(json['distance']),
      estimatedDuration: json['estimated_duration'],
      isScheduled: json['ride_type'] == 'scheduled',
      scheduledTime: json['scheduled_time'] != null
          ? DateTime.parse(json['scheduled_time'])
          : null,
      paymentMethod: json['payment_method'] ?? 'cash',
      promoCode: json['promo_code'],
      specialRequests: json['special_requests'],
      passengerCount: json['passenger_count'] ?? 1,
      cityName: json['city_name'],
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Create a copy with modified fields
  RideRequest copyWith({
    String? userId,
    String? vehicleTypeId,
    VehicleType? vehicleType,
    LatLng? pickupCoordinates,
    String? pickupAddress,
    String? pickupPlaceName,
    LatLng? destinationCoordinates,
    String? destinationAddress,
    String? destinationPlaceName,
    List<RideStop>? stops,
    double? estimatedFare,
    String? fareHash,
    double? distance,
    int? estimatedDuration,
    bool? isScheduled,
    DateTime? scheduledTime,
    String? paymentMethod,
    String? promoCode,
    String? specialRequests,
    int? passengerCount,
    String? cityName,
  }) {
    return RideRequest(
      userId: userId ?? this.userId,
      vehicleTypeId: vehicleTypeId ?? this.vehicleTypeId,
      vehicleType: vehicleType ?? this.vehicleType,
      pickupCoordinates: pickupCoordinates ?? this.pickupCoordinates,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupPlaceName: pickupPlaceName ?? this.pickupPlaceName,
      destinationCoordinates: destinationCoordinates ?? this.destinationCoordinates,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      destinationPlaceName: destinationPlaceName ?? this.destinationPlaceName,
      stops: stops ?? this.stops,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      fareHash: fareHash ?? this.fareHash,
      distance: distance ?? this.distance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      isScheduled: isScheduled ?? this.isScheduled,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      promoCode: promoCode ?? this.promoCode,
      specialRequests: specialRequests ?? this.specialRequests,
      passengerCount: passengerCount ?? this.passengerCount,
      cityName: cityName ?? this.cityName,
    );
  }

  // Helper getters
  String get formattedFare => '₦${estimatedFare.toStringAsFixed(0)}';
  String get formattedDistance => distance != null ? '${distance!.toStringAsFixed(1)} km' : '0 km';
  String get formattedDuration => estimatedDuration != null ? '$estimatedDuration min' : '0 min';
  bool get hasStops => stops != null && stops!.isNotEmpty;
  bool get hasPromo => promoCode != null && promoCode!.isNotEmpty;
}

/// Represents an intermediate stop in a ride
class RideStop {
  final LatLng coordinates;
  final String address;
  final String? placeName;
  final int order; // Order in the route (1, 2, 3...)
  final int? waitTimeMinutes; // How long to wait at this stop

  RideStop({
    required this.coordinates,
    required this.address,
    this.placeName,
    required this.order,
    this.waitTimeMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
      'address': address,
      if (placeName != null) 'place_name': placeName,
      'order': order,
      if (waitTimeMinutes != null) 'wait_time_minutes': waitTimeMinutes,
    };
  }

  factory RideStop.fromJson(Map<String, dynamic> json) {
    return RideStop(
      coordinates: LatLng(
        json['latitude'] ?? 0.0,
        json['longitude'] ?? 0.0,
      ),
      address: json['address'] ?? '',
      placeName: json['place_name'],
      order: json['order'] ?? 0,
      waitTimeMinutes: json['wait_time_minutes'],
    );
  }
}