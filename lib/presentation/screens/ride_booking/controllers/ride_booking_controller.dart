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
import '../../../../services/location_service.dart';
import '../../../../services/geocoding_service.dart'; // ✅ ADD: For city detection

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
  final SocketAuthProvider _socketAuthProvider = SocketAuthProvider();
  final LocationService _locationService = LocationService();
  final GeocodingService _geocodingService =
      GeocodingService(); // ✅ ADD: For reverse geocoding

  // Booking stage
  BookingStage _currentStage = BookingStage.selectingDestination;

  // Location data
  LatLng? _pickupLocation;
  String? _pickupAddress;
  LatLng? _destinationLocation;
  String? _destinationAddress;
  List<RideStop>? _stops;
  String? _cityName;

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
  String? get cityName => _cityName;
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
  String? get error => _errorMessage; // ✅ ADD: Alias for compatibility

  // Computed
  bool get canProceedToVehicleSelection =>
      _pickupLocation != null && _destinationLocation != null;
  bool get canConfirmBooking =>
      _selectedVehicle != null && _estimatedFare != null && _fareHash != null;

  // ============================================
  // DESTINATION SELECTION
  // ============================================

  /// Set pickup location
  Future<void> setPickupLocation(LatLng location, String address) async {
    _pickupLocation = location;
    _pickupAddress = address;
    debugPrint('📍 Pickup set: $address');

    // Detect city from pickup location
    await _detectCity(location);

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

      // Load vehicles after route is calculated
      if (_routeInfo != null) {
        // tyr to detect city form destination if not already detected
        if (_cityName != null) {
          debugPrint(' 🔍 Attempting to detect city from destination...');
          await _detectCity(location);
        }

          // load vehicles with detected city (or null)
          await loadAvailableVehicles(_cityName!);
      } else {
        // Fallback: Try to detect city from backend or use first available city
        debugPrint('⚠️ No city detected, attempting to detect from backend...');
        // TODO: Call backend /pricing/detect-city/ endpoint with coordinates
        // For now, try to extract from address or use empty (backend will handle)
        await loadAvailableVehicles(
            _cityName ?? ''); // Let backend handle default
      }
    }
  }

  /// ✅ FIXED: Detect city from coordinates using GeocodingService
  Future<void> _detectCity(LatLng location) async {
    try {
      debugPrint('🔍 Detecting city from coordinates...');

      // Use GeocodingService to reverse geocode
      final address = await _geocodingService.reverseGeocode(location);

      if (address != null && address.city != null) {
        _cityName = address.city;
        debugPrint('🏙️ City detected: $_cityName');
      } else {
        debugPrint('⚠️ Could not detect city from coordinates');
        // Fallback: Extract from address string or use default
        _cityName = _extractCityFromAddress(_pickupAddress);

        if (_cityName == null) {
          debugPrint('⚠️ Could not detect city, will use backend default');
          // Don't set a hard-coded city - let backend handle it
          _cityName = null;
        }
      }
    } catch (e) {
      debugPrint('❌ City detection error: $e');
      // Fallback to extracting from address
      _cityName = _extractCityFromAddress(_pickupAddress);
      // Don't set hard-coded fallback - let backend handle city detection
    }
  }

  /// ✅ ADD: Extract city name from address string
  String? _extractCityFromAddress(String? address) {
    if (address == null) return null;

    // Common Nigerian cities
    const cities = [
      'Lagos',
      'Abuja',
      'Kano',
      'Ibadan',
      'Port Harcourt',
      'Benin',
      'Kaduna',
      'Jos',
      'Enugu',
      'Makurdi',
      'Warri',
      'Calabar',
      'Maiduguri',
      'Aba',
      'Onitsha',
    ];

    for (final city in cities) {
      if (address.toLowerCase().contains(city.toLowerCase())) {
        return city;
      }
    }

    return null;
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
      debugPrint(
          '✅ Route calculated: ${route.formattedDistance}, ${route.formattedDuration}');

      _isLoadingRoute = false;
      notifyListeners();

      // Move to vehicle selection
      _currentStage = BookingStage.selectingVehicle;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Route calculation error: $e');
      _errorMessage = 'Could not calculate route: ${e.toString()}';
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
      debugPrint('🚗 Loading vehicles for city: ${cityName ?? "default"}');

        // Only pass cityName if it's valid
      final response = await _pricingService.getVehicleTypes(
        cityName: (cityName != null && cityName.isNotEmpty) ? cityName : null,
      );

      if (response.isSuccess && response.data != null) {
        _availableVehicles = response.data!.where((v) => v.available).toList();
        debugPrint('✅ Loaded ${_availableVehicles.length} available vehicles');
        notifyListeners();
      } else {
        debugPrint('⚠️ API returned no vehicles, using fallback');
        // Fallback: Use local vehicle types
        _availableVehicles = VehicleTypes.getVehiclesForCity(cityName);
        debugPrint('✅ Loaded ${_availableVehicles.length} fallback vehicles');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error loading vehicles: $e');
      // Fallback: Use local vehicle types
      _availableVehicles = VehicleTypes.getVehiclesForCity(cityName);
      debugPrint('✅ Using ${_availableVehicles.length} fallback vehicles');
      notifyListeners();
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

  /// Set vehicle type by ID (for when vehicle is selected from UI)
  void setVehicleType(String vehicleTypeId) {
    final vehicle = _availableVehicles.firstWhere(
      (v) => v.id == vehicleTypeId,
      orElse: () => _availableVehicles.first,
    );
    _selectedVehicle = vehicle;
    debugPrint('🚗 Vehicle type set: ${vehicle.name}');
    notifyListeners();
  }

  // ============================================
  // FARE CALCULATION
  // ============================================

  /// Calculate fare for selected vehicle
  Future<void> calculateFare() async {
    if (_selectedVehicle == null ||
        _pickupLocation == null ||
        _destinationLocation == null) {
      debugPrint('⚠️ Cannot calculate fare: missing required data');
      return;
    }

    try {
      _isCalculatingFare = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('💰 Calculating fare for ${_selectedVehicle!.name}...');

      final response = await _pricingService.calculateFare(
        vehicleType: _selectedVehicle!.id,
        pickupLatitude: _pickupLocation!.latitude,
        pickupLongitude: _pickupLocation!.longitude,
        destinationLatitude: _destinationLocation!.latitude,
        destinationLongitude: _destinationLocation!.longitude,
        cityName: _cityName,
      );

      if (response.isSuccess && response.data != null) {
        final fareCalc = response.data!;
        _estimatedFare = fareCalc.totalFare;
        _fareHash = fareCalc.fareHash;

        // Check if there's a surge multiplier
        if (fareCalc.surgeMultiplier > 1.0) {
          debugPrint('⚡ Surge pricing active: ${fareCalc.surgeMultiplier}x');
        }

        debugPrint('✅ Fare calculated: ${fareCalc.formattedTotal}');
        debugPrint('   - Base fare: ₦${fareCalc.baseFare.toStringAsFixed(0)}');
        debugPrint(
            '   - Distance fare: ₦${fareCalc.distanceFare.toStringAsFixed(0)}');
        debugPrint('   - Time fare: ₦${fareCalc.timeFare.toStringAsFixed(0)}');
        debugPrint('   - Fare hash: $_fareHash');
      } else {
        _errorMessage = response.error ?? 'Could not calculate fare';
        debugPrint('❌ Fare calculation failed: $_errorMessage');
      }

      _isCalculatingFare = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Fare calculation error: $e');
      _errorMessage = 'Could not calculate fare: ${e.toString()}';
      _isCalculatingFare = false;
      notifyListeners();
    }
  }

  /// Apply promo code
  Future<void> applyPromoCode(String code) async {
    if (code.isEmpty) return;

    _promoCode = code;
    debugPrint('🎟️ Applying promo code: $code');

    // Recalculate fare with promo code
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
    // Validate ALL required fields
    if (_pickupLocation == null ||
        _destinationLocation == null ||
        _pickupAddress == null ||
        _destinationAddress == null ||
        _selectedVehicle == null ||
        _fareHash == null) {
      _errorMessage = 'Missing required booking information';
      debugPrint('❌ Cannot book: $_errorMessage');
      debugPrint(
          '   - Pickup location: ${_pickupLocation != null ? "✓" : "✗"}');
      debugPrint('   - Pickup address: ${_pickupAddress != null ? "✓" : "✗"}');
      debugPrint(
          '   - Destination location: ${_destinationLocation != null ? "✓" : "✗"}');
      debugPrint(
          '   - Destination address: ${_destinationAddress != null ? "✓" : "✗"}');
      debugPrint('   - Vehicle: ${_selectedVehicle != null ? "✓" : "✗"}');
      debugPrint('   - Fare hash: ${_fareHash != null ? "✓" : "✗"}');
      notifyListeners();
      return false;
    }

    try {
      _isBookingRide = true;
      _currentStage = BookingStage.confirmingRide;
      _errorMessage = null;
      notifyListeners();

      debugPrint('📱 Booking ride...');
      debugPrint('   - Vehicle: ${_selectedVehicle!.name}');
      debugPrint('   - From: $_pickupAddress');
      debugPrint('   - To: $_destinationAddress');
      debugPrint('   - City: ${_cityName ?? "Not detected"}');
      debugPrint('   - Estimated fare: ₦${_estimatedFare?.toStringAsFixed(0)}');

      final response = await _rideService.bookRide(
        vehicleType: _selectedVehicle!.id,
        pickupLocation: _pickupAddress!,
        pickupLatitude: _pickupLocation!.latitude,
        pickupLongitude: _pickupLocation!.longitude,
        destinationLocation: _destinationAddress!,
        destinationLatitude: _destinationLocation!.latitude,
        destinationLongitude: _destinationLocation!.longitude,
        fareHash: _fareHash!,
        cityName: _cityName,
        scheduledTime: null,
      );

      if (response.isSuccess && response.data != null) {
        _activeRide = response.data;
        debugPrint('✅ Ride booked successfully!');
        debugPrint('   - Ride ID: ${_activeRide!.id}');
        debugPrint('   - Status: ${_activeRide!.status.displayName}');

        // Connect to WebSocket for real-time updates
        await _connectToRideSocket(_activeRide!.id);

        _isBookingRide = false;
        _currentStage = BookingStage.searchingDriver;
        notifyListeners();

        return true;
      } else {
        _errorMessage = response.error ?? 'Booking failed';
        debugPrint('❌ Booking failed: $_errorMessage');
        _isBookingRide = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Booking error: $e');
      _errorMessage = 'Could not book ride: ${e.toString()}';
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
      debugPrint('🔌 Connecting to ride WebSocket...');

      // Fetch stored JWT for socket authentication
      final authToken = await _socketAuthProvider.getToken();
      if (authToken == null) {
        debugPrint('❌ Cannot connect WS: missing auth token');
        _errorMessage = 'Authentication required';
        return;
      }

      await _socketService.connectToRide(rideId, authToken);

      // Listen to driver location updates
      _socketService.driverLocationStream.listen(
        (update) {
          _driverLocation = update;
          debugPrint('📍 Driver location updated');
          notifyListeners();
        },
        onError: (error) {
          debugPrint('❌ Driver location stream error: $error');
        },
      );

      // Listen to ride status updates
      _socketService.rideStatusStream.listen(
        (update) {
          _handleRideStatusUpdate(update);
        },
        onError: (error) {
          debugPrint('❌ Ride status stream error: $error');
        },
      );

      // Listen to driver match
      _socketService.driverMatchStream.listen(
        (match) {
          _handleDriverMatched(match);
        },
        onError: (error) {
          debugPrint('❌ Driver match stream error: $error');
        },
      );

      debugPrint('✅ Connected to ride WebSocket successfully');
    } catch (e) {
      debugPrint('❌ WebSocket connection error: $e');
      _errorMessage = 'Could not connect to real-time updates';
    }
  }

  void _handleRideStatusUpdate(RideStatusUpdate update) {
    debugPrint('📡 Ride status update: ${update.status}');

    switch (update.status) {
      case 'accepted':
        _currentStage = BookingStage.driverMatched;
        break;
      case 'driver_arrived':
      case 'arriving':
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
      default:
        debugPrint('⚠️ Unknown ride status: ${update.status}');
    }

    notifyListeners();
  }

  void _handleDriverMatched(DriverMatchUpdate match) {
    debugPrint('✅ Driver matched!');
    debugPrint('   - Name: ${match.driverName}');
    debugPrint('   - Phone: ${match.driverPhone}');
    debugPrint('   - Rating: ${match.driverRating}');
    debugPrint('   - Vehicle: ${match.vehicleModel} (${match.vehicleColor})');
    debugPrint('   - License: ${match.licensePlate}');
    debugPrint(
        '   - ETA: ${match.eta} minutes'); // ✅ FIXED: Changed from etaMinutes to eta

    _currentStage = BookingStage.driverMatched;
    notifyListeners();
  }

  // ============================================
  // RIDE CANCELLATION
  // ============================================

  /// Cancel active ride
  Future<bool> cancelRide(String reason) async {
    if (_activeRide == null) {
      debugPrint('⚠️ No active ride to cancel');
      return false;
    }

    try {
      debugPrint('🚫 Cancelling ride: ${_activeRide!.id}');
      debugPrint('   - Reason: $reason');

      final response = await _rideService.cancelRide(
        _activeRide!.id,
        reason: reason,
      );

      if (response.isSuccess) {
        debugPrint('✅ Ride cancelled successfully');

        // Notify via WebSocket
        _socketService.cancelRide(reason);

        // Disconnect WebSocket
        await _socketService.disconnect();

        _currentStage = BookingStage.cancelled;
        notifyListeners();

        return true;
      } else {
        debugPrint('❌ Cancellation failed: ${response.error}');
        _errorMessage = response.error ?? 'Could not cancel ride';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Cancel error: $e');
      _errorMessage = 'Could not cancel ride: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // RESET
  // ============================================

  /// Reset booking flow
  void reset() {
    debugPrint('🔄 Resetting booking controller...');

    _currentStage = BookingStage.selectingDestination;
    _pickupLocation = null;
    _pickupAddress = null;
    _destinationLocation = null;
    _destinationAddress = null;
    _cityName = null;
    _stops = null;
    _routeInfo = null;
    _selectedVehicle = null;
    _availableVehicles = [];
    _estimatedFare = null;
    _fareHash = null;
    _promoCode = null;
    _discount = null;
    _activeRide = null;
    _driverLocation = null;
    _paymentMethod = 'cash';
    _errorMessage = null;
    _isLoadingRoute = false;
    _isCalculatingFare = false;
    _isBookingRide = false;
    _isSearchingDriver = false;

    debugPrint('✅ Booking controller reset complete');
    notifyListeners();
  }

  // ============================================
  // CLEANUP
  // ============================================

  @override
  void dispose() {
    debugPrint('🗑️ Disposing ride booking controller...');
    _socketService.disconnect();
    super.dispose();
  }
}
