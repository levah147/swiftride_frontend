// ==================== 1. route_arguments.dart - UPDATED ====================

import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route_stop.dart';

class RideOptionsArguments {
  final String from;
  final String to;
  final bool isScheduled;
  final LatLng pickupLatLng; // ✅ ADDED
  final LatLng destinationLatLng; // ✅ ADDED
  final String pickupAddress; // ✅ ADDED
  final String destinationAddress; // ✅ ADDED
  final String? city;

  // ✅ NEW: Support for multiple stops
  final List<RouteStop>?
      waypoints; // Optional waypoints between pickup and destination

  RideOptionsArguments({
    required this.from,
    required this.to,
    required this.isScheduled,
    required this.pickupLatLng, // ✅ ADDED
    required this.destinationLatLng, // ✅ ADDED
    required this.pickupAddress, // ✅ ADDED
    required this.destinationAddress, // ✅ ADDED
    this.city,
    this.waypoints, // ✅ NEW: Optional waypoints
  });
}

class DriverMatchingArguments {
  final String rideId;
  final LatLng from;
  final String to;
  final Map<String, dynamic> rideType;
  final bool isScheduled;

  DriverMatchingArguments({
    required this.rideId,
    required this.from,
    required this.to,
    required this.rideType,
    required this.isScheduled,
  });
}

class RideTrackingArguments {
  final String rideId;
  final String from;
  final String to;
  final Map<String, dynamic> rideType;
  final Map<String, dynamic> driver;

  RideTrackingArguments({
    required this.rideId,
    required this.from,
    required this.to,
    required this.rideType,
    required this.driver,
  });
}

class RideCompletionArguments {
  final String rideId;
  final String from;
  final String to;
  final Map<String, dynamic> rideType;
  final Map<String, dynamic> driver;
  final String duration;
  final String distance;

  RideCompletionArguments({
    this.rideId = '',
    required this.from,
    required this.to,
    required this.rideType,
    required this.driver,
    required this.duration,
    required this.distance,
  });
}
