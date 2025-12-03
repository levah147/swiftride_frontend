import 'package:flutter/foundation.dart';

/// API Configuration for SwiftRide
/// Manages environment-specific URLs for backend communication
class ApiConfig {
  // ============================================
  // 🔧 CONFIGURATION - Change these values
  // ============================================

  /// Set to false to use local development server
  /// Set to true to use production Render server
  static bool get useProduction => !kDebugMode; // Auto-detect

  /// Local development server URL (your computer's IP)
  static const String _localUrl = 'http://192.168.229.65:8000/api';

  /// Production server URL (Render deployment)
  static const String _productionUrl =
      'https://swiftride-1wnu.onrender.com/api';

  /// Local WebSocket URL
  static const String _localWsUrl = 'ws://192.168.229.65:8000/ws';

  /// Production WebSocket URL
  static const String _productionWsUrl = 'wss://swiftride-1wnu.onrender.com/ws';

  // ============================================
  // COMPUTED PROPERTIES
  // ============================================

  /// Get the appropriate base URL based on environment
  static String get baseUrl {
    if (kDebugMode && !useProduction) {
      debugPrint('🔧 Using LOCAL server: $_localUrl');
      return _localUrl;
    }
    debugPrint('🌐 Using PRODUCTION server: $_productionUrl');
    return _productionUrl;
  }

  /// Get the appropriate WebSocket URL based on environment
  static String get wsUrl {
    if (kDebugMode && !useProduction) {
      debugPrint('🔧 Using LOCAL WebSocket: $_localWsUrl');
      return _localWsUrl;
    }
    debugPrint('🌐 Using PRODUCTION WebSocket: $_productionWsUrl');
    return _productionWsUrl;
  }

  /// Get the base domain (without /api)
  static String get baseDomain {
    if (kDebugMode && !useProduction) {
      return 'http://192.168.229.65:8000';
    }
    return 'https://swiftride-1wnu.onrender.com';
  }

  /// Check if running in production mode
  static bool get isProduction => useProduction || kReleaseMode;

  /// Check if running in development mode
  static bool get isDevelopment => !isProduction;

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Get full endpoint URL
  static String endpoint(String path) {
    // Remove leading slash if present
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$baseUrl/$cleanPath';
  }

  /// Get WebSocket endpoint URL
  static String wsEndpoint(String path) {
    // Remove leading slash if present
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$wsUrl/$cleanPath';
  }

  /// Print current configuration
  static void printConfig() {
    debugPrint('=================================');
    debugPrint('SwiftRide API Configuration');
    debugPrint('=================================');
    debugPrint('Environment: ${isProduction ? "PRODUCTION" : "DEVELOPMENT"}');
    debugPrint('Base URL: $baseUrl');
    debugPrint('WebSocket URL: $wsUrl');
    debugPrint('Base Domain: $baseDomain');
    debugPrint('=================================');
  }
}
