import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverAvailableRide {
  final String id;
  final String pickupLocation;
  final String destinationLocation;
  final LatLng pickupLatLng;
  final LatLng destinationLatLng;
  final double? fareAmount;
  final double? distanceKm;
  final String riderName;
  final double riderRating;
  final DateTime? expiresAt;
  final int timeRemainingSeconds;

  DriverAvailableRide({
    required this.id,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.pickupLatLng,
    required this.destinationLatLng,
    this.fareAmount,
    this.distanceKm,
    required this.riderName,
    required this.riderRating,
    this.expiresAt,
    required this.timeRemainingSeconds,
  });

  factory DriverAvailableRide.fromJson(Map<String, dynamic> json) {
    return DriverAvailableRide(
      id: json['id'].toString(),
      pickupLocation: json['pickup_location'] ?? '',
      destinationLocation: json['destination_location'] ?? '',
      pickupLatLng: LatLng(
        _toDouble(json['pickup_latitude']),
        _toDouble(json['pickup_longitude']),
      ),
      destinationLatLng: LatLng(
        _toDouble(json['destination_latitude']),
        _toDouble(json['destination_longitude']),
      ),
      fareAmount: _tryDouble(json['fare_amount']),
      distanceKm: _tryDouble(json['distance_km']),
      riderName: json['rider_name'] ?? '',
      riderRating: _toDouble(json['rider_rating'], fallback: 5.0),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'])
          : null,
      timeRemainingSeconds: json['time_remaining'] ?? 0,
    );
  }

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static double? _tryDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String get formattedFare =>
      fareAmount != null ? '₦${fareAmount!.toStringAsFixed(0)}' : '—';
  String get formattedDistance =>
      distanceKm != null ? '${distanceKm!.toStringAsFixed(1)} km' : '—';
}
