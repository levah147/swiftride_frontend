// ==================== ride_service.dart ====================
// Production-ready Ride Service for Django Backend
// Matches SwiftRide Django /api/rides/ endpoints

import '../models/ride.dart';
import 'api_client.dart';
import 'package:flutter/foundation.dart';

class RideService {
  final ApiClient _apiClient = ApiClient.instance;

  // ============================================
  // RIDE BOOKING
  // ============================================
  
  /// Book a new ride
  /// Django endpoint: POST /api/rides/
  /// Requires fare_hash from calculate-fare endpoint
  Future<ApiResponse<Ride>> bookRide({
    required String vehicleType,
    required String pickupLocation,
    required double pickupLatitude,
    required double pickupLongitude,
    required String destinationLocation,
    required double destinationLatitude,
    required double destinationLongitude,
    required String fareHash,
    String? cityName,
    DateTime? scheduledTime,
  }) async {
    try {
      debugPrint('🚕 Booking ride...');
      debugPrint('   Type: $vehicleType');
      debugPrint('   From: $pickupLocation');
      debugPrint('   To: $destinationLocation');
      
      final data = {
        'vehicle_type': vehicleType,
        'pickup_location': pickupLocation,
        'pickup_latitude': pickupLatitude,
        'pickup_longitude': pickupLongitude,
        'destination_location': destinationLocation,
        'destination_latitude': destinationLatitude,
        'destination_longitude': destinationLongitude,
        'fare_hash': fareHash,
        'ride_type': scheduledTime != null ? 'scheduled' : 'immediate',
        if (cityName != null) 'city_name': cityName,
        if (scheduledTime != null) 
          'scheduled_time': scheduledTime.toIso8601String(),
      };

      final response = await _apiClient.post<Ride>(
        '/rides/',
        data,
        fromJson: (json) => Ride.fromJson(json),
      );

      if (response.isSuccess) {
        debugPrint('✅ Ride booked successfully: #${response.data?.id}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Book Ride Error: $e');
      return ApiResponse.error('Failed to book ride: ${e.toString()}');
    }
  }

  // ============================================
  // RIDE HISTORY & DETAILS
  // ============================================
  
  /// Get ride history (paginated)
  /// Django endpoint: GET /api/rides/
  /// Query params: ?status=completed&page=1
  Future<ApiResponse<RideListResponse>> getRideHistory({
    String? status, // 'pending', 'completed', 'cancelled'
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      debugPrint('📋 Fetching ride history (page: $page, status: $status)');
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (status != null) 'status': status,
      };

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/rides/',
        queryParams: queryParams,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final rideListResponse = RideListResponse.fromJson(response.data!);
        debugPrint('✅ Fetched ${rideListResponse.rides.length} rides');
        return ApiResponse.success(rideListResponse);
      }

      return ApiResponse.error(
        response.error ?? 'Failed to fetch rides',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('❌ Get Ride History Error: $e');
      return ApiResponse.error('Failed to load rides: ${e.toString()}');
    }
  }

  /// Get details of a specific ride
  /// Django endpoint: GET /api/rides/{id}/
  Future<ApiResponse<Ride>> getRideDetails(String rideId) async {
    try {
      debugPrint('🔍 Fetching ride details: #$rideId');
      
      return await _apiClient.get<Ride>(
        '/rides/$rideId/',
        fromJson: (json) => Ride.fromJson(json),
      );
    } catch (e) {
      debugPrint('❌ Get Ride Details Error: $e');
      return ApiResponse.error('Failed to load ride: ${e.toString()}');
    }
  }

  /// Get active (ongoing) rides
  /// Django endpoint: GET /api/rides/active/
  Future<ApiResponse<List<Ride>>> getActiveRides() async {
    try {
      debugPrint('🚗 Fetching active rides...');
      
      return await _apiClient.get<List<Ride>>(
        '/rides/active/',
        fromJson: (json) {
          if (json is List) {
            return json.map((item) => Ride.fromJson(item)).toList();
          }
          return [];
        },
      );
    } catch (e) {
      debugPrint('❌ Get Active Rides Error: $e');
      return ApiResponse.error('Failed to load active rides: ${e.toString()}');
    }
  }

  // ============================================
  // RIDE ACTIONS
  // ============================================
  
