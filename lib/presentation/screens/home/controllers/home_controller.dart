// ==================== controllers/home_controller.dart ====================
// HOME CONTROLLER - Business logic for home screen
// Manages location, vehicles, and user interactions

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../models/vehicle_type.dart';
import '../../../../models/location.dart';
import '../../../../services/location_service.dart';
import '../../../../services/pricing_service.dart';
import 'package:swiftride/services/api_client.dart';

class HomeController extends ChangeNotifier {
  // Services
  final LocationService _locationService = LocationService();
  final PricingService _pricingService = PricingService();
  final ApiClient _apiClient = ApiClient.instance;

  // State
  Position? _currentPosition;
  String _currentCity = 'Detecting...';
  String _currentCountry = '';
  List<VehicleType> _availableVehicles = [];
  List<RecentLocation> _recentLocations = [];
  VehicleType? _selectedVehicle;
  String? _homeAddress;
  String? _workAddress;
  
  // Loading states
  bool _isLoadingLocation = true;
  bool _isLoadingVehicles = true;
  bool _isLoadingRecent = true;
  
  // Error state
  String? _errorMessage;

  // Getters
  Position? get currentPosition => _currentPosition;
  String get currentCity => _currentCity;
  String get currentCountry => _currentCountry;
  List<VehicleType> get availableVehicles => _availableVehicles;
  List<RecentLocation> get recentLocations => _recentLocations;
  VehicleType? get selectedVehicle => _selectedVehicle;
  String? get homeAddress => _homeAddress;
  String? get workAddress => _workAddress;
  
  bool get isLoadingLocation => _isLoadingLocation;
  bool get isLoadingVehicles => _isLoadingVehicles;
  bool get isLoadingRecent => _isLoadingRecent;
  bool get isLoading => _isLoadingLocation || _isLoadingVehicles || _isLoadingRecent;
  String? get errorMessage => _errorMessage;
  
  LatLng? get currentLatLng => _currentPosition != null
      ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
      : null;

  // ============================================
  // INITIALIZATION
  // ============================================

  /// Initialize home screen
  Future<void> initialize() async {
    debugPrint('🏠 Initializing home controller');
    
    // Load everything in parallel
    await Future.wait([
      getCurrentLocationAndDetectCity(),
      loadSavedPlaces(),
    ]);
    
    // Load vehicles after we know the city
    await loadAvailableVehicles();
    await loadRecentLocations();
    
    debugPrint('✅ Home controller initialized');
  }

  // ============================================
  // LOCATION DETECTION
  // ============================================

  /// Get current location and detect city
  Future<void> getCurrentLocationAndDetectCity() async {
    try {
      _isLoadingLocation = true;
      _errorMessage = null;
      notifyListeners();

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setError('Location permission denied');
          _currentCity = 'Permission Denied';
          _isLoadingLocation = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setError('Please enable location in settings');
        _currentCity = 'Permission Required';
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      // Get position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      _currentPosition = position;
      debugPrint('📍 Location detected: ${position.latitude}, ${position.longitude}');

      // Detect city from coordinates
      await _detectCityFromCoordinates(position);

    } catch (e) {
      debugPrint('❌ Location error: $e');
      _setError('Could not detect location');
      _currentCity = 'Makurdi'; // Fallback
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  /// Detect city name from coordinates using reverse geocoding
  Future<void> _detectCityFromCoordinates(Position position) async {
    try {
      debugPrint('🔍 Detecting city from coordinates');

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        
        // Extract city name
        String cityName = place.locality ?? 
                         place.subAdministrativeArea ?? 
                         place.administrativeArea ?? 
                         'Makurdi';
        
        String country = place.country ?? '';

        _currentCity = cityName;
        _currentCountry = country;
        _isLoadingLocation = false;
        
        debugPrint('✅ City detected: $cityName, $country');
        notifyListeners();

        // Reload vehicles for this city
        await loadAvailableVehicles();
      }
    } catch (e) {
      debugPrint('❌ Geocoding error: $e');
      _currentCity = 'Makurdi';
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  // ============================================
  // VEHICLE LOADING
  // ============================================

  /// Load available vehicles from backend
  Future<void> loadAvailableVehicles() async {
    try {
      _isLoadingVehicles = true;
      notifyListeners();

      debugPrint('🚗 Loading vehicles for: $_currentCity');

      final response = await _pricingService.getVehicleTypes(cityName: _currentCity);

      if (response.isSuccess && response.data != null) {
        _availableVehicles = response.data!.where((v) => v.available).toList();
        
        // Auto-select first vehicle
        if (_availableVehicles.isNotEmpty && _selectedVehicle == null) {
          _selectedVehicle = _availableVehicles.first;
        }
        
        debugPrint('✅ Loaded ${_availableVehicles.length} vehicles');
      } else {
        debugPrint('⚠️ Backend failed, using fallback');
        _loadLocalVehiclesFallback();
      }

      _isLoadingVehicles = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Vehicle load error: $e');
      _loadLocalVehiclesFallback();
      _isLoadingVehicles = false;
      notifyListeners();
    }
  }

  /// Fallback to local vehicle data
  void _loadLocalVehiclesFallback() {
    _availableVehicles = VehicleTypes.getVehiclesForCity(_currentCity);
    if (_availableVehicles.isNotEmpty && _selectedVehicle == null) {
      _selectedVehicle = _availableVehicles.first;
    }
  }

  // ============================================
  // SAVED PLACES
  // ============================================

  /// Load user's saved home and work addresses
  Future<void> loadSavedPlaces() async {
    try {
      final response = await _locationService.getSavedLocations();
      
      if (response.isSuccess && response.data != null) {
        for (var location in response.data!) {
          if (location.type.toLowerCase() == 'home') {
            _homeAddress = location.address;
          } else if (location.type.toLowerCase() == 'work') {
            _workAddress = location.address;
          }
        }
        
        debugPrint('✅ Loaded saved places');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error loading saved places: $e');
    }
  }

  // ============================================
  // RECENT LOCATIONS
  // ============================================

  /// Load recent locations from backend
  Future<void> loadRecentLocations() async {
    try {
      _isLoadingRecent = true;
      notifyListeners();

      final response = await _locationService.getRecentLocations();
      
      if (response.isSuccess && response.data != null) {
        _recentLocations = response.data!;
        debugPrint('✅ Loaded ${_recentLocations.length} recent locations');
      }

      _isLoadingRecent = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading recent locations: $e');
      _isLoadingRecent = false;
      notifyListeners();
    }
  }

  // ============================================
  // VEHICLE SELECTION
  // ============================================

  /// Select a vehicle type
  void selectVehicle(VehicleType vehicle) {
    _selectedVehicle = vehicle;
    debugPrint('🚗 Vehicle selected: ${vehicle.name}');
    notifyListeners();
  }

  // ============================================
  // ERROR HANDLING
  // ============================================

  void _setError(String message) {
    _errorMessage = message;
    debugPrint('❌ Error: $message');
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ============================================
  // REFRESH
  // ============================================

  /// Refresh all data
  Future<void> refresh() async {
    debugPrint('🔄 Refreshing home screen');
    await initialize();
  }

  /// Refresh only vehicles
  Future<void> refreshVehicles() async {
    await loadAvailableVehicles();
  }

  // ============================================
  // CLEANUP
  // ============================================

  @override
  void dispose() {
    debugPrint('🗑️ Disposing home controller');
    super.dispose();
  }
}