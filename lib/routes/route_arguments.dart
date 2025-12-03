// Arguments models for passing data through routes

import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideOptionsArguments {
  final String from;
  final String to;
  final bool isScheduled;

  RideOptionsArguments({
    required this.from,
    required this.to,
    required this.isScheduled,
  });
}

class DriverMatchingArguments {
  final String rideId;  // ✅ ADDED: Required for DriverMatchingScreen
  final LatLng from;    // ✅ CHANGED: String → LatLng (coordinates)
  final String to;      // Keep as String (address)
  final Map<String, dynamic> rideType;
  final bool isScheduled;

  DriverMatchingArguments({
    required this.rideId,  // ✅ NEW
    required this.from,
    required this.to,
    required this.rideType,
    required this.isScheduled,
  });
}

class RideTrackingArguments {
  final String rideId;  // ✅ ADDED: Required for RideTrackingScreen
  final String from;
  final String to;
  final Map<String, dynamic> rideType;
  final Map<String, dynamic> driver;

  RideTrackingArguments({
    required this.rideId,  // ✅ NEW
    required this.from,
    required this.to,
    required this.rideType,
    required this.driver,
  });
}

class RideCompletionArguments {
  final String rideId;  // ✅ OPTIONAL: Could be useful for completion tracking
  final String from;
  final String to;
  final Map<String, dynamic> rideType;
  final Map<String, dynamic> driver;
  final String duration;
  final String distance;

  RideCompletionArguments({
    this.rideId = '',  // ✅ Optional with default
    required this.from,
    required this.to,
    required this.rideType,
    required this.driver,
    required this.duration,
    required this.distance,
  });
}