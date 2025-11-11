// ==================== driver_service.dart ====================
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'api_client.dart';

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