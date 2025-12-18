// ==================== services/map_service.dart ====================
// GOOGLE MAPS SERVICE - Map operations and routing
// Handles all Google Maps API interactions

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/route_info.dart';

class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  // ✅ FIXED: Use environment variable or config for API key
  // TODO: Move to secure storage (flutter_dotenv or similar)
  // For now, this should be set via environment variable or build config
  static const String _googleMapsApiKey = String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY',
      defaultValue:
          'AIzaSyAPpZYwp6IjJhNDshFTxTsTaa05NxiTE3U'); // ⚠️ Remove hardcoded key in production

  // ============================================
  // ROUTE CALCULATIONS
  // ============================================

  /// Get route between two points
  Future<RouteInfo> getRoute({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
    bool alternatives = false,
  }) async {
    try {
      final url =
          _buildDirectionsUrl(origin, destination, waypoints, alternatives);

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK') {
          return RouteInfo.fromGoogleMapsResponse(data);
        } else {
          throw Exception('Directions API error: ${data['status']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Route calculation error: $e');
      rethrow;
    }
  }

  String _buildDirectionsUrl(LatLng origin, LatLng destination,
      List<LatLng>? waypoints, bool alternatives) {
    final originStr = '${origin.latitude},${origin.longitude}';
    final destStr = '${destination.latitude},${destination.longitude}';

    var url = 'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$originStr'
        '&destination=$destStr'
        '&key=$_googleMapsApiKey'
        '&alternatives=$alternatives';

    if (waypoints != null && waypoints.isNotEmpty) {
      final waypointsStr =
          waypoints.map((w) => '${w.latitude},${w.longitude}').join('|');
      url += '&waypoints=$waypointsStr';
    }

    return url;
  }

  // ============================================
  // DISTANCE CALCULATIONS
  // ============================================

  /// Calculate distance between two points in kilometers
  double calculateDistance(LatLng from, LatLng to) {
    const p = 0.017453292519943295; // pi/180
    final a = 0.5 -
        math.cos((to.latitude - from.latitude) * p) / 2 +
        math.cos(from.latitude * p) *
            math.cos(to.latitude * p) *
            (1 - math.cos((to.longitude - from.longitude) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a));
  }

  // ============================================
  // MARKER CREATION
  // ============================================

  /// Create standard markers for pickup, destination, and driver
  Future<Map<String, Marker>> createRideMarkers({
    required LatLng pickup,
    required LatLng destination,
    LatLng? driverLocation,
  }) async {
    final markers = <String, Marker>{};

    // Pickup marker
    markers['pickup'] = Marker(
      markerId: const MarkerId('pickup'),
      position: pickup,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: 'Pickup Location'),
    );

    // Destination marker
    markers['destination'] = Marker(
      markerId: const MarkerId('destination'),
      position: destination,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'Destination'),
    );

    // Driver marker (if provided)
    if (driverLocation != null) {
      markers['driver'] = Marker(
        markerId: const MarkerId('driver'),
        position: driverLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Driver'),
        rotation: 0,
      );
    }

    return markers;
  }

  // ============================================
  // POLYLINE CREATION
  // ============================================

  /// Create polyline from route
  Polyline createPolyline(RouteInfo route, {String polylineId = 'route'}) {
    return Polyline(
      polylineId: PolylineId(polylineId),
      points: route.polylinePoints,
      color: route.polylineColor,
      width: 5,
      patterns:
          route.hasTraffic ? [PatternItem.dash(10), PatternItem.gap(5)] : [],
    );
  }

  // ============================================
  // CAMERA OPERATIONS
  // ============================================

  /// Get camera position to fit bounds
  CameraPosition getCameraPositionForBounds(LatLngBounds bounds,
      {double zoom = 15}) {
    final center = LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );

    return CameraPosition(
      target: center,
      zoom: zoom,
      tilt: 0,
    );
  }

  /// Animate camera to fit route
  Future<void> animateCameraToRoute(
    GoogleMapController controller,
    RouteInfo route, {
    EdgeInsets padding = const EdgeInsets.all(50),
  }) async {
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(route.bounds, 50),
    );
  }
}
