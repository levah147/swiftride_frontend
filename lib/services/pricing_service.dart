// ==================== pricing_service.dart ====================
// Service for vehicle types, fare calculation, and pricing
// Matches Django /api/pricing/ endpoints

import '../models/vehicle_type.dart';
import 'api_client.dart';
import 'package:flutter/foundation.dart';

class PricingService {
  final ApiClient _apiClient = ApiClient.instance;

  // ============================================
  // VEHICLE TYPES
  // ============================================
  
  /// Get available vehicle types for a city
  /// Django endpoint: GET /api/pricing/vehicle-types/
  /// Query params: ?city_name=Lagos
  Future<ApiResponse<List<VehicleType>>> getVehicleTypes({String? cityName}) async {
    try {
      debugPrint('🚗 Fetching vehicle types for city: ${cityName ?? "all"}');
      
      final queryParams = <String, String>{};
      if (cityName != null) {
        queryParams['city_name'] = cityName;
      }

      return await _apiClient.get<List<VehicleType>>(
        '/pricing/vehicle-types/',
        queryParams: queryParams,
        fromJson: (json) {
          if (json is List) {
            return json.map((item) => VehicleType.fromJson(item)).toList();
          }
          return [];
        },
      );
    } catch (e) {
      debugPrint('❌ Get Vehicle Types Error: $e');
      return ApiResponse.error('Failed to load vehicle types: ${e.toString()}');
    }
  }

  /// Get details of a specific vehicle type
  /// Django endpoint: GET /api/pricing/types/{id}/
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
          if (cityName != null) 'city_name': cityName,
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

  // ============================================
  // SURGE PRICING
  // ============================================
  
  /// Get current surge multiplier for a city
  /// Django endpoint: GET /api/pricing/surge/
  Future<ApiResponse<Map<String, dynamic>>> getSurgeInfo({String? cityName}) async {
    try {
      final queryParams = <String, String>{};
      if (cityName != null) {
        queryParams['city_name'] = cityName;
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
  // FUEL PRICING
  // ============================================
  
  /// Get current fuel price for a city
  /// Django endpoint: GET /api/pricing/fuel-price/
  // Future<ApiResponse<Map<String, dynamic>>> getFuelPrice({String? cityName}) async {
  //   try {
  //     final queryParams = <String, String>{};
  //     if (cityName != null) {
  //       queryParams['city_name'] = cityName;
  //     }

      // return await _apiClient.get<Map<String, dynamic>>(
        // '/pricing/fuel-price/',
  //       queryParams: queryParams,
  //       fromJson: (json) => json as Map<String, dynamic>,
  //     );
  //   } catch (e) {
  //     debugPrint('❌ Get Fuel Price Error: $e');
  //     return ApiResponse.error('Failed to get fuel price: ${e.toString()}');
  //   }
  // }

  // ============================================
  // CITIES
  // ============================================
  
  /// Get list of cities where service is available
  /// Django endpoint: GET /api/pricing/cities/
  Future<ApiResponse<List<Map<String, dynamic>>>> getCities() async {
    try {
      debugPrint('🌍 Fetching available cities...');
      
      return await _apiClient.get<List<Map<String, dynamic>>>(
        '/pricing/cities/',
        fromJson: (json) {
          if (json is List) {
            return json.map((e) => e as Map<String, dynamic>).toList();
          }
          return [];
        },
      );
    } catch (e) {
      debugPrint('❌ Get Cities Error: $e');
      return ApiResponse.error('Failed to load cities: ${e.toString()}');
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
  final String? vehicleType;

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
    this.vehicleType,
  });

  factory FareCalculation.fromJson(Map<String, dynamic> json) {
    return FareCalculation(
      fareHash: json['fare_hash'] ?? '',
      baseFare: _parseDouble(json['base_fare']) ?? 0.0,
      distanceFare: _parseDouble(json['distance_fare']) ?? 0.0,
      timeFare: _parseDouble(json['time_fare']) ?? 0.0,
      surgeMultiplier: _parseDouble(json['surge_multiplier']) ?? 1.0,
      fuelAdjustment: _parseDouble(json['fuel_adjustment']) ?? 0.0,
      totalFare: _parseDouble(json['total_fare']) ?? 0.0,
      distance: _parseDouble(json['distance']) ?? 0.0,
      estimatedDuration: json['estimated_duration'] ?? 0,
      cityName: json['city_name'],
      vehicleType: json['vehicle_type'],
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
      'vehicle_type': vehicleType,
    };
  }

  // Formatted strings
  String get formattedTotal => '₦${totalFare.toStringAsFixed(0)}';
  String get formattedBase => '₦${baseFare.toStringAsFixed(0)}';
  String get formattedDistance => '${distance.toStringAsFixed(1)} km';
  String get formattedDuration => '${estimatedDuration} min';
  
  bool get hasSurge => surgeMultiplier > 1.0;
  bool get hasFuelAdjustment => fuelAdjustment != 0.0;
  
  @override
  String toString() {
    return 'FareCalculation(total: $formattedTotal, distance: $formattedDistance)';
  }
}