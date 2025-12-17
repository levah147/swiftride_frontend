
// ==================== 2. app_routes.dart - UPDATED ====================

import 'package:flutter/material.dart';
import '../splash_screen.dart';
import '../auth/auth_screen.dart';
import '../presentation/main_navigation_screen.dart';

import '../presentation/screens/ride_booking/destination_selection_screen.dart';
import '../presentation/screens/ride_booking/ride_options_screen.dart';
import '../presentation/screens/ride_booking/driver_matching_screen.dart';
import '../presentation/screens/ride_booking/ride_tracking_screen.dart';
import '../presentation/screens/ride_booking/ride_completion_screen.dart';
// Promotions imports
import '../presentation/screens/promotions/promotions_home_screen.dart';
import '../presentation/screens/promotions/referral_screen.dart';
import '../presentation/screens/promotions/loyalty_screen.dart';
import '../presentation/screens/promotions/promo_codes_list_screen.dart';
import '../presentation/screens/promotions/points_history_screen.dart';
// Support imports
import '../presentation/screens/support/support_home_screen.dart';
import '../presentation/screens/support/create_ticket_screen.dart';
import '../presentation/screens/support/my_tickets_screen.dart';
import '../presentation/screens/support/ticket_detail_screen.dart';
import '../presentation/screens/support/faq_screen.dart';

// Settings imports
import '../presentation/screens/settings/language_selector_screen.dart';

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
  
  // Promotions routes
  static const String promotions = '/promotions';
  static const String referral = '/promotions/referral';
  static const String loyalty = '/promotions/loyalty';
  static const String promosList = '/promotions/promos';
  static const String pointsHistory = '/promotions/loyalty/history'; 
  
  
  // Support routes
  static const String support = '/support';
  static const String createTicket = '/support/create-ticket';
  static const String myTickets = '/support/tickets';
  static const String ticketDetail = '/support/ticket-detail';
  static const String faq = '/support/faq';
  
  static const String language = '/settings/language';

  
  // Define all named routes
  static final Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    auth: (context) => const AuthScreen(),
    home: (context) => const MainNavigationScreen(),
    
    // Promotions screens
    promotions: (context) => const PromotionsHomeScreen(),
    referral: (context) => const ReferralScreen(),
    loyalty: (context) => const LoyaltyScreen(),
    promosList: (context) => const PromoCodesListScreen(),
    pointsHistory: (context) => const PointsHistoryScreen(),
    
    // Support screens (without arguments)
    support: (context) => const SupportHomeScreen(),
    myTickets: (context) => const MyTicketsScreen(),
    faq: (context) => const FAQScreen(),
    
    // Settings screens
    language: (context) => const LanguageSelectorScreen(),
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
        // ✅ FIXED: Handle RideOptionsArguments with all required fields
        if (args is RideOptionsArguments) {
          return MaterialPageRoute(
            builder: (context) => RideOptionsScreen(
              from: args.from,
              to: args.to,
              isScheduled: args.isScheduled,
              pickupLatLng: args.pickupLatLng,           // ✅ NOW INCLUDED
              destinationLatLng: args.destinationLatLng, // ✅ NOW INCLUDED
              pickupAddress: args.pickupAddress,         // ✅ NOW INCLUDED
              destinationAddress: args.destinationAddress, // ✅ NOW INCLUDED
              city: args.city,
            ),
            settings: settings,
          );
        }
        break;

      case driverMatching:
        if (args is DriverMatchingArguments) {
          return MaterialPageRoute(
            builder: (context) => DriverMatchingScreen(
              rideId: args.rideId,
              from: args.from,
            ),
            settings: settings,
          );
        }
        break;

      case rideTracking:
        if (args is RideTrackingArguments) {
          return MaterialPageRoute(
            builder: (context) => RideTrackingScreen(
              rideId: args.rideId,
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

      // Support routes with arguments
      case createTicket:
        final category = args != null && args is Map<String, dynamic>
            ? args['category'] as int?
            : null;
        return MaterialPageRoute(
          builder: (context) => CreateTicketScreen(
          initialCategory: args as Map<String, dynamic>?,
          ),
          settings: settings,
        );

      case ticketDetail:
        if (args is Map<String, dynamic> && args.containsKey('ticketId')) {
          return MaterialPageRoute(
            builder: (context) => TicketDetailScreen(
              ticketId: args['ticketId'] as int,
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