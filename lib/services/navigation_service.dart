// ==================== services/navigation_service.dart ====================
// NAVIGATION SERVICE - Fixed to support real location data

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../routes/app_routes.dart';
import '../routes/route_arguments.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();

  factory NavigationService() {
    return _instance;
  }

  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState? get _navigator => navigatorKey.currentState;

  // Basic navigation
  void goToHome() {
    _navigator?.pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  void goToAuth() {
    _navigator?.pushNamedAndRemoveUntil(
      AppRoutes.auth,
      (route) => false,
    );
  }

  void goToDestinationSelection() {
    _navigator?.pushNamed(AppRoutes.destinationSelection);
  }

  // ✅ FIXED: Updated to include coordinates
  void goToRideOptions({
    required String from,
    required String to,
    required bool isScheduled,
    required LatLng pickupLatLng,           // ✅ ADDED
    required LatLng destinationLatLng,      // ✅ ADDED
    required String pickupAddress,          // ✅ ADDED
    required String destinationAddress,     // ✅ ADDED
    String? city,
  }) {
    _navigator?.pushNamed(
      AppRoutes.rideOptions,
      arguments: RideOptionsArguments(
        from: from,
        to: to,
        isScheduled: isScheduled,
        pickupLatLng: pickupLatLng,         // ✅ ADDED
        destinationLatLng: destinationLatLng, // ✅ ADDED
        pickupAddress: pickupAddress,       // ✅ ADDED
        destinationAddress: destinationAddress, // ✅ ADDED
        city: city,
      ),
    );
  }

  // ✅ CORRECT: Already matches DriverMatchingArguments
  void goToDriverMatching({
    required String rideId,
    required LatLng from,
    required String to,
    required Map<String, dynamic> rideType,
    required bool isScheduled,
  }) {
    _navigator?.pushNamed(
      AppRoutes.driverMatching,
      arguments: DriverMatchingArguments(
        rideId: rideId,
        from: from,
        to: to,
        rideType: rideType,
        isScheduled: isScheduled,
      ),
    );
  }

  // ✅ CORRECT: Already matches RideTrackingArguments
  void goToRideTracking({
    required String rideId,
    required String from,
    required String to,
    required Map<String, dynamic> rideType,
    required Map<String, dynamic> driver,
  }) {
    _navigator?.pushReplacementNamed(
      AppRoutes.rideTracking,
      arguments: RideTrackingArguments(
        rideId: rideId,
        from: from,
        to: to,
        rideType: rideType,
        driver: driver,
      ),
    );
  }

  // ✅ CORRECT: Already matches RideCompletionArguments
  void goToRideCompletion({
    required String rideId,
    required String from,
    required String to,
    required Map<String, dynamic> rideType,
    required Map<String, dynamic> driver,
    required String duration,
    required String distance,
  }) {
    _navigator?.pushReplacementNamed(
      AppRoutes.rideCompletion,
      arguments: RideCompletionArguments(
        rideId: rideId,
        from: from,
        to: to,
        rideType: rideType,
        driver: driver,
        duration: duration,
        distance: distance,
      ),
    );
  }

  // Generic navigation
  void push(String routeName, {Object? arguments}) {
    _navigator?.pushNamed(routeName, arguments: arguments);
  }

  void pop({dynamic result}) {
    _navigator?.pop(result);
  }

  void popUntil(String routeName) {
    _navigator?.popUntil(ModalRoute.withName(routeName));
  }

  void popToRoot() {
    _navigator?.popUntil((route) => route.isFirst);
  }

  void pushReplacement(String routeName, {Object? arguments}) {
    _navigator?.pushReplacementNamed(routeName, arguments: arguments);
  }

  void pushAndRemoveUntil(String routeName, {Object? arguments}) {
    _navigator?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  // Check if can pop
  bool canPop() {
    return _navigator?.canPop() ?? false;
  }

  // ============================================
  // CONVENIENCE METHODS FOR COMMON PATTERNS
  // ============================================

  /// Navigate to ride options from any screen with full location data
  void navigateToRideOptionsWithLocations({
    required LatLng pickupLatLng,
    required LatLng destinationLatLng,
    required String pickupAddress,
    required String destinationAddress,
    bool isScheduled = false,
    String? city,
  }) {
    goToRideOptions(
      from: pickupAddress,
      to: destinationAddress,
      isScheduled: isScheduled,
      pickupLatLng: pickupLatLng,
      destinationLatLng: destinationLatLng,
      pickupAddress: pickupAddress,
      destinationAddress: destinationAddress,
      city: city,
    );
  }

  /// Show error dialog
  void showErrorDialog({
    required String title,
    required String message,
    VoidCallback? onDismiss,
  }) {
    final context = _navigator?.context;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss?.call();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show success snackbar
  void showSuccessSnackBar(String message) {
    final context = _navigator?.context;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error snackbar
  void showErrorSnackBar(String message) {
    final context = _navigator?.context;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}