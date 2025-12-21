// ==================== pricing_service.dart ====================
// Service for vehicle types, fare calculation, and pricing
// ✅ FIXED: Now matches Django backend parameter names exactly

import '../models/vehicle_type.dart';
import 'api_client.dart';
import 'package:flutter/foundation.dart';

class PricingService {
  final ApiClient _apiClient = ApiClient.instance;

  // ============================================
  // VEHICLE TYPES
  // ============================================
  
  /// Get available vehicle types for a city
  /// Django endpoint: GET /api/pricing/vehicle-types/?city=Lagos
  /// ✅ FIXED: Changed 'city_name' to 'city' to match backend
  Future<ApiResponse<List<VehicleType>>> getVehicleTypes({String? cityName}) async {
    try {
      debugPrint('🚗 Fetching vehicle types for city: ${cityName ?? "all"}');
      
      final queryParams = <String, String>{};
      if (cityName != null && cityName.isNotEmpty) {
        queryParams['city'] = cityName; // ✅ CHANGED from 'city_name' to 'city'
      }

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/pricing/vehicle-types/',
        queryParams: queryParams,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        
        // Backend returns: { "city": {...}, "vehicles": [...], "surge_multiplier": 1.0 }
        final vehiclesJson = data['vehicles'] as List<dynamic>?;
        
        if (vehiclesJson != null) {
          final vehicles = vehiclesJson
              .map((item) => VehicleType.fromJson(item as Map<String, dynamic>))
              .toList();
          
          debugPrint('✅ Loaded ${vehicles.length} vehicle types');
          return ApiResponse.success(vehicles, statusCode: response.statusCode);
        }
        
        return ApiResponse.error('No vehicles data in response');
      }

      return ApiResponse.error(
        response.error ?? 'Failed to load vehicle types',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('❌ Get Vehicle Types Error: $e');
      return ApiResponse.error('Failed to load vehicle types: ${e.toString()}');
    }
  }

  /// Get details of a specific vehicle type
  /// Django endpoint: GET /api/pricing/vehicle-types/{id}/
  Future<ApiResponse<VehicleType>> getVehicleTypeDetails(String vehicleTypeId) async {
    try {
      debugPrint('🚗 Fetching vehicle type: $vehicleTypeId');
      
      return await _apiClient.get<VehicleType>(
        '/pricing/vehicle-types/$vehicleTypeId/',
        fromJson: (json) => VehicleType.fromJson(json),
      );
    } catch (e) {
      debugPrint('❌ Get Vehicle Type Error: $e');
      return ApiResponse.error('Failed to load vehicle type: ${e.toString()}');
    }
  }

  // ============================================
  // FARE CALCULATION
  // ============================================
  
