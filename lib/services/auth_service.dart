// ==================== auth_service.dart ====================
// Production-ready Auth Service for Django Backend
// Matches SwiftRide Django API exactly

import '../models/user.dart';
import 'api_client.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient.instance;

  // ============================================
  // AUTHENTICATION FLOW
  // ============================================
  
  /// Step 1: Send OTP to phone number
  /// Django endpoint: POST /api/auth/send-otp/
  /// Returns: { "message": "OTP sent successfully", "expires_at": "..." }
  Future<ApiResponse<Map<String, dynamic>>> sendOtp(String phoneNumber) async {
    try {
      debugPrint('📱 Sending OTP to: $phoneNumber');
      
      return await _apiClient.post<Map<String, dynamic>>(
        '/auth/send-otp/',
        {'phone_number': phoneNumber},
        requiresAuth: false,
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Send OTP Error: $e');
      return ApiResponse.error('Failed to send OTP: ${e.toString()}');
    }
  }

  /// Step 2: Verify OTP and login user
  /// Django endpoint: POST /api/auth/verify-otp/
  /// Returns: { "user": {...}, "tokens": { "access": "...", "refresh": "..." } }
  Future<ApiResponse<AuthResponse>> verifyOtp(
    String phoneNumber,
    String otp,
  ) async {
    try {
      debugPrint('🔐 Verifying OTP for: $phoneNumber');
      
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/auth/verify-otp/',
        {
          'phone_number': phoneNumber,
          'otp': otp,
        },
        requiresAuth: false,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        // Parse user and tokens
        final user = User.fromJson(response.data!['user'] ?? response.data!);
        final tokens = response.data!['tokens'] as Map<String, dynamic>?;
        
        final authResponse = AuthResponse(
          user: user,
          accessToken: tokens?['access'],
          refreshToken: tokens?['refresh'],
        );
        
        debugPrint('✅ OTP verified successfully');
        return ApiResponse.success(authResponse);
      }

      return ApiResponse.error(
        response.error ?? 'Failed to verify OTP',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('❌ Verify OTP Error: $e');
      return ApiResponse.error('Failed to verify OTP: ${e.toString()}');
    }
  }

  // ============================================
  // PROFILE MANAGEMENT
  // ============================================
  
  /// Get current logged-in user profile
  /// Django endpoint: GET /api/auth/profile/
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      debugPrint('👤 Fetching current user profile...');
      
      return await _apiClient.get<User>(
        '/auth/profile/',
        fromJson: (json) => User.fromJson(json),
      );
    } catch (e) {
      debugPrint('❌ Get User Error: $e');
      return ApiResponse.error('Failed to fetch profile: ${e.toString()}');
    }
  }

  /// Update user profile with text fields only
  /// Django endpoint: PATCH /api/auth/profile/update/
  /// NOTE: Uses multipart/form-data because Django view is configured for it
  Future<ApiResponse<User>> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    try {
      final fields = <String, String>{};
      if (firstName != null) fields['first_name'] = firstName;
      if (lastName != null) fields['last_name'] = lastName;
      if (email != null) fields['email'] = email;

      debugPrint('📝 Updating profile: $fields');

      return await _apiClient.patchMultipart<User>(
        '/auth/profile/update/',
        fields,
        {}, // Empty files map
        fromJson: (json) => User.fromJson(json),
      );
    } catch (e) {
      debugPrint('❌ Update Profile Error: $e');
      return ApiResponse.error('Failed to update profile: ${e.toString()}');
    }
  }

  /// Update user profile picture
  /// Django endpoint: PATCH /api/auth/profile/update/
  /// [imagePath] - Local file path to the image
  Future<ApiResponse<User>> updateProfilePicture(String imagePath) async {
    try {
      debugPrint('📸 Uploading profile picture: $imagePath');
      
      return await _apiClient.patchMultipart<User>(
        '/auth/profile/update/',
        {}, // No text fields
        {'profile_picture': imagePath},
        fromJson: (json) => User.fromJson(json),
      );
    } catch (e) {
      debugPrint('❌ Upload Picture Error: $e');
      return ApiResponse.error('Failed to upload picture: ${e.toString()}');
    }
  }

  /// Update profile with both text fields and profile picture
  Future<ApiResponse<User>> updateProfileWithPicture({
    String? firstName,
    String? lastName,
    String? email,
    String? imagePath,
  }) async {
    try {
      final fields = <String, String>{};
      if (firstName != null) fields['first_name'] = firstName;
      if (lastName != null) fields['last_name'] = lastName;
      if (email != null) fields['email'] = email;

      final files = <String, String>{};
      if (imagePath != null) files['profile_picture'] = imagePath;

      debugPrint('📝 Updating profile with picture');

      return await _apiClient.patchMultipart<User>(
        '/auth/profile/update/',
        fields,
        files,
        fromJson: (json) => User.fromJson(json),
      );
    } catch (e) {
      debugPrint('❌ Update with Picture Error: $e');
      return ApiResponse.error('Failed to update: ${e.toString()}');
    }
  }

  // ============================================
  // SESSION MANAGEMENT
  // ============================================
  
  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _apiClient.isLoggedIn();
  }

  /// Logout user - calls backend and clears local tokens
  /// Django endpoint: POST /api/auth/logout/
  Future<ApiResponse<void>> logout() async {
    try {
      debugPrint('🚪 Logging out...');
      
      // Call backend logout endpoint
      try {
        await _apiClient.post<Map<String, dynamic>>(
          '/auth/logout/',
          {},
          fromJson: (json) => json as Map<String, dynamic>,
        );
      } catch (e) {
        debugPrint('⚠️ Backend logout call failed (continuing with local logout): $e');
      }
      
      // Clear local tokens
      await _apiClient.clearTokens();
      debugPrint('✅ Logged out successfully');
      
      return ApiResponse.success(null);
    } catch (e) {
      debugPrint('❌ Logout Error: $e');
      return ApiResponse.error('Failed to logout: ${e.toString()}');
    }
  }

  /// Delete user account permanently
  /// Django endpoint: DELETE /api/auth/delete-account/
  Future<ApiResponse<void>> deleteAccount() async {
    try {
      debugPrint('🗑️ Deleting account...');
      
      final response = await _apiClient.delete<Map<String, dynamic>>(
        '/auth/delete-account/',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess) {
        // Clear tokens after successful deletion
        await logout();
        return ApiResponse.success(null);
      }

      return ApiResponse.error(
        response.error ?? 'Failed to delete account',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('❌ Delete Account Error: $e');
      return ApiResponse.error('Failed to delete account: ${e.toString()}');
    }
  }

  // ============================================
  // TOKEN REFRESH
  // ============================================
  
  /// Refresh access token using refresh token
  Future<bool> refreshToken() async {
    return await _apiClient.refreshAccessToken();
  }
}

// ============================================
// AUTH RESPONSE MODEL
// ============================================

class AuthResponse {
  final User user;
  final String? accessToken;
  final String? refreshToken;

  AuthResponse({
    required this.user,
    this.accessToken,
    this.refreshToken,
  });

  bool get hasTokens => accessToken != null && refreshToken != null;

  @override
  String toString() {
    return 'AuthResponse(user: ${user.fullName}, hasTokens: $hasTokens)';
  }
}