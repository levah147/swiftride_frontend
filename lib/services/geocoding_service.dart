// ==================== services/geocoding_service.dart ====================
// GEOCODING SERVICE - Address ↔ Coordinates conversion
// Handles Google Places API and Geocoding API

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  static final GeocodingService _instance = GeocodingService._internal();
  factory GeocodingService() => _instance;
  GeocodingService._internal();

  // TODO: Replace with your Google Maps API key
  static const String _googleMapsApiKey = 'AIzaSyAPpZYwp6IjJhNDshFTxTsTaa05NxiTE3U';

  // ============================================
  // PLACE AUTOCOMPLETE
  // ============================================

  /// Get place suggestions based on search query
  Future<List<PlaceSuggestion>> getPlaceSuggestions({
    required String query,
    LatLng? location,
    int radius = 50000, // 50km
  }) async {
    if (query.isEmpty) return [];

    try {
      final url = _buildAutocompleteUrl(query, location, radius);
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          final predictions = data['predictions'] as List? ?? [];
          return predictions
              .map((p) => PlaceSuggestion.fromJson(p))
              .toList();
        } else {
          debugPrint('⚠️ Autocomplete API status: ${data['status']}');
          return [];
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Place autocomplete error: $e');
      return [];
    }
  }

  String _buildAutocompleteUrl(String query, LatLng? location, int radius) {
    var url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&key=$_googleMapsApiKey'
        '&components=country:ng'; // Restrict to Nigeria
    
    if (location != null) {
      url += '&location=${location.latitude},${location.longitude}'
          '&radius=$radius';
    }
    
    return url;
  }

  // ============================================
  // PLACE DETAILS
  // ============================================

  /// Get detailed information about a place
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId'
          '&key=$_googleMapsApiKey'
          '&fields=name,formatted_address,geometry,types';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result']);
        } else {
          debugPrint('⚠️ Place details API status: ${data['status']}');
          return null;
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Place details error: $e');
      return null;
    }
  }

  // ============================================
  // REVERSE GEOCODING
  // ============================================

  /// Convert coordinates to address
  Future<Address?> reverseGeocode(LatLng location) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${location.latitude},${location.longitude}'
          '&key=$_googleMapsApiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          if (results.isNotEmpty) {
            return Address.fromJson(results[0]);
          }
        } else {
          debugPrint('⚠️ Reverse geocoding status: ${data['status']}');
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Reverse geocoding error: $e');
      return null;
    }
  }

  // ============================================
  // FORWARD GEOCODING
  // ============================================

  /// Convert address to coordinates
  Future<LatLng?> forwardGeocode(String address) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json'
          '?address=${Uri.encodeComponent(address)}'
          '&key=$_googleMapsApiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          if (results.isNotEmpty) {
            final location = results[0]['geometry']['location'];
            return LatLng(location['lat'], location['lng']);
          }
        } else {
          debugPrint('⚠️ Forward geocoding status: ${data['status']}');
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Forward geocoding error: $e');
      return null;
    }
  }

  // ============================================
  // NEARBY SEARCH
  // ============================================

  /// Search for nearby places
  Future<List<PlaceDetails>> searchNearby({
    required LatLng location,
    required String type,
    int radius = 5000,
  }) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=${location.latitude},${location.longitude}'
          '&radius=$radius'
          '&type=$type'
          '&key=$_googleMapsApiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          return results
              .map((r) => PlaceDetails.fromJson(r))
              .toList();
        }
      }
      
      return [];
    } catch (e) {
      debugPrint('❌ Nearby search error: $e');
      return [];
    }
  }
}

// ============================================
// DATA MODELS
// ============================================

/// Place suggestion from autocomplete
class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: json['structured_formatting']?['main_text'] ?? '',
      secondaryText: json['structured_formatting']?['secondary_text'] ?? '',
    );
  }
}

/// Detailed place information
class PlaceDetails {
  final String placeId;
  final String name;
  final String formattedAddress;
  final LatLng location;
  final List<String> types;

  PlaceDetails({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.location,
    required this.types,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] ?? {};
    final loc = geometry['location'] ?? {};
    
    return PlaceDetails(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      formattedAddress: json['formatted_address'] ?? '',
      location: LatLng(
        loc['lat'] ?? 0.0,
        loc['lng'] ?? 0.0,
      ),
      types: (json['types'] as List?)?.map((t) => t.toString()).toList() ?? [],
    );
  }
}

/// Address from reverse geocoding
class Address {
  final String formattedAddress;
  final String? street;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final LatLng location;

  Address({
    required this.formattedAddress,
    this.street,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    required this.location,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    final components = json['address_components'] as List? ?? [];
    final geometry = json['geometry'] ?? {};
    final loc = geometry['location'] ?? {};
    
    String? getComponent(String type) {
      try {
        final component = components.firstWhere(
          (c) => (c['types'] as List).contains(type),
          orElse: () => {},
        );
        return component['long_name'];
      } catch (e) {
        return null;
      }
    }
    
    return Address(
      formattedAddress: json['formatted_address'] ?? '',
      street: getComponent('route'),
      city: getComponent('locality') ?? getComponent('administrative_area_level_2'),
      state: getComponent('administrative_area_level_1'),
      country: getComponent('country'),
      postalCode: getComponent('postal_code'),
      location: LatLng(
        loc['lat'] ?? 0.0,
        loc['lng'] ?? 0.0,
      ),
    );
  }
}