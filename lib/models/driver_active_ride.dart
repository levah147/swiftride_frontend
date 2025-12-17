class DriverActiveRide {
  final String id;
  final String riderName;
  final String riderPhone;
  final double riderRating;
  final String pickupLocation;
  final String destinationLocation;
  final double pickupLatitude;
  final double pickupLongitude;
  final double destinationLatitude;
  final double destinationLongitude;
  final String status;
  final double? fareAmount;
  final double? distanceKm;

  DriverActiveRide({
    required this.id,
    required this.riderName,
    required this.riderPhone,
    required this.riderRating,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.status,
    this.fareAmount,
    this.distanceKm,
  });

  factory DriverActiveRide.fromJson(Map<String, dynamic> json) {
    return DriverActiveRide(
      id: json['id'].toString(),
      riderName: json['rider_name'] ?? '',
      riderPhone: json['rider_phone'] ?? '',
      riderRating: _toDouble(json['rider_rating'], fallback: 5.0),
      pickupLocation: json['pickup_location'] ?? '',
      destinationLocation: json['destination_location'] ?? '',
      pickupLatitude: _toDouble(json['pickup_latitude']),
      pickupLongitude: _toDouble(json['pickup_longitude']),
      destinationLatitude: _toDouble(json['destination_latitude']),
      destinationLongitude: _toDouble(json['destination_longitude']),
      status: json['status'] ?? '',
      fareAmount: _tryDouble(json['fare_amount']),
      distanceKm: _tryDouble(json['distance_km']),
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
