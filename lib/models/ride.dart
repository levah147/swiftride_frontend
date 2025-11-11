// ==================== models/ride.dart ====================
// COMPLETE RIDE MODEL - Production Ready
// Handles all backend API responses

import 'package:flutter/material.dart';

enum RideStatus {
  pending,
  driverAssigned,
  driverArriving,
  inProgress,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case RideStatus.pending:
        return 'Finding Driver';
      case RideStatus.driverAssigned:
        return 'Driver Assigned';
      case RideStatus.driverArriving:
        return 'Driver Arriving';
      case RideStatus.inProgress:
        return 'In Progress';
      case RideStatus.completed:
        return 'Completed';
      case RideStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case RideStatus.pending:
        return const Color(0xFFF59E0B);
      case RideStatus.driverAssigned:
      case RideStatus.driverArriving:
        return const Color(0xFF0066FF);
      case RideStatus.inProgress:
        return const Color(0xFF7C3AED);
      case RideStatus.completed:
        return const Color(0xFF10B981);
      case RideStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  static RideStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return RideStatus.pending;
      case 'driver_assigned':
      case 'accepted':
        return RideStatus.driverAssigned;
      case 'driver_arriving':
      case 'arriving':
        return RideStatus.driverArriving;
      case 'in_progress':
      case 'started':
        return RideStatus.inProgress;
      case 'completed':
        return RideStatus.completed;
      case 'cancelled':
        return RideStatus.cancelled;
      default:
        return RideStatus.pending;
    }
  }
}

class Ride {
  final String id;
  final String userId;
  final String? driverId;
  final String rideType;
  final RideStatus status;
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String destinationAddress;
  final double destinationLatitude;
  final double destinationLongitude;
  final double? fare;
  final double? distance;
  final int? estimatedDuration;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Driver? driver;

  Ride({
    required this.id,
    required this.userId,
    this.driverId,
    required this.rideType,
    required this.status,
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.destinationAddress,
    required this.destinationLatitude,
    required this.destinationLongitude,
    this.fare,
    this.distance,
    this.estimatedDuration,
    required this.createdAt,
    this.completedAt,
    this.driver,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    try {
      return Ride(
        id: json['id'].toString(),
        userId: json['user_id']?.toString() ?? '',
        driverId: json['driver_id']?.toString(),
        rideType: json['ride_type'] ?? 'swift_go',
        status: RideStatus.fromString(json['status'] ?? 'pending'),
        pickupAddress: json['pickup_address'] ?? json['pickup_location'] ?? '',
        pickupLatitude: _parseDouble(json['pickup_latitude']) ?? 0.0,
        pickupLongitude: _parseDouble(json['pickup_longitude']) ?? 0.0,
        destinationAddress: json['destination_address'] ?? json['dropoff_location'] ?? '',
        destinationLatitude: _parseDouble(json['destination_latitude']) ?? 0.0,
        destinationLongitude: _parseDouble(json['destination_longitude']) ?? 0.0,
        fare: _parseDouble(json['fare'] ?? json['fare_amount']),
        distance: _parseDouble(json['distance']),
        estimatedDuration: json['estimated_duration'] as int?,
        createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
        completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
        driver: json['driver'] != null ? Driver.fromJson(json['driver']) : null,
      );
    } catch (e) {
      debugPrint('❌ Error parsing Ride: $e');
      debugPrint('JSON: $json');
      rethrow;
    }
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'driver_id': driverId,
      'ride_type': rideType,
      'status': status.name,
      'pickup_address': pickupAddress,
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'destination_address': destinationAddress,
      'destination_latitude': destinationLatitude,
      'destination_longitude': destinationLongitude,
      'fare': fare,
      'distance': distance,
      'estimated_duration': estimatedDuration,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  // Helper getters
  bool get hasDriver => driverId != null;
  bool get isActive => status == RideStatus.pending ||
      status == RideStatus.driverAssigned ||
      status == RideStatus.driverArriving ||
      status == RideStatus.inProgress;
  bool get isCompleted => status == RideStatus.completed;
  bool get isCancelled => status == RideStatus.cancelled;

  String get formattedFare => fare != null ? '₦${fare!.toStringAsFixed(0)}' : '₦0';
  String get formattedDistance => distance != null ? '${distance!.toStringAsFixed(1)} km' : '0 km';
  String get formattedDuration => estimatedDuration != null ? '${estimatedDuration! ~/ 60} min' : '0 min';
}

class Driver {
  final String id;
  final String name;
  final String phoneNumber;
  final double rating;
  final String vehicleModel;
  final String vehicleColor;
  final String licensePlate;
  final String? profileImage;

  Driver({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.rating,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.licensePlate,
    this.profileImage,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'].toString(),
      name: json['name'] ?? json['full_name'] ?? 'Driver',
      phoneNumber: json['phone_number'] ?? '',
      rating: (json['rating'] ?? 5.0).toDouble(),
      vehicleModel: json['vehicle_model'] ?? '',
      vehicleColor: json['vehicle_color'] ?? '',
      licensePlate: json['license_plate'] ?? json['vehicle_plate'] ?? '',
      profileImage: json['profile_image'] ?? json['profile_picture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'rating': rating,
      'vehicle_model': vehicleModel,
      'vehicle_color': vehicleColor,
      'license_plate': licensePlate,
      'profile_image': profileImage,
    };
  }
}