// ==================== driver_service.dart ====================
import 'api_client.dart';
import '../models/driver_available_ride.dart';
import '../models/driver_active_ride.dart';

class DriverService {
  final ApiClient _apiClient = ApiClient.instance;

  /// Check if current user is a driver and their status
  Future<ApiResponse<Map<String, dynamic>>> getDriverStatus() async {
    return await _apiClient.get<Map<String, dynamic>>(
      '/drivers/status/',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Apply to become a driver
  /// Returns driver profile with pending status
  Future<ApiResponse<Map<String, dynamic>>> applyToBeDriver({
    required String vehicleType,
    required String vehicleColor,
    required String licensePlate,
    required String driverLicenseNumber,
    required String driverLicenseExpiry, // Format: YYYY-MM-DD
    int? vehicleYear,
  }) async {
    return await _apiClient.post<Map<String, dynamic>>(
      '/drivers/apply/',
      {
        'vehicle_type': vehicleType,
        'vehicle_color': vehicleColor,
        'license_plate': licensePlate,
        'driver_license_number': driverLicenseNumber,
        'driver_license_expiry': driverLicenseExpiry,
        if (vehicleYear != null) 'vehicle_year': vehicleYear,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Get driver profile
  Future<ApiResponse<Map<String, dynamic>>> getDriverProfile() async {
    return await _apiClient.get<Map<String, dynamic>>(
      '/drivers/profile/',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Toggle driver availability (online/offline)
  /// action: 'online' | 'offline'
  Future<ApiResponse<Map<String, dynamic>>> toggleAvailability(
      String action) async {
    return await _apiClient.post<Map<String, dynamic>>(
      '/drivers/toggle-availability/',
      {'action': action},
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Fetch available ride requests for drivers
  Future<ApiResponse<List<DriverAvailableRide>>> getAvailableRides({
    required double latitude,
    required double longitude,
    double maxDistanceKm = 10,
  }) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/rides/available/',
      queryParams: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'max_distance': maxDistanceKm.toString(),
      },
      fromJson: (json) => json as List<dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      final list = response.data!
          .map((e) => DriverAvailableRide.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResponse.success(list);
    }
    return ApiResponse.error(response.error, statusCode: response.statusCode);
  }

  /// Accept a ride request
  Future<ApiResponse<Map<String, dynamic>>> acceptRide(String requestId) async {
    return await _apiClient.post<Map<String, dynamic>>(
      '/rides/requests/$requestId/accept/',
      {},
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Decline a ride request
  Future<ApiResponse<Map<String, dynamic>>> declineRide(
    String requestId, {
    String? reason,
  }) async {
    return await _apiClient.post<Map<String, dynamic>>(
      '/rides/requests/$requestId/decline/',
      {
        if (reason != null) 'reason': reason,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Get active rides for driver
  Future<ApiResponse<List<DriverActiveRide>>> getActiveRides() async {
    final response = await _apiClient.get<List<dynamic>>(
      '/rides/active/',
      fromJson: (json) => json as List<dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      final list = response.data!
          .map((e) => DriverActiveRide.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResponse.success(list);
    }
    return ApiResponse.error(response.error, statusCode: response.statusCode);
  }

  /// Start ride
  Future<ApiResponse<Map<String, dynamic>>> startRide(String rideId) async {
    return await _apiClient.post<Map<String, dynamic>>(
      '/rides/$rideId/start/',
      {},
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Complete ride
  Future<ApiResponse<Map<String, dynamic>>> completeRide(String rideId) async {
    return await _apiClient.post<Map<String, dynamic>>(
      '/rides/$rideId/complete/',
      {},
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Push driver location for active ride
  Future<ApiResponse<Map<String, dynamic>>> updateDriverLocation({
    required String rideId,
    required double latitude,
    required double longitude,
    double? speed,
    double? bearing,
  }) async {
    return await _apiClient.post<Map<String, dynamic>>(
      '/rides/$rideId/update-location/',
      {
        'latitude': latitude,
        'longitude': longitude,
        if (speed != null) 'speed_kmh': speed,
        if (bearing != null) 'bearing': bearing,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Upload driver verification document
  /// [documentType]: license, registration, insurance, vehicle_picture, driver_picture
  /// [filePath]: Local path to the document file
  Future<ApiResponse<Map<String, dynamic>>> uploadVerificationDocument({
    required String documentType,
    required String filePath,
  }) async {
    return await _apiClient.postMultipart<Map<String, dynamic>>(
      '/drivers/upload-document/',
      {
        'document_type': documentType,
      },
      {
        'document': filePath,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Upload vehicle image
  /// [imageType]: front, back, side, interior, registration
  /// [imagePath]: Local path to the image file
  Future<ApiResponse<Map<String, dynamic>>> uploadVehicleImage({
    required String imageType,
    required String imagePath,
  }) async {
    return await _apiClient.postMultipart<Map<String, dynamic>>(
      '/drivers/upload-vehicle-image/',
      {
        'image_type': imageType,
      },
      {
        'image': imagePath,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Get documents and verification status
  Future<ApiResponse<Map<String, dynamic>>> getDocumentsStatus() async {
    return await _apiClient.get<Map<String, dynamic>>(
      '/drivers/documents-status/',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }
}
