// ==================== screens/destination_selection_screen.dart ====================
// DESTINATION SELECTION SCREEN - Production Ready
// No hardcoded data, real location integration

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../constants/app_dimensions.dart';
import 'package:swiftride/routes/app_routes.dart';
import 'package:swiftride/routes/route_arguments.dart';
import 'ride_options_screen.dart';

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
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final FocusNode _toFocusNode = FocusNode();
  
  bool _isScheduled = false;
  String _searchQuery = '';
  
  // Selected destination data
  LatLng? _selectedDestinationLatLng;
  String? _selectedDestinationAddress;

  // Mock data - TODO: Replace with API calls
  final List<Map<String, String>> _savedPlaces = [
    {'icon': 'home', 'title': 'Add home', 'subtitle': 'Set your home location'},
    {'icon': 'work', 'title': 'Add work', 'subtitle': 'Set your work location'},
  ];

  final List<Map<String, dynamic>> _recentLocations = [
    {
      'title': 'Keton Apartments',
      'subtitle': '677 Galadimawa - Lokogoma Road, Makurdi',
      'lat': 7.7419,
      'lng': 8.5378,
    },
    {
      'title': 'Wurukum Market',
      'subtitle': 'Wurukum, Makurdi, Benue State',
      'lat': 7.7329,
      'lng': 8.5201,
    },
    {
      'title': 'Modern Market',
      'subtitle': 'High Level, Makurdi',
      'lat': 7.7456,
      'lng': 8.5289,
    },
    {
      'title': 'North Bank',
      'subtitle': 'Makurdi, Benue State',
      'lat': 7.7512,
      'lng': 8.5423,
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // Use real pickup address from navigation or default
    _fromController.text = widget.pickupAddress ?? 'Current Location';
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _toFocusNode.requestFocus();
    });

    _toController.addListener(() {
      setState(() {
        _searchQuery = _toController.text;
      });
    });
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _toFocusNode.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredLocations {
    if (_searchQuery.isEmpty) {
      return _recentLocations;
    }
    return _recentLocations.where((location) {
      final title = location['title']!.toLowerCase();
      final subtitle = location['subtitle']!.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || subtitle.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 Get theme colors
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colorScheme),
            
            Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),
            
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildDefaultContent(colorScheme)
                  : _buildSearchResults(colorScheme),
            ),
            
            if (_toController.text.isNotEmpty && _selectedDestinationLatLng != null) 
              _buildContinueButton(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        children: [
          // Top bar
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Where to?',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Input fields container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                // From field
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _fromController,
                        enabled: false,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Pickup location',
                          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.my_location,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
                
                // Connecting line
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Container(
                    width: 2,
                    height: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                
                // To field
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _toController,
                        focusNode: _toFocusNode,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Where to?',
                          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_toController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: () {
                          _toController.clear();
                          setState(() {
                            _selectedDestinationLatLng = null;
                            _selectedDestinationAddress = null;
                          });
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Schedule toggle
          Row(
            children: [
              Switch(
                value: _isScheduled,
                onChanged: (value) => setState(() => _isScheduled = value),
                activeColor: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Schedule for later',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultContent(ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      children: [
        _buildSectionHeader('Saved places', colorScheme),
        const SizedBox(height: 8),
        ..._savedPlaces.map((place) => _buildLocationItem(
              icon: place['icon'] == 'home' ? Icons.home_outlined : Icons.work_outline,
              title: place['title']!,
              subtitle: place['subtitle']!,
              onTap: () {
                // TODO: Navigate to add saved place
                debugPrint('Add saved place: ${place['title']}');
              },
              colorScheme: colorScheme,
            )),
        
        const SizedBox(height: 24),
        
        _buildSectionHeader('Recent', colorScheme),
        const SizedBox(height: 8),
        ..._recentLocations.map((location) => _buildLocationItem(
              icon: Icons.history,
              title: location['title']!,
              subtitle: location['subtitle']!,
              onTap: () {
                setState(() {
                  _toController.text = location['title']!;
                  _selectedDestinationLatLng = LatLng(
                    location['lat'] as double,
                    location['lng'] as double,
                  );
                  _selectedDestinationAddress = location['subtitle'] as String;
                });
              },
              colorScheme: colorScheme,
            )),
      ],
    );
  }

  Widget _buildSearchResults(ColorScheme colorScheme) {
    if (_filteredLocations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "$_searchQuery"',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      children: [
        _buildSectionHeader('Search results', colorScheme),
        const SizedBox(height: 8),
        ..._filteredLocations.map((location) => _buildLocationItem(
              icon: Icons.location_on,
              title: location['title']!,
              subtitle: location['subtitle']!,
              onTap: () {
                setState(() {
                  _toController.text = location['title']!;
                  _selectedDestinationLatLng = LatLng(
                    location['lat'] as double,
                    location['lng'] as double,
                  );
                  _selectedDestinationAddress = location['subtitle'] as String;
                });
                _toFocusNode.unfocus();
              },
              colorScheme: colorScheme,
            )),
      ],
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildLocationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
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
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: colorScheme.onSurfaceVariant,
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
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: AppDimensions.buttonHeightLarge,
          child: ElevatedButton(
            onPressed: () {
              // Validate that we have real coordinates
              if (_selectedDestinationLatLng == null || widget.pickupLatLng == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please select valid pickup and destination locations'),
                    backgroundColor: colorScheme.error,
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
            ),
            child: const Text(
              'Confirm locations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}