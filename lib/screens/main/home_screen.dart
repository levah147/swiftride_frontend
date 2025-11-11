import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:swiftride/models/location.dart';
import '../../constants/colors.dart';
import '../../constants/app_dimensions.dart';
import '../../models/vehicle_type.dart';
import '../../services/location_service.dart';
import '../../services/ride_service.dart';
import '../../services/api_client.dart';
import '../rides_booking/ride_options_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(String, {Map<String, dynamic>? data}) onNavigate;

  const HomeScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  bool _isLoadingVehicles = true;
  bool _isLoadingRecent = true;
  String _currentCity = 'Detecting...'; // ✅ DYNAMIC - NOT STATIC!
  String _currentCountry = '';
  
  // Draggable bottom sheet
  late AnimationController _bottomSheetController;
  final DraggableScrollableController _scrollController = DraggableScrollableController();
  
  // Dynamic data from API
  List<VehicleType> _availableVehicles = [];
  List<RecentLocation> _recentLocations = []; 
  VehicleType? _selectedVehicle;
  String? _homeAddress;
  String? _workAddress;

  // Services
  final LocationService _locationService = LocationService();
  final RideService _rideService = RideService();
  final ApiClient _apiClient = ApiClient.instance;

  @override
  void initState() {
    super.initState();
    _initializeBottomSheet();
    _initializeScreen();
  }

  void _initializeBottomSheet() {
    _bottomSheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bottomSheetController.forward();
  }

  Future<void> _initializeScreen() async {
    // Load everything in parallel
    await Future.wait([
      _getCurrentLocationAndDetectCity(), // ✅ AUTO DETECT CITY
      _loadSavedPlaces(),
    ]);
    
    // Load vehicles AFTER we know the city
    await _loadAvailableVehiclesFromBackend(); // ✅ FROM BACKEND
    await _loadRecentLocations();
  }

  // ============================================
  // ✅ AUTO CITY DETECTION - NOT STATIC!
  // ============================================
  Future<void> _getCurrentLocationAndDetectCity() async {
    try {
      setState(() => _isLoadingLocation = true);

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied');
          setState(() {
            _currentCity = 'Permission Denied';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Please enable location in settings');
        setState(() {
          _currentCity = 'Permission Required';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
      });

      // ✅ Move camera with 3D effect
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16.0, // Higher zoom for detail
            tilt: 45.0, // ✅ 3D TILT
            bearing: 0,
          ),
        ),
      );

      // ✅ GET ACTUAL CITY NAME FROM COORDINATES
      await _detectCityFromCoordinates(position);

    } catch (e) {
      debugPrint('❌ Location error: $e');
      if (mounted) {
        setState(() {
          _currentCity = 'Makurdi'; // Fallback
          _isLoadingLocation = false;
        });
        _showError('Could not detect location');
      }
    }
  }

  // ============================================
  // ✅ REVERSE GEOCODING - GET REAL CITY NAME
  // ============================================
  Future<void> _detectCityFromCoordinates(Position position) async {
    try {
      debugPrint('🔍 Detecting city from: ${position.latitude}, ${position.longitude}');

      // Use geocoding to get place name
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        
        // Extract city name (try multiple fields)
        String cityName = place.locality ?? 
                         place.subAdministrativeArea ?? 
                         place.administrativeArea ?? 
                         'Makurdi'; // Final fallback
        
        String country = place.country ?? '';

        if (!mounted) return;

        setState(() {
          _currentCity = cityName;
          _currentCountry = country;
          _isLoadingLocation = false;
        });

        debugPrint('✅ City detected: $cityName, $country');

        // Reload vehicles for this city
        await _loadAvailableVehiclesFromBackend();
      }
    } catch (e) {
      debugPrint('❌ Geocoding error: $e');
      if (mounted) {
        setState(() {
          _currentCity = 'Makurdi';
          _isLoadingLocation = false;
        });
      }
    }
  }

  // ============================================
  // ✅ LOAD VEHICLES FROM BACKEND - DYNAMIC!
  // ============================================
  Future<void> _loadAvailableVehiclesFromBackend() async {
    try {
      setState(() => _isLoadingVehicles = true);

      debugPrint('🚗 Loading vehicles for: $_currentCity');

      // ✅ CALL BACKEND API
      final response = await _apiClient.get<List<dynamic>>(
        '/vehicles/types/',
        queryParams: {
          'city': _currentCity,
          if (_currentPosition != null) ...{
            'latitude': _currentPosition!.latitude.toString(),
            'longitude': _currentPosition!.longitude.toString(),
          },
        },
        fromJson: (json) => json as List<dynamic>,
      );

      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        // ✅ Parse vehicles from backend response
        final vehicles = response.data!.map((item) {
          return VehicleType.fromJson(item as Map<String, dynamic>);
        }).toList();

        setState(() {
          _availableVehicles = vehicles.where((v) => v.available).toList();
          _isLoadingVehicles = false;
        });

        debugPrint('✅ Loaded ${_availableVehicles.length} vehicles from backend');
      } else {
        // Backend failed - use local fallback
        debugPrint('⚠️ Backend failed: ${response.error}');
        _loadLocalVehiclesFallback();
      }
    } catch (e) {
      debugPrint('❌ Vehicle load error: $e');
      _loadLocalVehiclesFallback();
    }
  }

  // Fallback to local data if backend unavailable
  void _loadLocalVehiclesFallback() {
    debugPrint('📱 Using local vehicle data for: $_currentCity');
    setState(() {
      _availableVehicles = VehicleTypes.getVehiclesForCity(_currentCity);
      _isLoadingVehicles = false;
    });
  }

  Future<void> _loadRecentLocations() async {
    try {
      setState(() => _isLoadingRecent = true);

      final response = await _locationService.getRecentLocations();
      
      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        setState(() {
          _recentLocations = response.data!;
          _isLoadingRecent = false;
        });
        debugPrint('✅ Loaded ${_recentLocations.length} recent locations');
      } else {
        setState(() {
          _recentLocations = [];
          _isLoadingRecent = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Recent locations error: $e');
      if (mounted) {
        setState(() {
          _recentLocations = [];
          _isLoadingRecent = false;
        });
      }
    }
  }

  Future<void> _loadSavedPlaces() async {
    try {
      final response = await _locationService.getSavedLocations();
      
      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        for (var place in response.data!) {
          if (place.type.toLowerCase() == 'home') {
            setState(() => _homeAddress = place.address);
          } else if (place.type.toLowerCase() == 'work') {
            setState(() => _workAddress = place.address);
          }
        }
        debugPrint('✅ Loaded saved places');
      }
    } catch (e) {
      debugPrint('❌ Saved places error: $e');
    }
  }

  void _bookRide(String title, String address) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideOptionsScreen(
          from: 'Current Location',
          to: title,
          isScheduled: false,
          city: _currentCity,
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _bottomSheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ 3D SHARP MAP (Full screen)
          _buildMap(),
          
          // Top gradient overlay
          _buildTopGradient(),
          
          // Recenter button
          _buildRecenterButton(),
          
          // Draggable bottom sheet
          _buildDraggableBottomSheet(),
        ],
      ),
    );
  }

  // ============================================
  // ✅ SHARP 3D MAP WITH DETAILS
  // ============================================
  Widget _buildMap() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentPosition != null
              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
              : const LatLng(7.7304, 8.5378), // Makurdi fallback
          zoom: 16.0,
          tilt: 45.0, // ✅ 3D TILT
        ),
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
          
          // ✅ APPLY DETAILED MAP STYLE
          _mapController?.setMapStyle('''
            [
              {
                "featureType": "poi",
                "elementType": "labels",
                "stylers": [{"visibility": "on"}]
              },
              {
                "featureType": "road",
                "elementType": "geometry",
                "stylers": [{"visibility": "simplified"}]
              },
              {
                "featureType": "landscape",
                "elementType": "geometry",
                "stylers": [{"visibility": "on"}]
              }
            ]
          ''');
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        compassEnabled: true,
        mapToolbarEnabled: false,
        buildingsEnabled: true, // ✅ 3D BUILDINGS
        trafficEnabled: false,
        indoorViewEnabled: true,
        liteModeEnabled: false, // ✅ FULL QUALITY - NOT LITE MODE
        mapType: MapType.normal,
        minMaxZoomPreference: const MinMaxZoomPreference(12, 20),
      ),
    );
  }

  Widget _buildTopGradient() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundPrimary.withOpacity(0.9),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: GestureDetector(
              onTap: () {
                // Show city picker or refresh location
                _getCurrentLocationAndDetectCity();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isLoadingLocation ? Icons.location_searching : Icons.location_on,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currentCity, // ✅ DYNAMIC CITY NAME
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (_isLoadingLocation)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      )
                    else
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecenterButton() {
    return Positioned(
      right: AppDimensions.paddingLarge,
      bottom: MediaQuery.of(context).size.height * 0.35,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(Icons.my_location, color: AppColors.primary),
          onPressed: _getCurrentLocationAndDetectCity,
          tooltip: 'Recenter & Detect City',
        ),
      ),
    );
  }

  Widget _buildDraggableBottomSheet() {
    return DraggableScrollableSheet(
      controller: _scrollController,
      initialChildSize: 0.35,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundPrimary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // ✅ IMPROVED SEARCH BAR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
                child: _buildImprovedSearchBar(),
              ),
              
              const SizedBox(height: 20),
              
              // ✅ VEHICLE SELECTOR (FROM BACKEND)
              if (_isLoadingVehicles)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text(
                          'Loading vehicles...',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_availableVehicles.isNotEmpty)
                _buildVehicleSelector(),
              
              const SizedBox(height: 20),
              
              // Quick actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
                child: _buildQuickActions(),
              ),
              
              const SizedBox(height: 20),
              
              // Recent locations
              if (_isLoadingRecent)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_recentLocations.isNotEmpty)
                _buildRecentLocations(),
              
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  // ============================================
  // ✅ IMPROVED SEARCH BAR
  // ============================================
  Widget _buildImprovedSearchBar() {
    return GestureDetector(
      onTap: () => widget.onNavigate('destination_selection'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.surface,
              AppColors.surface.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.search, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Where to?',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Search destination',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: AppColors.primary,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Rides',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'in $_currentCity', // ✅ Show current city
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
            itemCount: _availableVehicles.length,
            itemBuilder: (context, index) {
              final vehicle = _availableVehicles[index];
              final isSelected = _selectedVehicle?.id == vehicle.id;
              
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedVehicle = vehicle);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 85,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? vehicle.color.withOpacity(0.15) 
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? vehicle.color : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: vehicle.color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        vehicle.icon,
                        color: isSelected ? vehicle.color : AppColors.textSecondary,
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        vehicle.name,
                        style: TextStyle(
                          color: isSelected ? vehicle.color : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vehicle.formattedBasePrice,
                        style: TextStyle(
                          color: isSelected ? vehicle.color : AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.home_outlined,
            label: _homeAddress?.split(',').first ?? 'Add Home',
            onTap: () {
              if (_homeAddress != null) {
                _bookRide('Home', _homeAddress!);
              } else {
                _showError('Please add your home address in Account settings');
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.work_outline,
            label: _workAddress?.split(',').first ?? 'Add Work',
            onTap: () {
              if (_workAddress != null) {
                _bookRide('Work', _workAddress!);
              } else {
                _showError('Please add your work address in Account settings');
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLocations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              TextButton(
                onPressed: () {
                  widget.onNavigate('destination_selection');
                },
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
          itemCount: _recentLocations.length > 3 ? 3 : _recentLocations.length,
          itemBuilder: (context, index) {
            final location = _recentLocations[index];
            return _buildLocationItem(
              title: location.address.split(',').first,
              subtitle: location.address,
              onTap: () => _bookRide(
                location.address.split(',').first,
                location.address,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLocationItem({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.history,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}