// ==================== models/route_info.dart ====================
// ROUTE INFO MODEL - Route polyline and details
// Used for displaying routes on Google Maps

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

/// Represents complete route information including polyline
class RouteInfo {
  // Route points
  final List<LatLng> polylinePoints;
  final String encodedPolyline; // Google Maps encoded polyline
  
  // Distance & duration
  final double distanceInMeters;
  final int durationInSeconds;
  
  // Map bounds
  final LatLngBounds bounds;
  
  // Route metadata
  final String? routeSummary; // e.g., "via N1 Highway"
  final List<RouteStep>? steps; // Turn-by-turn directions
  final bool hasTraffic;
  final TrafficLevel? trafficLevel;
  
  // Alternative routes
  final List<RouteInfo>? alternativeRoutes;

  RouteInfo({
    required this.polylinePoints,
    required this.encodedPolyline,
    required this.distanceInMeters,
    required this.durationInSeconds,
    required this.bounds,
    this.routeSummary,
    this.steps,
    this.hasTraffic = false,
    this.trafficLevel,
    this.alternativeRoutes,
  });

  /// Create from Google Maps API response
  factory RouteInfo.fromGoogleMapsResponse(Map<String, dynamic> json) {
    final route = json['routes']?[0];
    if (route == null) {
      throw Exception('No routes found in response');
    }

    final leg = route['legs']?[0];
    final polyline = route['overview_polyline']?['points'] ?? '';
    
    // Decode polyline
    final points = _decodePolyline(polyline);
    
    // Get bounds
    final northeast = route['bounds']?['northeast'];
    final southwest = route['bounds']?['southwest'];
    final bounds = LatLngBounds(
      southwest: LatLng(
        southwest?['lat'] ?? 0.0,
        southwest?['lng'] ?? 0.0,
      ),
      northeast: LatLng(
        northeast?['lat'] ?? 0.0,
        northeast?['lng'] ?? 0.0,
      ),
    );

    // Parse steps if available
    List<RouteStep>? steps;
    if (leg?['steps'] != null) {
      steps = (leg['steps'] as List)
          .map((step) => RouteStep.fromJson(step))
          .toList();
    }

    return RouteInfo(
      polylinePoints: points,
      encodedPolyline: polyline,
      distanceInMeters: (leg?['distance']?['value'] ?? 0).toDouble(),
      durationInSeconds: leg?['duration']?['value'] ?? 0,
      bounds: bounds,
      routeSummary: route['summary'],
      steps: steps,
      hasTraffic: leg?['duration_in_traffic'] != null,
    );
  }

  /// Create from backend API response
  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    final points = json['polyline_points'] != null
        ? (json['polyline_points'] as List)
            .map((p) => LatLng(p['lat'], p['lng']))
            .toList()
        : _decodePolyline(json['encoded_polyline'] ?? '');

    return RouteInfo(
      polylinePoints: points,
      encodedPolyline: json['encoded_polyline'] ?? '',
      distanceInMeters: _parseDouble(json['distance']) ?? 0.0,
      durationInSeconds: json['duration'] ?? 0,
      bounds: LatLngBounds(
        southwest: LatLng(
          json['bounds']?['southwest']?['lat'] ?? 0.0,
          json['bounds']?['southwest']?['lng'] ?? 0.0,
        ),
        northeast: LatLng(
          json['bounds']?['northeast']?['lat'] ?? 0.0,
          json['bounds']?['northeast']?['lng'] ?? 0.0,
        ),
      ),
      routeSummary: json['summary'],
      hasTraffic: json['has_traffic'] ?? false,
      trafficLevel: json['traffic_level'] != null
          ? TrafficLevel.fromString(json['traffic_level'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'encoded_polyline': encodedPolyline,
      'distance': distanceInMeters,
      'duration': durationInSeconds,
      'summary': routeSummary,
      'has_traffic': hasTraffic,
      if (trafficLevel != null) 'traffic_level': trafficLevel!.name,
      'bounds': {
        'southwest': {
          'lat': bounds.southwest.latitude,
          'lng': bounds.southwest.longitude,
        },
        'northeast': {
          'lat': bounds.northeast.latitude,
          'lng': bounds.northeast.longitude,
        },
      },
    };
  }

  // Helper getters
  double get distanceInKm => distanceInMeters / 1000;
  int get durationInMinutes => (durationInSeconds / 60).ceil();
  String get formattedDistance => '${distanceInKm.toStringAsFixed(1)} km';
  String get formattedDuration => '$durationInMinutes min';
  
  /// Get color for polyline based on traffic
  Color get polylineColor {
    if (!hasTraffic || trafficLevel == null) {
      return const Color(0xFF0066FF); // Default blue
    }
    
    switch (trafficLevel!) {
      case TrafficLevel.low:
        return const Color(0xFF10B981); // Green
      case TrafficLevel.moderate:
        return const Color(0xFFF59E0B); // Orange
      case TrafficLevel.heavy:
        return const Color(0xFFEF4444); // Red
    }
  }

  /// Decode Google Maps polyline string to LatLng points
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int shift = 0;
      int result = 0;
      int b;
      
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Represents a single step in turn-by-turn directions
class RouteStep {
  final String instruction; // HTML instructions
  final double distanceInMeters;
  final int durationInSeconds;
  final LatLng startLocation;
  final LatLng endLocation;
  final String? maneuver; // e.g., "turn-left", "turn-right"

  RouteStep({
    required this.instruction,
    required this.distanceInMeters,
    required this.durationInSeconds,
    required this.startLocation,
    required this.endLocation,
    this.maneuver,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    return RouteStep(
      instruction: json['html_instructions'] ?? json['instruction'] ?? '',
      distanceInMeters: (json['distance']?['value'] ?? 0).toDouble(),
      durationInSeconds: json['duration']?['value'] ?? 0,
      startLocation: LatLng(
        json['start_location']?['lat'] ?? 0.0,
        json['start_location']?['lng'] ?? 0.0,
      ),
      endLocation: LatLng(
        json['end_location']?['lat'] ?? 0.0,
        json['end_location']?['lng'] ?? 0.0,
      ),
      maneuver: json['maneuver'],
    );
  }

  String get formattedDistance => '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
  String get formattedDuration => '${(durationInSeconds / 60).ceil()} min';
  
  /// Get clean text instruction (remove HTML tags)
  String get cleanInstruction {
    return instruction
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }
}

/// Traffic level enum
enum TrafficLevel {
  low,
  moderate,
  heavy;

  String get displayName {
    switch (this) {
      case TrafficLevel.low:
        return 'Light Traffic';
      case TrafficLevel.moderate:
        return 'Moderate Traffic';
      case TrafficLevel.heavy:
        return 'Heavy Traffic';
    }
  }

  Color get color {
    switch (this) {
      case TrafficLevel.low:
        return const Color(0xFF10B981);
      case TrafficLevel.moderate:
        return const Color(0xFFF59E0B);
      case TrafficLevel.heavy:
        return const Color(0xFFEF4444);
    }
  }

  static TrafficLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
      case 'light':
        return TrafficLevel.low;
      case 'moderate':
      case 'medium':
        return TrafficLevel.moderate;
      case 'heavy':
      case 'high':
        return TrafficLevel.heavy;
      default:
        return TrafficLevel.low;
    }
  }
}