// ==================== controllers/ride_booking_controller.dart ====================
// RIDE BOOKING CONTROLLER - Manages the entire ride booking flow
// From destination selection to ride completion

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../models/ride_request.dart';
import '../../../../models/ride.dart';
import '../../../../models/route_info.dart';
import '../../../../models/vehicle_type.dart';
import '../../../../services/ride_service.dart';
import '../../../../services/pricing_service.dart';
import '../../../../services/map_service.dart';
import '../../../../services/socket_service.dart';

enum BookingStage {
  selectingDestination,
  selectingVehicle,
  confirmingRide,
  searchingDriver,
  driverMatched,
  driverArriving,
  inProgress,
  completed,
  cancelled,
}

class RideBookingController extends ChangeNotifier {
  // Services
  final RideService _rideService = RideService();
  final PricingService _pricingService = PricingService();
  final MapService _mapService = MapService();
  final SocketService _socketService = SocketService();

  // Booking stage
  BookingStage _currentStage = BookingStage.selectingDestination;

  // Location data
  LatLng? _pickupLocation;
  String? _pickupAddress;
  LatLng? _destinationLocation;
  String? _destinationAddress;
  List<RideStop>? _stops;

  // Route data
  RouteInfo? _routeInfo;
  
  // Vehicle selection
  VehicleType? _selectedVehicle;
  List<VehicleType> _availableVehicles = [];
  
  // Pricing
  double? _estimatedFare;
  String? _fareHash;
  String? _promoCode;
  double? _discount;

  // Active ride
  Ride? _activeRide;
  DriverLocationUpdate? _driverLocation;
  
  // Payment
  String _paymentMethod = 'cash';
  
  // Loading states
  bool _isLoadingRoute = false;
  bool _isCalculatingFare = false;
  bool _isBookingRide = false;
  bool _isSearchingDriver = false;
  
  // Error
  String? _errorMessage;

  // Getters
  BookingStage get currentStage => _currentStage;
  LatLng? get pickupLocation => _pickupLocation;
  String? get pickupAddress => _pickupAddress;
  LatLng? get destinationLocation => _destinationLocation;
  String? get destinationAddress => _destinationAddress;
  List<RideStop>? get stops => _stops;
  RouteInfo? get routeInfo => _routeInfo;
  VehicleType? get selectedVehicle => _selectedVehicle;
  List<VehicleType> get availableVehicles => _availableVehicles;
  double? get estimatedFare => _estimatedFare;
  String? get fareHash => _fareHash;
  String? get promoCode => _promoCode;
  double? get discount => _discount;
  Ride? get activeRide => _activeRide;
  DriverLocationUpdate? get driverLocation => _driverLocation;
  String get paymentMethod => _paymentMethod;
  bool get isLoadingRoute => _isLoadingRoute;
  bool get isCalculatingFare => _isCalculatingFare;
  bool get isBookingRide => _isBookingRide;
  bool get isSearchingDriver => _isSearchingDriver;
  bool get isLoading => _isLoadingRoute || _isCalculatingFare || _isBookingRide;
  String? get errorMessage => _errorMessage;
  
  // Computed
  bool get canProceedToVehicleSelection => 
      _pickupLocation != null && _destinationLocation != null;
  bool get canConfirmBooking => 
      _selectedVehicle != null && _estimatedFare != null && _fareHash != null;

  // ============================================
  // DESTINATION SELECTION
  // ============================================

  /// Set pickup location
  void setPickupLocation(LatLng location, String address) {
    _pickupLocation = location;
    _pickupAddress = address;
    debugPrint('📍 Pickup set: $address');
    notifyListeners();
  }

  /// Set destination location
  Future<void> setDestinationLocation(LatLng location, String address) async {
    _destinationLocation = location;
    _destinationAddress = address;
    debugPrint('📍 Destination set: $address');
    notifyListeners();

    // Automatically calculate route
    if (_pickupLocation != null) {
      await calculateRoute();
    }
  }

  /// Add a stop
  void addStop(LatLng location, String address) {
    _stops ??= [];
    _stops!.add(RideStop(
      coordinates: location,
      address: address,
      order: _stops!.length + 1,
    ));
    debugPrint('➕ Stop added: $address');
    notifyListeners();
    
    // Recalculate route with stops
    calculateRoute();
  }

  /// Remove a stop
  void removeStop(int index) {
    if (_stops != null && index < _stops!.length) {
      _stops!.removeAt(index);
      debugPrint('➖ Stop removed');
      notifyListeners();
      calculateRoute();
    }
  }

