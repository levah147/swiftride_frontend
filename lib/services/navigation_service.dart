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

  // Ride booking flow
  void goToRideOptions({
    required String from,
    required String to,
    required bool isScheduled,
  }) {
    _navigator?.pushNamed(
      AppRoutes.rideOptions,
      arguments: RideOptionsArguments(
        from: from,
        to: to,
        isScheduled: isScheduled,
      ),
    );
  }

  // ✅ FIXED: Updated to match DriverMatchingArguments signature
  void goToDriverMatching({
    required String rideId,           // ✅ ADDED
    required LatLng from,             // ✅ CHANGED: String → LatLng
    required String to,               // Keep as String
    required Map<String, dynamic> rideType,
    required bool isScheduled,
  }) {
    _navigator?.pushNamed(
      AppRoutes.driverMatching,
      arguments: DriverMatchingArguments(
        rideId: rideId,               // ✅ ADDED
        from: from,                   // ✅ Now LatLng type
        to: to,
        rideType: rideType,
        isScheduled: isScheduled,
      ),
    );
  }

  // ✅ FIXED: Updated to match RideTrackingArguments signature
  void goToRideTracking({
    required String rideId,           // ✅ ADDED
    required String from,
    required String to,
    required Map<String, dynamic> rideType,
    required Map<String, dynamic> driver,
  }) {
    _navigator?.pushReplacementNamed(
      AppRoutes.rideTracking,
      arguments: RideTrackingArguments(
        rideId: rideId,               // ✅ ADDED
        from: from,
        to: to,
        rideType: rideType,
        driver: driver,
      ),
    );
  }

  // ✅ FIXED: Updated to match RideCompletionArguments signature
  void goToRideCompletion({
    required String rideId,           // ✅ ADDED
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
        rideId: rideId,               // ✅ ADDED
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
}