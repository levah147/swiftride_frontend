// ==================== controllers/home_controller.dart ====================
// HOME CONTROLLER - Enhanced with robust city detection
// Features: Retry logic, backend fallback, better error handling

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
  bool _showLocationError = false;

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
  bool get showLocationError => _showLocationError;
  
  LatLng? get currentLatLng => _currentPosition != null
      ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
      : null;

  // ============================================
  // INITIALIZATION
  // ============================================

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
  // ENHANCED LOCATION DETECTION
  // ============================================

  /// Get current location and detect city with retry logic
  Future<void> getCurrentLocationAndDetectCity() async {
    try {
      _isLoadingLocation = true;
      _errorMessage = null;
      _showLocationError = false;
      notifyListeners();

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setError('Location permission denied');
          _currentCity = 'Makurdi';
          _showLocationError = true;
          _isLoadingLocation = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setError('Please enable location in Settings');
        _currentCity = 'Makurdi';
        _showLocationError = true;
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      // Get position with longer timeout and medium accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // ✅ Changed from high
        timeLimit: const Duration(seconds: 30), // ✅ Increased from 15
      );

      _currentPosition = position;
      debugPrint('📍 Location detected: ${position.latitude}, ${position.longitude}');

      // Detect city with retry and fallback
      await _detectCityWithRetry(position);

    } catch (e) {
      debugPrint('❌ Location error: $e');
      _handleLocationError(e);
    }
  }

  /// Detect city with retry logic and backend fallback
  Future<void> _detectCityWithRetry(Position position) async {
    const maxRetries = 3;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('🔍 City detection attempt $attempt/$maxRetries');
        
        // Try device geocoding first
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Geocoding timeout'),
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          
          // Debug: Log all placemark data
          debugPrint('📍 Placemark data: locality=${place.locality}, '
              'subAdmin=${place.subAdministrativeArea}, '
              'admin=${place.administrativeArea}');
          
          // Extract city name with better logic
          String cityName = _extractCityName(place);
          String country = place.country ?? '';

          if (cityName.isNotEmpty && cityName != 'Unknown') {
            _currentCity = cityName;
            _currentCountry = country;
            _isLoadingLocation = false;
            _showLocationError = false;
            
            debugPrint('✅ City detected: $cityName, $country');
            notifyListeners();
            return; // Success!
          }
        }
        
        // If we got here, placemark was empty or invalid
        throw Exception('Invalid placemark data');
        
      } catch (e) {
        debugPrint('⚠️ Geocoding attempt $attempt failed: $e');
        
        if (attempt < maxRetries) {
          // Wait before retry (exponential backoff)
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
    
    // All device geocoding attempts failed, try backend
    debugPrint('🌐 Device geocoding failed, trying backend...');
    await _tryBackendGeocoding(position);
  }

  /// Extract city name from placemark with better logic
  String _extractCityName(Placemark place) {
    // Priority order for Nigeria and similar regions
    String? cityName;
    
    // 1. Try locality (most accurate for cities)
    if (place.locality != null && place.locality!.isNotEmpty) {
      cityName = place.locality;
    }
    // 2. Try subAdministrativeArea (districts/LGAs)
    else if (place.subAdministrativeArea != null && 
             place.subAdministrativeArea!.isNotEmpty) {
      cityName = place.subAdministrativeArea;
    }
    // 3. Try administrativeArea (states - use as last resort)
    else if (place.administrativeArea != null && 
             place.administrativeArea!.isNotEmpty) {
      cityName = place.administrativeArea;
    }
    
    // Clean up city name
    if (cityName != null) {
      cityName = cityName.trim();
      // Remove common suffixes
      cityName = cityName.replaceAll(RegExp(r'\s+(State|LGA|Municipality)$', caseSensitive: false), '');
    }
    
    return cityName ?? 'Unknown';
  }

  /// Try backend geocoding as fallback
  Future<void> _tryBackendGeocoding(Position position) async {
    try {
      final response = await _locationService.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        _currentCity = data['city'] ?? data['town'] ?? data['village'] ?? 'Makurdi';
        _currentCountry = data['country'] ?? '';
        _isLoadingLocation = false;
        _showLocationError = false;
        
        debugPrint('✅ Backend geocoding success: $_currentCity');
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('❌ Backend geocoding failed: $e');
    }
    
    // Final fallback
    _currentCity = 'Makurdi';
    _setError('Could not detect your city. Using Makurdi as default.');
    _showLocationError = true;
    _isLoadingLocation = false;
    notifyListeners();
  }

  /// Handle location errors
  void _handleLocationError(dynamic error) {
    String errorMsg;
    
    if (error.toString().contains('timeout')) {
      errorMsg = 'Location detection timed out. Please ensure GPS is enabled.';
    } else if (error.toString().contains('denied')) {
      errorMsg = 'Location permission denied. Please enable in Settings.';
    } else {
      errorMsg = 'Could not detect location. Using Makurdi as default.';
    }
    
    _setError(errorMsg);
    _currentCity = 'Makurdi';
    _showLocationError = true;
    _isLoadingLocation = false;
    notifyListeners();
  }

  // ============================================
  // VEHICLE LOADING
  // ============================================

  Future<void> loadAvailableVehicles() async {
    try {
      _isLoadingVehicles = true;
      notifyListeners();

      debugPrint('🚗 Loading vehicles for: $_currentCity');

      final response = await _pricingService.getVehicleTypes(cityName: _currentCity);

      if (response.isSuccess && response.data != null) {
        _availableVehicles = response.data!.where((v) => v.available).toList();
        
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

  void _loadLocalVehiclesFallback() {
    _availableVehicles = VehicleTypes.getVehiclesForCity(_currentCity);
    if (_availableVehicles.isNotEmpty && _selectedVehicle == null) {
      _selectedVehicle = _availableVehicles.first;
    }
  }

  // ============================================
  // SAVED PLACES
  // ============================================

  Future<void> loadSavedPlaces() async {
    try {
      final response = await _locationService.getSavedLocations();
      
      if (response.isSuccess && response.data != null) {
        for (var location in response.data!) {
          if (location.locationType.toLowerCase() == 'home') {
            _homeAddress = location.address;
          } else if (location.locationType.toLowerCase() == 'work') {
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
    _showLocationError = false;
    notifyListeners();
  }

  // ============================================
  // MANUAL CITY SELECTION
  // ============================================

  /// Allow user to manually set city if auto-detection fails
  Future<void> setManualCity(String cityName) async {
    _currentCity = cityName;
    _showLocationError = false;
    notifyListeners();
    
    // Reload vehicles for new city
    await loadAvailableVehicles();
  }

  // ============================================
  // REFRESH
  // ============================================

  Future<void> refresh() async {
    debugPrint('🔄 Refreshing home screen');
    await initialize();
  }

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