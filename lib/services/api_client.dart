import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:swiftride/config/api_config.dart'; // Update with your app name

class ApiClient {
  // Use dynamic URL from ApiConfig
  static String get baseUrl => ApiConfig.baseUrl;

  static ApiClient? _instance;

  ApiClient._internal() {
    // Print configuration on initialization
    ApiConfig.printConfig();
  }

  static ApiClient get instance {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  // ============================================
  // TOKEN MANAGEMENT
  // ============================================

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    debugPrint('✅ Tokens saved successfully');
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    debugPrint('🗑️ Tokens cleared');
  }

  /// Expose access token for services that need to build authenticated URLs (e.g., WebSockets).
  Future<String?> getAccessToken() => _getAccessToken();

  // ============================================
  // HEADERS
  // ============================================

  Map<String, String> _getHeaders({bool requiresAuth = false}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, String>> _getMultipartAuthHeaders() async {
    final token = await _getAccessToken();
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ============================================
  // HTTP CLIENT WITH REDIRECT SUPPORT
  // ============================================

  /// Create HTTP client that follows redirects
  http.Client _createClient() {
    return http.Client();
  }

  // ============================================
  // HTTP METHODS
  // ============================================

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
    Map<String, String>? queryParams,
  }) async {
    final client = _createClient();
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final headers = requiresAuth ? await _getAuthHeaders() : _getHeaders();

      debugPrint('📡 GET: $uri');

      final response = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      debugPrint('❌ GET Error: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    } finally {
      client.close();
    }
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint,
    Map<String, dynamic> data, {
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    final client = _createClient();
    try {
      final headers = requiresAuth ? await _getAuthHeaders() : _getHeaders();

      final uri = Uri.parse('$baseUrl$endpoint');
      debugPrint('📡 POST: $uri');
      debugPrint('📤 Data: ${jsonEncode(data)}');

      final response = await client
          .post(
            uri,
            headers: headers,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      debugPrint('❌ POST Error: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    } finally {
      client.close();
    }
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint,
    Map<String, dynamic> data, {
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    final client = _createClient();
    try {
      final headers = requiresAuth ? await _getAuthHeaders() : _getHeaders();

      final uri = Uri.parse('$baseUrl$endpoint');
      debugPrint('📡 PUT: $uri');

      final response = await client
          .put(
            uri,
            headers: headers,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      debugPrint('❌ PUT Error: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    } finally {
      client.close();
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String endpoint,
    Map<String, dynamic> data, {
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    final client = _createClient();
    try {
      final headers = requiresAuth ? await _getAuthHeaders() : _getHeaders();

      final uri = Uri.parse('$baseUrl$endpoint');
      debugPrint('📡 PATCH: $uri');

      final response = await client
          .patch(
            uri,
            headers: headers,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      debugPrint('❌ PATCH Error: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    } finally {
      client.close();
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    final client = _createClient();
    try {
      final headers = requiresAuth ? await _getAuthHeaders() : _getHeaders();

      final uri = Uri.parse('$baseUrl$endpoint');
      debugPrint('📡 DELETE: $uri');

      final response = await client
          .delete(
            uri,
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      debugPrint('❌ DELETE Error: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    } finally {
      client.close();
    }
  }

  // ============================================
  // MULTIPART REQUESTS (For file uploads)
  // ============================================

  Future<ApiResponse<T>> postMultipart<T>(
    String endpoint,
    Map<String, String> fields,
    Map<String, String> files, {
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final headers = await _getMultipartAuthHeaders();
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(headers);

      request.fields.addAll(fields);

      for (final entry in files.entries) {
        final file = await http.MultipartFile.fromPath(entry.key, entry.value);
        request.files.add(file);
      }

      debugPrint('📡 POST Multipart: $uri');

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      debugPrint('❌ Multipart Error: $e');
      return ApiResponse.error('Upload error: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> patchMultipart<T>(
    String endpoint,
    Map<String, String> fields,
    Map<String, String> files, {
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final headers = await _getMultipartAuthHeaders();
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('PATCH', uri)
        ..headers.addAll(headers);

      request.fields.addAll(fields);

      for (final entry in files.entries) {
        final file = await http.MultipartFile.fromPath(entry.key, entry.value);
        request.files.add(file);
      }

      debugPrint('📡 PATCH Multipart: $uri');

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      debugPrint('❌ Multipart Update Error: $e');
      return ApiResponse.error('Update error: ${e.toString()}');
    }
  }

  // ============================================
  // RESPONSE HANDLING (Django DRF Optimized)
  // ============================================

  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
  ) {
    try {
      debugPrint('📥 Status: ${response.statusCode}');
      debugPrint('📥 Body: ${response.body}');

      // Handle redirects (301, 302, 307, 308)
      if (response.statusCode >= 301 && response.statusCode <= 308) {
        final location = response.headers['location'];
        return ApiResponse.error(
          'Server redirect detected (${response.statusCode}). '
          'Check URL structure. ${location != null ? "Redirecting to: $location" : ""}',
          statusCode: response.statusCode,
        );
      }

      // Handle empty responses
      if (response.body.isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return ApiResponse.success(null as T);
        }
        return ApiResponse.error(
          'Empty response from server (Status: ${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      final data = jsonDecode(response.body);

      // Success responses (200-299)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Extract and save tokens if present (for login/verify-otp)
        _extractAndSaveTokens(data);

        if (fromJson != null) {
          return ApiResponse.success(fromJson(data),
              statusCode: response.statusCode);
        }
        return ApiResponse.success(data as T, statusCode: response.statusCode);
      }

      // Error responses
      final errorMessage = _extractErrorMessage(data);
      return ApiResponse.error(
        errorMessage,
        statusCode: response.statusCode,
        errorData: data,
      );
    } catch (e) {
      debugPrint('❌ Response Parse Error: $e');
      return ApiResponse.error('Failed to parse response: ${e.toString()}');
    }
  }

  // ============================================
  // DJANGO DRF ERROR EXTRACTION
  // ============================================

  String _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      // Django REST Framework common error fields
      if (data.containsKey('error')) {
        return _extractNestedError(data['error']);
      }
      if (data.containsKey('message')) {
        return _extractNestedError(data['message']);
      }
      if (data.containsKey('detail')) {
        return _extractNestedError(data['detail']);
      }

      // Handle field-specific errors (e.g., {"phone_number": ["Invalid format"]})
      if (data.isNotEmpty) {
        final firstKey = data.keys.first;
        final firstError = data[firstKey];

        if (firstError is List && firstError.isNotEmpty) {
          return '${_formatFieldName(firstKey)}: ${firstError.first}';
        }
        if (firstError is String) {
          return '$firstKey: $firstError';
        }
        return firstError.toString();
      }
    }

    if (data is String) {
      return data;
    }

    return 'Unknown error occurred';
  }

  String _extractNestedError(dynamic error) {
    if (error is String) return error;
    if (error is List && error.isNotEmpty) return error.first.toString();
    if (error is Map) return _extractErrorMessage(error);
    return error.toString();
  }

  String _formatFieldName(String fieldName) {
    return fieldName.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  // ============================================
  // TOKEN EXTRACTION (Django JWT Format)
  // ============================================

  Future<void> _extractAndSaveTokens(dynamic data) async {
    try {
      if (data is! Map<String, dynamic>) return;

      // Django JWT format: { "tokens": { "access": "...", "refresh": "..." } }
      if (data.containsKey('tokens')) {
        final tokens = data['tokens'];
        if (tokens is Map<String, dynamic>) {
          final access = tokens['access']?.toString();
          final refresh = tokens['refresh']?.toString();

          if (access != null && refresh != null) {
            await saveTokens(access, refresh);
            debugPrint('✅ Tokens extracted and saved');
            return;
          }
        }
      }

      // Alternative format: { "access": "...", "refresh": "..." }
      if (data.containsKey('access') && data.containsKey('refresh')) {
        await saveTokens(
          data['access'].toString(),
          data['refresh'].toString(),
        );
        debugPrint('✅ Tokens extracted and saved');
      }
    } catch (e) {
      debugPrint('⚠️ Token extraction error: $e');
    }
  }

  // ============================================
  // TOKEN REFRESH
  // ============================================

  Future<bool> refreshAccessToken() async {
    final client = _createClient();
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) {
        debugPrint('❌ No refresh token available');
        return false;
      }

      debugPrint('🔄 Refreshing access token...');

      final uri = Uri.parse('$baseUrl/auth/token/refresh/');
      final response = await client.post(
        uri,
        headers: _getHeaders(),
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('access')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', data['access']);
          debugPrint('✅ Access token refreshed');
          return true;
        }
      }

      debugPrint('❌ Token refresh failed: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ Token refresh error: $e');
      return false;
    } finally {
      client.close();
    }
  }

  // ============================================
  // HELPER METHOD - Check if logged in
  // ============================================

  Future<bool> isLoggedIn() async {
    final token = await _getAccessToken();
    return token != null && token.isNotEmpty;
  }
}

// ============================================
// API RESPONSE CLASS
// ============================================

class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;
  final int? statusCode;
  final dynamic errorData;

  ApiResponse.success(this.data, {this.statusCode})
      : error = null,
        errorData = null,
        isSuccess = true;

  ApiResponse.error(this.error, {this.statusCode, this.errorData})
      : data = null,
        isSuccess = false;

  // HTTP Status helpers
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidationError => statusCode == 400;
  bool get isServerError => statusCode != null && statusCode! >= 500;
  bool get isRedirect =>
      statusCode != null && statusCode! >= 301 && statusCode! <= 308;

  // Get formatted error message
  String get errorMessage => error ?? 'Unknown error occurred';

  @override
  String toString() {
    if (isSuccess) {
      return 'ApiResponse.success(data: $data, statusCode: $statusCode)';
    } else {
      return 'ApiResponse.error(error: $error, statusCode: $statusCode)';
    }
  }
}
