// ==================== services/location_service.dart ====================
// ENHANCED LOCATION SERVICE - Added backend reverse geocoding
// Handles saved locations, recent locations, and robust geocoding

import 'dart:async';
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
  // 🆕 BACKEND REVERSE GEOCODING (NEW!)
  // ============================================

  /// Convert coordinates to city name using backend API
  /// This is more reliable than device geocoding for Nigeria/Africa
  Future<ApiResponse<Map<String, String>>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      debugPrint('🌐 Backend reverse geocoding: $latitude, $longitude');
      
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/locations/reverse-geocode/?lat=$latitude&lng=$longitude',
        fromJson: (data) =>
            data is Map ? data as Map<String, dynamic> : <String, dynamic>{},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          return ApiResponse.error('Backend geocoding timeout');
        },
      );
      
      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        
        // Extract location data from backend response
        final result = <String, String>{
          'city': data['city']?.toString() ?? 
                  data['town']?.toString() ?? 
                  data['village']?.toString() ?? '',
          'state': data['state']?.toString() ?? 
                   data['region']?.toString() ?? '',
          'country': data['country']?.toString() ?? '',
          'address': data['display_name']?.toString() ?? 
                     data['formatted']?.toString() ?? '',
        };
        
        debugPrint('✅ Backend geocoding success: ${result['city']}');
        return ApiResponse.success(result, statusCode: response.statusCode);
      }
      
      return ApiResponse.error(
        response.error ?? 'Backend geocoding failed',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('❌ Backend geocoding error: $e');
      return ApiResponse.error('Backend geocoding error: ${e.toString()}');
    }
  }

  // ============================================
  // LOCATION UTILITIES
  // ============================================

  Future<Position?> getCurrentLocation() async {
    try {
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

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // ✅ Changed from high
        timeLimit: const Duration(seconds: 30), // ✅ Increased timeout
      ).timeout(
        const Duration(seconds: 30),
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

  /// Convert coordinates to address using device geocoding
  Future<String?> getAddressFromCoordinates(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      ).timeout(const Duration(seconds: 10));

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.administrativeArea}';
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error getting address: $e');
      
      // Fallback to backend
      try {
        final response = await reverseGeocode(
          latitude: location.latitude,
          longitude: location.longitude,
        );
        
        if (response.isSuccess && response.data != null) {
          return response.data!['address'];
        }
      } catch (backendError) {
        debugPrint('❌ Backend address lookup also failed: $backendError');
      }
      
      return null;
    }
  }

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

  double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    ) / 1000;
  }

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }
}