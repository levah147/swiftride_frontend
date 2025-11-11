import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/main/main_navigation_screen.dart';
import '../screens/rides_booking/destination_selection_screen.dart';
import '../screens/rides_booking/ride_options_screen.dart';
import '../screens/rides_booking/driver_matching_screen.dart';
import '../screens/rides_booking/ride_tracking_screen.dart';
import '../screens/rides_booking/ride_completion_screen.dart';
import 'route_arguments.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String rides = '/rides';
  static const String account = '/account';
  static const String destinationSelection = '/destination-selection';
  static const String rideOptions = '/ride-options';
  static const String driverMatching = '/driver-matching';
  static const String rideTracking = '/ride-tracking';
  static const String rideCompletion = '/ride-completion';

  // Define all named routes
  static final Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    auth: (context) => const AuthScreen(),
    home: (context) => const MainNavigationScreen(),
  };

  // Handle routes with arguments
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case destinationSelection:
        return MaterialPageRoute(
          builder: (context) => const DestinationSelectionScreen(),
          settings: settings,
        );

      case rideOptions:
        if (args is RideOptionsArguments) {
          return MaterialPageRoute(
            builder: (context) => RideOptionsScreen(
              from: args.from,
              to: args.to,
              isScheduled: args.isScheduled,
            ),
            settings: settings,
          );
        }
        break;

      case driverMatching:
        if (args is DriverMatchingArguments) {
          return MaterialPageRoute(
            builder: (context) => DriverMatchingScreen(
              from: args.from,
              to: args.to,
              rideType: args.rideType,
              isScheduled: args.isScheduled,
            ),
            settings: settings,
          );
        }
        break;

      case rideTracking:
        if (args is RideTrackingArguments) {
          return MaterialPageRoute(
            builder: (context) => RideTrackingScreen(
              from: args.from,
              to: args.to,
              rideType: args.rideType,
              driver: args.driver,
            ),
            settings: settings,
          );
        }
        break;

      case rideCompletion:
        if (args is RideCompletionArguments) {
          return MaterialPageRoute(
            builder: (context) => RideCompletionScreen(
              from: args.from,
              to: args.to,
              rideType: args.rideType,
              driver: args.driver,
              duration: args.duration,
              distance: args.distance,
            ),
            settings: settings,
          );
        }
        break;
    }

    return null;
  }

  // Handle unknown routes
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Error', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                'Route not found: ${settings.name}',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.home,
                  (route) => false,
                ),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}