  /// Calculate fare for a ride
  /// Django endpoint: POST /api/pricing/calculate-fare/
  /// Returns fare breakdown with surge, fuel adjustments, etc.
  Future<ApiResponse<FareCalculation>> calculateFare({
    required String vehicleType,
    required double pickupLatitude,
    required double pickupLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    String? cityName,
  }) async {
    try {
      debugPrint('💰 Calculating fare...');
      debugPrint('   Vehicle: $vehicleType');
      debugPrint('   From: ($pickupLatitude, $pickupLongitude)');
      debugPrint('   To: ($destinationLatitude, $destinationLongitude)');
      
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/pricing/calculate-fare/',
        {
          'vehicle_type': vehicleType,
          'pickup_latitude': pickupLatitude,
          'pickup_longitude': pickupLongitude,
          'destination_latitude': destinationLatitude,
          'destination_longitude': destinationLongitude,
          if (cityName != null) 'city_name': cityName, // ✅ Backend accepts 'city_name' here
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final fareCalc = FareCalculation.fromJson(response.data!);
        debugPrint('✅ Fare calculated: ${fareCalc.formattedTotal}');
        return ApiResponse.success(fareCalc);
      }

      return ApiResponse.error(
        response.error ?? 'Failed to calculate fare',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('❌ Calculate Fare Error: $e');
      return ApiResponse.error('Failed to calculate fare: ${e.toString()}');
    }
  }

  /// Verify a fare hash before creating a ride
  /// Django endpoint: POST /api/pricing/verify-fare/
  Future<ApiResponse<Map<String, dynamic>>> verifyFare(String fareHash) async {
    try {
      debugPrint('🔒 Verifying fare hash...');
      
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/pricing/verify-fare/',
        {'fare_hash': fareHash},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final isValid = response.data!['valid'] == true;
        debugPrint(isValid ? '✅ Fare verified' : '❌ Fare invalid');
        return response;
      }

      return ApiResponse.error(
        response.error ?? 'Failed to verify fare',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('❌ Verify Fare Error: $e');
      return ApiResponse.error('Failed to verify fare: ${e.toString()}');
    }
  }

  // ============================================
  // SURGE PRICING
  // ============================================
  
  /// Get current surge multiplier for a city
  /// Django endpoint: GET /api/pricing/surge-info/?city=Lagos
  Future<ApiResponse<Map<String, dynamic>>> getSurgeInfo({String? cityName}) async {
    try {
      final queryParams = <String, String>{};
      if (cityName != null && cityName.isNotEmpty) {
        queryParams['city'] = cityName; // ✅ CHANGED from 'city_name' to 'city'
      }

      return await _apiClient.get<Map<String, dynamic>>(
        '/pricing/surge-info/',
        queryParams: queryParams,
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Get Surge Info Error: $e');
      return ApiResponse.error('Failed to get surge info: ${e.toString()}');
    }
  }
  

  // ============================================
  // CITIES
  // ============================================
  
  /// Get list of cities where service is available
  /// Django endpoint: GET /api/pricing/cities/
  Future<ApiResponse<List<Map<String, dynamic>>>> getCities() async {
    try {
      debugPrint('🌍 Fetching available cities...');
      
      final response = await _apiClient.get<List<dynamic>>(
        '/pricing/cities/',
        fromJson: (json) => json is List ? json : [json],
      );

      if (response.isSuccess && response.data != null) {
        final cities = response.data!
            .map((e) => e as Map<String, dynamic>)
            .toList();
        
        debugPrint('✅ Loaded ${cities.length} cities');
        return ApiResponse.success(cities, statusCode: response.statusCode);
      }

      return ApiResponse.error(
        response.error ?? 'Failed to load cities',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('❌ Get Cities Error: $e');
      return ApiResponse.error('Failed to load cities: ${e.toString()}');
    }
  }

  /// Detect city from coordinates
  /// Django endpoint: POST /api/pricing/detect-city/
  Future<ApiResponse<Map<String, dynamic>>> detectCity({
    required double latitude,
    required double longitude,
  }) async {
    try {
      debugPrint('🌍 Detecting city from coordinates: $latitude, $longitude');
      
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/pricing/detect-city/',
        {
          'latitude': latitude,
          'longitude': longitude,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final cityName = response.data!['name'] as String?;
        debugPrint('✅ City detected: $cityName');
        return response;
      }

      return ApiResponse.error(
        response.error ?? 'Failed to detect city',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('❌ Detect City Error: $e');
      return ApiResponse.error('Failed to detect city: ${e.toString()}');
    }
  }
}

// ============================================
// FARE CALCULATION MODEL
// ============================================

class FareCalculation {
  final String fareHash;
  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double surgeMultiplier;
  final double fuelAdjustment;
  final double totalFare;
  final double distance;
  final int estimatedDuration;
  final String? cityName;
  final int? cityId; // ✅ NEW: Store city ID for ride creation
  final String? vehicleType;
  final String? vehicleTypeId;
  final String currency;
  final String currencySymbol;
  final double minimumFare;
  final double cancellationFee;
  final Map<String, dynamic>? breakdown;
  final Map<String, dynamic>? driverEarnings;

  FareCalculation({
    required this.fareHash,
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.surgeMultiplier,
    required this.fuelAdjustment,
    required this.totalFare,
    required this.distance,
    required this.estimatedDuration,
    this.cityName,
    this.cityId,
    this.vehicleType,
    this.vehicleTypeId,
    this.currency = 'NGN',
    this.currencySymbol = '₦',
    this.minimumFare = 0.0,
    this.cancellationFee = 0.0,
    this.breakdown,
    this.driverEarnings,
  });

  factory FareCalculation.fromJson(Map<String, dynamic> json) {
    return FareCalculation(
      fareHash: json['fare_hash'] ?? '',
      baseFare: _parseDouble(json['base_fare']) ?? 0.0,
      distanceFare: _parseDouble(json['distance_fare']) ?? 0.0,
      timeFare: _parseDouble(json['time_fare']) ?? 0.0,
      surgeMultiplier: _parseDouble(json['surge_multiplier']) ?? 1.0,
      fuelAdjustment: _parseDouble(json['fuel_adjustment_total']) ?? 
                      _parseDouble(json['fuel_adjustment']) ?? 0.0,
      totalFare: _parseDouble(json['total_fare']) ?? 0.0,
      distance: _parseDouble(json['distance_km']) ?? 
                _parseDouble(json['distance']) ?? 0.0,
      estimatedDuration: json['estimated_duration_minutes'] ?? 
                         json['estimated_duration'] ?? 0,
      cityName: json['city_name'],
      cityId: json['city_id'], // ✅ NEW: Get city ID from backend
      vehicleType: json['vehicle_type'],
      vehicleTypeId: json['vehicle_type_id'],
      currency: json['currency'] ?? 'NGN',
      currencySymbol: json['currency_symbol'] ?? '₦',
      minimumFare: _parseDouble(json['minimum_fare']) ?? 0.0,
      cancellationFee: _parseDouble(json['cancellation_fee']) ?? 0.0,
      breakdown: json['breakdown'] as Map<String, dynamic>?,
      driverEarnings: json['driver_earnings'] as Map<String, dynamic>?,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'fare_hash': fareHash,
      'base_fare': baseFare,
      'distance_fare': distanceFare,
      'time_fare': timeFare,
      'surge_multiplier': surgeMultiplier,
      'fuel_adjustment': fuelAdjustment,
      'total_fare': totalFare,
      'distance': distance,
      'estimated_duration': estimatedDuration,
      'city_name': cityName,
      'city_id': cityId,
      'vehicle_type': vehicleType,
      'vehicle_type_id': vehicleTypeId,
      'currency': currency,
      'currency_symbol': currencySymbol,
      'minimum_fare': minimumFare,
      'cancellation_fee': cancellationFee,
      if (breakdown != null) 'breakdown': breakdown,
      if (driverEarnings != null) 'driver_earnings': driverEarnings,
    };
  }

  // Formatted strings
  String get formattedTotal => '$currencySymbol${totalFare.toStringAsFixed(0)}';
  String get formattedBase => '$currencySymbol${baseFare.toStringAsFixed(0)}';
  String get formattedDistance => '${distance.toStringAsFixed(1)} km';
  String get formattedDuration => '${estimatedDuration} min';
  String get formattedSurge => '${surgeMultiplier.toStringAsFixed(1)}x';
  
  bool get hasSurge => surgeMultiplier > 1.0;
  bool get hasFuelAdjustment => fuelAdjustment != 0.0;
  
  @override
  String toString() {
    return 'FareCalculation(total: $formattedTotal, distance: $formattedDistance, duration: $formattedDuration)';
  }
}