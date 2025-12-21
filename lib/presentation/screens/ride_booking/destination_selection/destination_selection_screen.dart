// ==================== destination_selection_screen.dart ====================
// REDESIGNED - Multi-stop support, editable pickup, real-time search

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../constants/app_dimensions.dart';
import 'package:swiftride/routes/app_routes.dart';
import 'package:swiftride/routes/route_arguments.dart';
import '../../../../services/location_service.dart';
import '../../../../services/geocoding_service.dart';
import '../../../../models/location.dart';
import '../../../../models/route_stop.dart';
import 'widgets/route_header.dart';
import 'widgets/route_stops_input.dart';
import 'widgets/location_list_items.dart';
import 'widgets/continue_button.dart';

class DestinationSelectionScreen extends StatefulWidget {
  final String? pickupAddress;
  final LatLng? pickupLatLng;

  const DestinationSelectionScreen({
    super.key,
    this.pickupAddress,
    this.pickupLatLng,
  });

  @override
  State<DestinationSelectionScreen> createState() =>
      _DestinationSelectionScreenState();
}

class _DestinationSelectionScreenState
    extends State<DestinationSelectionScreen> {
  // Services
  final LocationService _locationService = LocationService();
  final GeocodingService _geocodingService = GeocodingService();

  // Route stops state (replaces _fromController/_toController)
  List<RouteStop> _routeStops = [];
  final Map<String, TextEditingController> _stopControllers = {};
  final Map<String, FocusNode> _stopFocusNodes = {};

  // Currently focused/active stop for search
  String? _activeStopId;

  // Search state
  bool _isSearching = false;
  List<PlaceSuggestion> _placeSuggestions = [];

  // Saved and recent locations
  bool _isLoadingSaved = false;
  bool _isLoadingRecent = false;
  List<SavedLocation> _savedLocations = [];
  List<RecentLocation> _recentLocations = [];

  // Constants
  static const int maxStops = 5; // pickup + 3 waypoints + destination

  @override
  void initState() {
    super.initState();
    _initializeRouteStops();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedAndRecentLocations();
    });
  }

  @override
  void dispose() {
    // Dispose all controllers and focus nodes
    for (var controller in _stopControllers.values) {
      controller.dispose();
    }
    for (var focusNode in _stopFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  // ============================================
  // INITIALIZATION
  // ============================================

  void _initializeRouteStops() {
    // Initialize with pickup and destination
    final pickup = RouteStop.pickup(
      address: widget.pickupAddress ?? '',
      latitude: widget.pickupLatLng?.latitude ?? 0,
      longitude: widget.pickupLatLng?.longitude ?? 0,
      placeName: widget.pickupAddress ?? 'Current Location',
    );

    final destination = RouteStop.destination(
      order: 1,
      address: '',
      latitude: 0,
      longitude: 0,
    );

    _routeStops = [pickup, destination];

    // Create controllers and focus nodes
    for (var stop in _routeStops) {
      _stopControllers[stop.id] = TextEditingController(text: stop.displayName);
      _stopFocusNodes[stop.id] = FocusNode();

      // Add listener for search
      _stopControllers[stop.id]!.addListener(() {
        _onStopTextChanged(stop.id);
      });

      // Focus listener to track active stop
      _stopFocusNodes[stop.id]!.addListener(() {
        if (_stopFocusNodes[stop.id]!.hasFocus) {
          setState(() => _activeStopId = stop.id);
        }
      });
    }

    // Auto-focus destination field
    Future.delayed(const Duration(milliseconds: 100), () {
      _stopFocusNodes['destination']?.requestFocus();
    });
  }

  // ============================================
  // STOP MANAGEMENT
  // ============================================

  void _addStop() {
    if (_routeStops.length >= maxStops) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum $maxStops stops allowed')),
      );
      return;
    }

    setState(() {
      // Insert waypoint before destination
      final waypointOrder = _routeStops.length - 1;
      final waypoint = RouteStop.waypoint(
        order: waypointOrder,
        address: '',
        latitude: 0,
        longitude: 0,
      );

      // Update destination order
      final destination = _routeStops.last.copyWith(order: waypointOrder + 1);

      // Remove old destination, add waypoint, add new destination
      _routeStops.removeLast();
      _routeStops.add(waypoint);
      _routeStops.add(destination);

      // Create controller and focus node for new waypoint
      _stopControllers[waypoint.id] = TextEditingController();
      _stopFocusNodes[waypoint.id] = FocusNode();

      _stopControllers[waypoint.id]!.addListener(() {
        _onStopTextChanged(waypoint.id);
      });

      _stopFocusNodes[waypoint.id]!.addListener(() {
        if (_stopFocusNodes[waypoint.id]!.hasFocus) {
          setState(() => _activeStopId = waypoint.id);
        }
      });
    });

    // Auto-focus new waypoint
    Future.delayed(const Duration(milliseconds: 100), () {
      _stopFocusNodes[_routeStops[_routeStops.length - 2].id]?.requestFocus();
    });
  }

  void _removeStop(String stopId) {
    setState(() {
      final index = _routeStops.indexWhere((s) => s.id == stopId);
      if (index == -1) return;

      _routeStops.removeAt(index);

      // Dispose controller and focus node
      _stopControllers[stopId]?.dispose();
      _stopFocusNodes[stopId]?.dispose();
      _stopControllers.remove(stopId);
      _stopFocusNodes.remove(stopId);

      // Reorder remaining stops
      for (int i = 0; i < _routeStops.length; i++) {
        _routeStops[i] = _routeStops[i].copyWith(order: i);
      }
    });
  }

  void _moveStopUp(String stopId) {
    final index = _routeStops.indexWhere((s) => s.id == stopId);
    if (index <= 1) return; // Can't move above pickup

    setState(() {
      final stop = _routeStops.removeAt(index);
      _routeStops.insert(index - 1, stop);

      // Reorder
      for (int i = 0; i < _routeStops.length; i++) {
        _routeStops[i] = _routeStops[i].copyWith(order: i);
      }
    });
  }

  void _moveStopDown(String stopId) {
    final index = _routeStops.indexWhere((s) => s.id == stopId);
    if (index == -1 || index >= _routeStops.length - 1)
      return; // Can't move below destination

    setState(() {
      final stop = _routeStops.removeAt(index);
      _routeStops.insert(index + 1, stop);

      // Reorder
      for (int i = 0; i < _routeStops.length; i++) {
        _routeStops[i] = _routeStops[i].copyWith(order: i);
      }
    });
  }

  // ============================================
  // SEARCH & LOCATION HANDLING
  // ============================================

  void _onStopTextChanged(String stopId) {
    final query = _stopControllers[stopId]?.text ?? '';

    if (query.isEmpty) {
      setState(() {
        _placeSuggestions = [];
        _isSearching = false;
      });
    } else {
      _searchPlaces(query);
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.length < 3) {
      setState(() {
        _placeSuggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final suggestions = await _geocodingService.getPlaceSuggestions(
        query: query,
        location: widget.pickupLatLng,
        radius: 50000,
      );

      if (mounted) {
        setState(() {
          _placeSuggestions = suggestions;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
      debugPrint('❌ Error searching places: $e');
    }
  }

  Future<void> _selectPlaceSuggestion(PlaceSuggestion suggestion) async {
    if (_activeStopId == null) return;

    final details = await _geocodingService.getPlaceDetails(suggestion.placeId);

    if (details == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get place details')),
        );
      }
      return;
    }

    // Update the active stop
    final index = _routeStops.indexWhere((s) => s.id == _activeStopId);
    if (index == -1) return;

    setState(() {
      _routeStops[index] = _routeStops[index].copyWith(
        address: details.formattedAddress,
        latitude: details.location.latitude,
        longitude: details.location.longitude,
        placeId: details.placeId,
        placeName: details.name,
      );

      _stopControllers[_activeStopId]?.text = details.name;
      _placeSuggestions = [];
    });

    _stopFocusNodes[_activeStopId]?.unfocus();

    await _saveRecentLocation(
      address: details.formattedAddress,
      latitude: details.location.latitude,
      longitude: details.location.longitude,
    );
  }

  Future<void> _selectSavedLocation(SavedLocation location) async {
    if (_activeStopId == null) return;

    final index = _routeStops.indexWhere((s) => s.id == _activeStopId);
    if (index == -1) return;

    setState(() {
      _routeStops[index] = _routeStops[index].copyWith(
        address: location.address,
        latitude: location.latitude,
        longitude: location.longitude,
        placeName: location.displayName,
      );

      _stopControllers[_activeStopId]?.text = location.displayName;
    });

    _stopFocusNodes[_activeStopId]?.unfocus();

    await _saveRecentLocation(
      address: location.address,
      latitude: location.latitude,
      longitude: location.longitude,
    );
  }

  Future<void> _selectRecentLocation(RecentLocation location) async {
    if (_activeStopId == null) return;

    final index = _routeStops.indexWhere((s) => s.id == _activeStopId);
    if (index == -1) return;

    setState(() {
      _routeStops[index] = _routeStops[index].copyWith(
        address: location.address,
        latitude: location.latitude,
        longitude: location.longitude,
        placeName: location.placeName,
      );

      _stopControllers[_activeStopId]?.text = location.placeName;
    });

    _stopFocusNodes[_activeStopId]?.unfocus();
  }

  Future<void> _useCurrentLocation() async {
    // Get current location and update pickup
    try {
      final currentPosition = widget.pickupLatLng;
      if (currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location')),
        );
        return;
      }

      final address = await _geocodingService.reverseGeocode(currentPosition);

      setState(() {
        _routeStops[0] = _routeStops[0].copyWith(
          address: address?.formattedAddress ?? 'Current Location',
          latitude: currentPosition.latitude,
          longitude: currentPosition.longitude,
          placeName: 'Current Location',
        );

        _stopControllers['pickup']?.text = 'Current Location';
      });
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }

  // ============================================
  // DATA LOADING
  // ============================================

  Future<void> _loadSavedAndRecentLocations() async {
    setState(() {
      _isLoadingSaved = true;
      _isLoadingRecent = true;
    });

    // Load saved locations
    final savedResponse = await _locationService.getSavedLocations();
    if (savedResponse.isSuccess && savedResponse.data != null) {
      setState(() {
        _savedLocations = savedResponse.data!;
        _isLoadingSaved = false;
      });
    } else {
      setState(() => _isLoadingSaved = false);
    }

    // Load recent locations
    final recentResponse = await _locationService.getRecentLocations(limit: 10);
    if (recentResponse.isSuccess && recentResponse.data != null) {
      setState(() {
        _recentLocations = recentResponse.data!;
        _isLoadingRecent = false;
      });
    } else {
      setState(() => _isLoadingRecent = false);
    }
  }

  Future<void> _saveRecentLocation({
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _locationService.addRecentLocation(
        address: address,
        latitude: latitude,
        longitude: longitude,
      );

      final response = await _locationService.getRecentLocations(limit: 10);
      if (response.isSuccess && response.data != null && mounted) {
        setState(() => _recentLocations = response.data!);
      }
    } catch (e) {
      debugPrint('⚠️ Could not save recent location: $e');
    }
  }

  // ============================================
  // NAVIGATION & VALIDATION
  // ============================================

  bool get _canContinue {
    // All stops must have valid coordinates
    return _routeStops.length >= 2 &&
        _routeStops.every((stop) => stop.hasValidLocation);
  }

  bool get _shouldShowButton {
    // Show button if any stop is being edited or has content
    return _routeStops
        .any((stop) => _stopControllers[stop.id]?.text.isNotEmpty ?? false);
  }

  bool get _shouldShowRecent {
    // Show recent only if no stop is being actively searched
    return _stopControllers.values.every((c) =>
            c.text.isEmpty ||
            _routeStops.any(
                (s) => _stopControllers[s.id] == c && s.hasValidLocation)) &&
        _recentLocations.isNotEmpty;
  }

  void _handleContinue() {
    if (!_canContinue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select valid locations for all stops'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Get pickup and destination
    final pickup = _routeStops.first;
    final destination = _routeStops.last;

    // Get waypoints (everything between pickup and destination)
    final waypoints = _routeStops.length > 2
        ? _routeStops.sublist(1, _routeStops.length - 1)
        : null;

    Navigator.pushNamed(
      context,
      AppRoutes.rideOptions,
      arguments: RideOptionsArguments(
        from: pickup.displayName,
        to: destination.displayName,
        isScheduled: false, // Removed schedule toggle
        pickupLatLng: pickup.latLng,
        destinationLatLng: destination.latLng,
        pickupAddress: pickup.address,
        destinationAddress: destination.address,
        waypoints: waypoints,
      ),
    );
  }

  void _handleClose() {
    // Navigate to home instead of just popping
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ============================================
  // BUILD
  // ============================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            RouteHeader(onClose: _handleClose),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLarge,
              ),
              child: RouteStopsInput(
                stops: _routeStops,
                controllers: _stopControllers,
                focusNodes: _stopFocusNodes,
                onStopChanged: (stopId, query) {
                  // Handled by text controller listeners
                },
                onAddStop: _addStop,
                onRemoveStop: _removeStop,
                onMoveStopUp: _moveStopUp,
                onMoveStopDown: _moveStopDown,
                onUseCurrentLocationForPickup: _useCurrentLocation,
                canAddMoreStops: _routeStops.length < maxStops,
                maxStops: maxStops,
              ),
            ),
            Divider(
              height: 32,
              color: colorScheme.outline.withOpacity(0.2),
            ),
            Expanded(
              child: _buildContent(colorScheme),
            ),
            if (_shouldShowButton)
              ContinueButton(
                onPressed: _canContinue ? _handleContinue : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    // Show search results if actively searching
    if (_placeSuggestions.isNotEmpty) {
      return _buildPlaceSuggestions(colorScheme);
    }

    // Show loading if searching
    if (_isSearching) {
      return _buildLoading(colorScheme);
    }

    // Show default content (saved + recent)
    return _buildDefaultContent(colorScheme);
  }

  Widget _buildDefaultContent(ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      children: [
        // Saved places section
        LocationSectionHeader(title: 'Saved places'),
        const SizedBox(height: 8),

        if (_isLoadingSaved)
          const Center(child: CircularProgressIndicator())
        else if (_savedLocations.isEmpty)
          const SizedBox.shrink()
        else
          ..._savedLocations.map((location) => SavedLocationItem(
                location: location,
                onTap: () => _selectSavedLocation(location),
              )),

        const SizedBox(height: 24),

        // Recent locations section (only if user is not typing)
        if (_shouldShowRecent) ...[
          LocationSectionHeader(title: 'Recent'),
          const SizedBox(height: 8),
          if (_isLoadingRecent)
            const Center(child: CircularProgressIndicator())
          else
            ..._recentLocations.map((location) => RecentLocationItem(
                  location: location,
                  onTap: () => _selectRecentLocation(location),
                )),
        ],
      ],
    );
  }

  Widget _buildPlaceSuggestions(ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      children: [
        LocationSectionHeader(title: 'Search results'),
        const SizedBox(height: 8),
        ..._placeSuggestions.map((suggestion) => PlaceSuggestionItem(
              suggestion: suggestion,
              onTap: () => _selectPlaceSuggestion(suggestion),
            )),
      ],
    );
  }

  Widget _buildLoading(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Searching...',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