  /// Cancel a ride
  /// Django endpoint: POST /api/rides/{id}/cancel/
  Future<ApiResponse<Ride>> cancelRide(
    String rideId, {
    String? reason,
  }) async {
    try {
      debugPrint('❌ Cancelling ride: #$rideId');
      
      final data = <String, dynamic>{};
      if (reason != null) data['cancellation_reason'] = reason;

      return await _apiClient.post<Ride>(
        '/rides/$rideId/cancel/',
        data,
        fromJson: (json) => Ride.fromJson(json),
      );
    } catch (e) {
      debugPrint('❌ Cancel Ride Error: $e');
      return ApiResponse.error('Failed to cancel ride: ${e.toString()}');
    }
  }

  /// Update ride status (usually called by driver)
  /// Django endpoint: PATCH /api/rides/{id}/
  Future<ApiResponse<Ride>> updateRideStatus(
    String rideId,
    String status, // 'accepted', 'arriving', 'in_progress', 'completed'
  ) async {
    try {
      debugPrint('🔄 Updating ride status: #$rideId -> $status');
      
      return await _apiClient.patch<Ride>(
        '/rides/$rideId/',
        {'status': status},
        fromJson: (json) => Ride.fromJson(json),
      );
    } catch (e) {
      debugPrint('❌ Update Ride Status Error: $e');
      return ApiResponse.error('Failed to update ride: ${e.toString()}');
    }
  }

  // ============================================
  // RATINGS & FEEDBACK
  // ============================================
  
  /// Rate a completed ride
  /// Django endpoint: POST /api/rides/{id}/rate/
  Future<ApiResponse<Map<String, dynamic>>> rateRide(
    String rideId, {
    required int rating, // 1-5
    String? feedback,
  }) async {
    try {
      debugPrint('⭐ Rating ride: #$rideId with $rating stars');
      
      final data = {
        'rider_rating': rating,
        if (feedback != null) 'rider_comment': feedback,
      };

      return await _apiClient.post<Map<String, dynamic>>(
        '/rides/$rideId/rate/',
        data,
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Rate Ride Error: $e');
      return ApiResponse.error('Failed to rate ride: ${e.toString()}');
    }
  }

  /// Get rating for a ride
  /// Django endpoint: GET /api/rides/{id}/rating/
  Future<ApiResponse<Map<String, dynamic>>> getRideRating(String rideId) async {
    try {
      return await _apiClient.get<Map<String, dynamic>>(
        '/rides/$rideId/rating/',
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Get Ride Rating Error: $e');
      return ApiResponse.error('Failed to load rating: ${e.toString()}');
    }
  }

  // ============================================
  // DRIVER TRACKING
  // ============================================
  
  /// Get driver's current location for active ride
  /// Django endpoint: GET /api/rides/{id}/driver-location/
  Future<ApiResponse<Map<String, dynamic>>> getDriverLocation(String rideId) async {
    try {
      return await _apiClient.get<Map<String, dynamic>>(
        '/rides/$rideId/driver-location/',
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Get Driver Location Error: $e');
      return ApiResponse.error('Failed to get driver location: ${e.toString()}');
    }
  }

  // ============================================
  // RIDE RECEIPT
  // ============================================
  
  /// Get ride receipt/summary
  /// Django endpoint: GET /api/rides/{id}/receipt/
  Future<ApiResponse<Map<String, dynamic>>> getRideReceipt(String rideId) async {
    try {
      debugPrint('🧾 Fetching receipt for ride: #$rideId');
      
      return await _apiClient.get<Map<String, dynamic>>(
        '/rides/$rideId/receipt/',
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Get Receipt Error: $e');
      return ApiResponse.error('Failed to load receipt: ${e.toString()}');
    }
  }
}

// ============================================
// RIDE LIST RESPONSE MODEL (for pagination)
// ============================================

class RideListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<Ride> rides;

  RideListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.rides,
  });

  factory RideListResponse.fromJson(Map<String, dynamic> json) {
    // Handle paginated response format
    if (json.containsKey('results')) {
      return RideListResponse(
        count: json['count'] ?? 0,
        next: json['next'],
        previous: json['previous'],
        rides: (json['results'] as List)
            .map((item) => Ride.fromJson(item))
            .toList(),
      );
    }
    
    // Handle simple list format
    return RideListResponse(
      count: (json as List).length,
      next: null,
      previous: null,
      rides: (json as List).map((item) => Ride.fromJson(item)).toList(),
    );
  }

  bool get hasMore => next != null;
  bool get hasPrevious => previous != null;
  
  @override
  String toString() {
    return 'RideListResponse(count: $count, rides: ${rides.length})';
  }
}