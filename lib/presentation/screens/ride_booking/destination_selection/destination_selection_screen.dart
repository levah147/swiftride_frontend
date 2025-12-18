// ==================== destination_selection_screen.dart ====================
// MAIN SCREEN - Clean, focused, delegates to components

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../constants/app_dimensions.dart';
import 'package:swiftride/routes/app_routes.dart';
import 'package:swiftride/routes/route_arguments.dart';
import '../../../../services/location_service.dart';
import '../../../../services/geocoding_service.dart';
import '../../../../models/location.dart';
import 'widgets/destination_header.dart';
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
  // Controllers & Focus
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final FocusNode _toFocusNode = FocusNode();

  // Services
  final LocationService _locationService = LocationService();
  final GeocodingService _geocodingService = GeocodingService();

  // State
  bool _isScheduled = false;
  String _searchQuery = '';
  bool _isLoadingSaved = false;
  bool _isLoadingRecent = false;
  bool _isSearching = false;

  // Data
  List<SavedLocation> _savedLocations = [];
  List<RecentLocation> _recentLocations = [];
  List<PlaceSuggestion> _placeSuggestions = [];

  // Selected destination
  LatLng? _selectedDestinationLatLng;
  String? _selectedDestinationAddress;

  @override
  void initState() {
    super.initState();
    _fromController.text = widget.pickupAddress ?? 'Current Location';
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _toFocusNode.requestFocus();
      _loadSavedAndRecentLocations();
    });

    _toController.addListener(_onSearchQueryChanged);
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _toFocusNode.dispose();
    super.dispose();
  }

  // ============================================
  // SEARCH & QUERY HANDLING
  // ============================================

  void _onSearchQueryChanged() {
    final query = _toController.text;
    setState(() => _searchQuery = query);

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

  // ============================================
  // SELECTION HANDLERS
  // ============================================

  Future<void> _selectPlaceSuggestion(PlaceSuggestion suggestion) async {
    final details = await _geocodingService.getPlaceDetails(suggestion.placeId);

    if (details == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get place details')),
        );
      }
      return;
    }

    setState(() {
      _toController.text = details.name;
      _selectedDestinationLatLng = LatLng(
        details.location.latitude,
        details.location.longitude,
      );
      _selectedDestinationAddress = details.formattedAddress;
      _placeSuggestions = [];
    });

    _toFocusNode.unfocus();
    await _saveRecentLocation(
      address: details.formattedAddress,
      latitude: details.location.latitude,
      longitude: details.location.longitude,
    );
  }

  Future<void> _selectSavedLocation(SavedLocation location) async {
    setState(() {
      _toController.text = location.displayName;
      _selectedDestinationLatLng = LatLng(location.latitude, location.longitude);
      _selectedDestinationAddress = location.address;
    });

    _toFocusNode.unfocus();
    await _saveRecentLocation(
      address: location.address,
      latitude: location.latitude,
      longitude: location.longitude,
    );
  }

  Future<void> _selectRecentLocation(RecentLocation location) async {
    setState(() {
      _toController.text = location.placeName;
      _selectedDestinationLatLng = LatLng(location.latitude, location.longitude);
      _selectedDestinationAddress = location.address;
    });

    _toFocusNode.unfocus();
    await _saveRecentLocation(
      address: location.address,
      latitude: location.latitude,
      longitude: location.longitude,
    );
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

  Future<void> _addSavedPlace(String type) async {
    if (_selectedDestinationLatLng == null || _selectedDestinationAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination first')),
      );
      return;
    }

    final existing = _savedLocations.firstWhere(
      (loc) => loc.locationType == type,
      orElse: () => SavedLocation(
        id: '',
        locationType: '',
        locationTypeDisplay: '',
        address: '',
        latitude: 0,
        longitude: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (existing.id.isNotEmpty) {
      final response = await _locationService.updateSavedLocation(
        locationId: existing.id,
        address: _selectedDestinationAddress!,
        latitude: _selectedDestinationLatLng!.latitude,
        longitude: _selectedDestinationLatLng!.longitude,
      );

      if (response.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${type == 'home' ? 'Home' : 'Work'} location updated')),
        );
        _loadSavedAndRecentLocations();
      }
    } else {
      final response = await _locationService.addSavedLocation(
        type: type,
        address: _selectedDestinationAddress!,
        latitude: _selectedDestinationLatLng!.latitude,
        longitude: _selectedDestinationLatLng!.longitude,
      );

      if (response.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${type == 'home' ? 'Home' : 'Work'} location saved')),
        );
        _loadSavedAndRecentLocations();
      }
    }
  }

  void _handleClearDestination() {
    _toController.clear();
    setState(() {
      _selectedDestinationLatLng = null;
      _selectedDestinationAddress = null;
    });
  }

  void _handleContinue() {
    if (_selectedDestinationLatLng == null || widget.pickupLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select valid pickup and destination locations'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.rideOptions,
      arguments: RideOptionsArguments(
        from: _fromController.text,
        to: _toController.text,
        isScheduled: _isScheduled,
        pickupLatLng: widget.pickupLatLng!,
        destinationLatLng: _selectedDestinationLatLng!,
        pickupAddress: widget.pickupAddress ?? _fromController.text,
        destinationAddress: _selectedDestinationAddress ?? _toController.text,
      ),
    );
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
            DestinationHeader(
              fromController: _fromController,
              toController: _toController,
              toFocusNode: _toFocusNode,
              isScheduled: _isScheduled,
              onScheduledChanged: (value) => setState(() => _isScheduled = value),
              onBack: () => Navigator.pop(context),
              onClearDestination: _handleClearDestination,
            ),
            Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),
            Expanded(
              child: _buildContent(colorScheme),
            ),
            if (_toController.text.isNotEmpty && _selectedDestinationLatLng != null)
              ContinueButton(onPressed: _handleContinue),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    if (_searchQuery.isNotEmpty && _placeSuggestions.isNotEmpty) {
      return _buildPlaceSuggestions(colorScheme);
    }
    
    if (_searchQuery.isNotEmpty && _isSearching) {
      return _buildLoading(colorScheme);
    }
    
    return _buildDefaultContent(colorScheme);
  }

  Widget _buildDefaultContent(ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      children: [
        LocationSectionHeader(title: 'Saved places'),
        const SizedBox(height: 8),
        
        if (_isLoadingSaved)
          const Center(child: CircularProgressIndicator())
        else if (_savedLocations.isEmpty)
          AddSavedPlaceItem(type: 'home', onTap: () => _addSavedPlace('home'))
        else
          ..._savedLocations.map((location) => SavedLocationItem(
            location: location,
            onTap: () => _selectSavedLocation(location),
          )),

        if (!_savedLocations.any((loc) => loc.locationType == 'work'))
          AddSavedPlaceItem(type: 'work', onTap: () => _addSavedPlace('work')),

        const SizedBox(height: 24),
        LocationSectionHeader(title: 'Recent'),
        const SizedBox(height: 8),
        
        if (_isLoadingRecent)
          const Center(child: CircularProgressIndicator())
        else if (_recentLocations.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'No recent locations',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          )
        else
          ..._recentLocations.map((location) => RecentLocationItem(
            location: location,
            onTap: () => _selectRecentLocation(location),
          )),
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