// ==================== services/location_service.dart ====================
// LOCATION SERVICE - Expanded version with comprehensive functionality
// Handles saved locations, recent locations, and geocoding
import 'dart:async'; // ✅ Add this import for TimeoutException
import 'package:flutter/foundation.dart';
import '../models/location.dart';
import 'api_client.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  final ApiClient _apiClient = ApiClient.instance;

  // ============================================
  // SAVED LOCATIONS (Home, Work, Favorites)
  // ============================================

  /// Get all saved locations
  Future<ApiResponse<List<SavedLocation>>> getSavedLocations() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/locations/saved/',
        fromJson: (data) => data is List ? data : [data],
      );
      
      if (response.isSuccess && response.data != null) {
        final locations = response.data!
            .map((json) => SavedLocation.fromJson(json as Map<String, dynamic>))
            .toList();
        
        return ApiResponse.success(
          locations,
          statusCode: response.statusCode,
        );
      }
      
      return ApiResponse.error(
        response.error ?? 'Failed to get saved locations',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('❌ Error getting saved locations: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Add a saved location (Home/Work/Favorite)
  Future<ApiResponse<SavedLocation>> addSavedLocation({
    required String type,
    required String address,
    required double latitude,
    required double longitude,
    String? placeName,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/locations/saved/',
        {
          'type': type,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          if (placeName != null) 'place_name': placeName,
        },
        fromJson: (data) =>
            data is Map ? data as Map<String, dynamic> : <String, dynamic>{},
      );
      
      if (response.isSuccess && response.data != null) {
        final location = SavedLocation.fromJson(response.data!);
        return ApiResponse.success(
          location,
          statusCode: response.statusCode,
        );
      }
      
      return ApiResponse.error(
        response.error ?? 'Failed to save location',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('❌ Error adding saved location: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Update a saved location
  Future<ApiResponse<SavedLocation>> updateSavedLocation({
    required String locationId,
    String? address,
    double? latitude,
    double? longitude,
    String? placeName,
  }) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/locations/saved/$locationId/',
        {
          if (address != null) 'address': address,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (placeName != null) 'place_name': placeName,
        },
        fromJson: (data) =>
            data is Map ? data as Map<String, dynamic> : <String, dynamic>{},
      );
      
      if (response.isSuccess && response.data != null) {
        final location = SavedLocation.fromJson(response.data!);
        return ApiResponse.success(
          location,
          statusCode: response.statusCode,
        );
      }
      
      return ApiResponse.error(
        response.error ?? 'Failed to update location',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('❌ Error updating saved location: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Delete a saved location
  Future<ApiResponse<void>> deleteSavedLocation(String locationId) async {
    try {
      final response = await _apiClient.delete<void>(
        '/locations/saved/$locationId/',
      );
      
      if (response.isSuccess) {
        return ApiResponse.success(
          null,
          statusCode: response.statusCode,
        );
      }
      
      return ApiResponse.error(
        response.error ?? 'Failed to delete location',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('❌ Error deleting saved location: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // ============================================
  // RECENT LOCATIONS
  // ============================================

  /// Get recent locations
  Future<ApiResponse<List<RecentLocation>>> getRecentLocations({
    int limit = 10,
  }) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/locations/recent/?limit=$limit',
        fromJson: (data) => data is List ? data : [data],
      );
      
      if (response.isSuccess && response.data != null) {
        final locations = response.data!
            .map((json) => RecentLocation.fromJson(json as Map<String, dynamic>))
            .toList();
        
        return ApiResponse.success(
          locations,
          statusCode: response.statusCode,
        );
      }
      
      return ApiResponse.error(
        response.error ?? 'Failed to get recent locations',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('❌ Error getting recent locations: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Add a recent location
  Future<ApiResponse<RecentLocation>> addRecentLocation({
    required String address,
    required double latitude,
    required double longitude,
    String? placeName,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/locations/recent/add/',
        {
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          if (placeName != null) 'place_name': placeName,
        },
        fromJson: (data) =>
            data is Map ? data as Map<String, dynamic> : <String, dynamic>{},
      );
      
      if (response.isSuccess && response.data != null) {
        final location = RecentLocation.fromJson(response.data!);
        return ApiResponse.success(
          location,
          statusCode: response.statusCode,
        );
      }
      
      return ApiResponse.error(
        response.error ?? 'Failed to add recent location',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('❌ Error adding recent location: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Clear all recent locations
  Future<ApiResponse<void>> clearRecentLocations() async {
    try {
      final response = await _apiClient.delete<void>(
        '/locations/recent/',
      );
      
      if (response.isSuccess) {
        return ApiResponse.success(
          null,
          statusCode: response.statusCode,
        );
      }
      
      return ApiResponse.error(
        response.error ?? 'Failed to clear recent locations',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('❌ Error clearing recent locations: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // ============================================
  // LOCATION UTILITIES
  // ============================================

    /// Get current device location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permission denied forever');
        return null;
      }

      // Get position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 30), // ✅ Add 30 second timeout
      ).timeout(
        Duration(seconds: 30), // ✅ Additional timeout wrapper
        onTimeout: () {
          debugPrint('❌ Location request timed out');
          throw TimeoutException('Location request timed out after 30 seconds');
        },
      );

      return position;
    } on TimeoutException catch (e) {
      debugPrint('❌ Location timeout: $e');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting current location: $e');
      return null;
    }
  }

  /// Convert coordinates to address
  Future<String?> getAddressFromCoordinates(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.administrativeArea}';
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error getting address: $e');
      return null;
    }
  }

  /// Convert address to coordinates
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        final loc = locations.first;
        return LatLng(loc.latitude, loc.longitude);
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error getting coordinates: $e');
      return null;
    }
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    ) / 1000; // Convert to km
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Listen to location changes
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }
}