  // ============================================
  // ROUTE CALCULATION
  // ============================================

  /// Calculate route between pickup and destination
  Future<void> calculateRoute() async {
    if (_pickupLocation == null || _destinationLocation == null) return;

    try {
      _isLoadingRoute = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('🗺️ Calculating route...');

      final waypoints = _stops?.map((s) => s.coordinates).toList();

      final route = await _mapService.getRoute(
        origin: _pickupLocation!,
        destination: _destinationLocation!,
        waypoints: waypoints,
        alternatives: true,
      );

      _routeInfo = route;
      debugPrint('✅ Route calculated: ${route.formattedDistance}, ${route.formattedDuration}');

      _isLoadingRoute = false;
      notifyListeners();

      // Move to vehicle selection
      _currentStage = BookingStage.selectingVehicle;
      notifyListeners();

    } catch (e) {
      debugPrint('❌ Route calculation error: $e');
      _errorMessage = 'Could not calculate route';
      _isLoadingRoute = false;
      notifyListeners();
    }
  }

  // ============================================
  // VEHICLE SELECTION
  // ============================================

  /// Load available vehicles
  Future<void> loadAvailableVehicles(String cityName) async {
    try {
      final response = await _pricingService.getVehicleTypes(cityName: cityName);
      
      if (response.isSuccess && response.data != null) {
        _availableVehicles = response.data!.where((v) => v.available).toList();
        debugPrint('✅ Loaded ${_availableVehicles.length} vehicles');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error loading vehicles: $e');
    }
  }

  /// Select vehicle and calculate fare
  Future<void> selectVehicle(VehicleType vehicle) async {
    _selectedVehicle = vehicle;
    debugPrint('🚗 Vehicle selected: ${vehicle.name}');
    notifyListeners();

    // Calculate fare
    await calculateFare();
  }

  // ============================================
  // FARE CALCULATION
  // ============================================

  /// Calculate fare for selected vehicle
  Future<void> calculateFare() async {
    if (_selectedVehicle == null || _routeInfo == null) return;

    try {
      _isCalculatingFare = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('💰 Calculating fare...');

      final response = await _pricingService.calculateFare(
        vehicleType: _selectedVehicle!.id,  // ✅ Correct parameter name
        pickupLatitude: _pickupLocation!.latitude,
        pickupLongitude: _pickupLocation!.longitude,
        destinationLatitude: _destinationLocation!.latitude,
        destinationLongitude: _destinationLocation!.longitude,
        cityName: null,  // TODO: Get from user location context
      );

      if (response.isSuccess && response.data != null) {
        final fareCalc = response.data!;
        _estimatedFare = fareCalc.totalFare;  // ✅ Use totalFare from FareCalculation
        _fareHash = fareCalc.fareHash;        // ✅ Use fareHash from FareCalculation
        // Note: FareCalculation doesn't have discount field, only surgeMultiplier
        
        debugPrint('✅ Fare calculated: ${fareCalc.formattedTotal}');
      }



      //  final response = await _pricingService.calculateFare(
      //   vehicle_type_id: _selectedVehicle!.id,
      //   distance: _routeInfo!.distanceInKm,
      //   duration: _routeInfo!.durationInMinutes,
      //   promo_code: _promoCode,
      // );

      // if (response.isSuccess && response.data != null) {
      //   final fareData = response.data!;
      //   _estimatedFare = fareData['total_fare'];
      //   _fareHash = fareData['fare_hash'];
      //   _discount = fareData['discount'];
        
      //   debugPrint('✅ Fare calculated: ₦${_estimatedFare!.toStringAsFixed(0)}');
      // }

      _isCalculatingFare = false;
      notifyListeners();

    } catch (e) {
      debugPrint('❌ Fare calculation error: $e');
      _errorMessage = 'Could not calculate fare';
      _isCalculatingFare = false;
      notifyListeners();
    }
  }

  /// Apply promo code
  Future<void> applyPromoCode(String code) async {
    _promoCode = code;
    await calculateFare();
  }

  /// Set payment method
  void setPaymentMethod(String method) {
    _paymentMethod = method;
    debugPrint('💳 Payment method: $method');
    notifyListeners();
  }

  // ============================================
  // RIDE BOOKING
  // ============================================

  /// Book the ride
  Future<bool> bookRide(String userId) async {
    if (!canConfirmBooking) return false;

    try {
      _isBookingRide = true;
      _currentStage = BookingStage.confirmingRide;
      _errorMessage = null;
      notifyListeners();

      debugPrint('📱 Booking ride...');

      // Call bookRide with individual named parameters
      final response = await _rideService.bookRide(
        vehicleType: _selectedVehicle!.id,
        pickupLocation: _pickupAddress!,
        pickupLatitude: _pickupLocation!.latitude,
        pickupLongitude: _pickupLocation!.longitude,
        destinationLocation: _destinationAddress!,
        destinationLatitude: _destinationLocation!.latitude,
        destinationLongitude: _destinationLocation!.longitude,
        fareHash: _fareHash!,
        // Optional parameters
        cityName: null, // TODO: Get from user location context
        scheduledTime: null, // TODO: Handle scheduled rides if needed
      );

      if (response.isSuccess && response.data != null) {
        _activeRide = response.data;
        debugPrint('✅ Ride booked: ${_activeRide!.id}');

        // Connect to WebSocket
        await _connectToRideSocket(_activeRide!.id);

        _isBookingRide = false;
        _currentStage = BookingStage.searchingDriver;
        notifyListeners();
        
        return true;
      } else {
        _errorMessage = response.error ?? 'Booking failed';
        _isBookingRide = false;
        notifyListeners();
        return false;
      }

    } catch (e) {
      debugPrint('❌ Booking error: $e');
      _errorMessage = 'Could not book ride';
      _isBookingRide = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // WEBSOCKET CONNECTION
  // ============================================

  /// Connect to ride WebSocket
  Future<void> _connectToRideSocket(String rideId) async {
    try {
      // TODO: Get auth token from secure storage
      const authToken = 'YOUR_AUTH_TOKEN';
      
      await _socketService.connectToRide(rideId, authToken);

      // Listen to driver location updates
      _socketService.driverLocationStream.listen((update) {
        _driverLocation = update;
        notifyListeners();
      });

      // Listen to ride status updates
      _socketService.rideStatusStream.listen((update) {
        _handleRideStatusUpdate(update);
      });

      // Listen to driver match
      _socketService.driverMatchStream.listen((match) {
        _handleDriverMatched(match);
      });

      debugPrint('✅ Connected to ride WebSocket');
    } catch (e) {
      debugPrint('❌ WebSocket connection error: $e');
    }
  }

  void _handleRideStatusUpdate(RideStatusUpdate update) {
    debugPrint('📡 Ride status: ${update.status}');
    
    switch (update.status) {
      case 'driver_arrived':
        _currentStage = BookingStage.driverArriving;
        break;
      case 'in_progress':
        _currentStage = BookingStage.inProgress;
        break;
      case 'completed':
        _currentStage = BookingStage.completed;
        break;
      case 'cancelled':
        _currentStage = BookingStage.cancelled;
        break;
    }
    
    notifyListeners();
  }

  void _handleDriverMatched(DriverMatchUpdate match) {
    debugPrint('✅ Driver matched: ${match.driverName}');
    _currentStage = BookingStage.driverMatched;
    notifyListeners();
  }

  // ============================================
  // RIDE CANCELLATION
  // ============================================

  /// Cancel active ride
  Future<bool> cancelRide(String reason) async {
    if (_activeRide == null) return false;

    try {
      // cancelRide takes rideId and optional reason parameter
      final response = await _rideService.cancelRide(
        _activeRide!.id,
        reason: reason,
      );
      
      if (response.isSuccess) {
        _socketService.cancelRide(reason);
        await _socketService.disconnect();
        
        _currentStage = BookingStage.cancelled;
        notifyListeners();
        
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Cancel error: $e');
      return false;
    }
  }

  // ============================================
  // RESET
  // ============================================

  /// Reset booking flow
  void reset() {
    _currentStage = BookingStage.selectingDestination;
    _pickupLocation = null;
    _pickupAddress = null;
    _destinationLocation = null;
    _destinationAddress = null;
    _stops = null;
    _routeInfo = null;
    _selectedVehicle = null;
    _estimatedFare = null;
    _fareHash = null;
    _promoCode = null;
    _discount = null;
    _activeRide = null;
    _driverLocation = null;
    _paymentMethod = 'cash';
    _errorMessage = null;
    
    debugPrint('🔄 Booking controller reset');
    notifyListeners();
  }

  // ============================================
  // CLEANUP
  // ============================================

  @override
  void dispose() {
    _socketService.disconnect();
    debugPrint('🗑️ Disposing ride booking controller');
    super.dispose();
  }
}