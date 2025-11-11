import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/app_dimensions.dart';
import 'ride_options_screen.dart';

class DestinationSelectionScreen extends StatefulWidget {
  const DestinationSelectionScreen({super.key});

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

  // Mock data - TODO: Replace with API calls
  final List<Map<String, String>> _savedPlaces = [
    {'icon': 'home', 'title': 'Add home', 'subtitle': 'Set your home location'},
    {'icon': 'work', 'title': 'Add work', 'subtitle': 'Set your work location'},
  ];

  final List<Map<String, String>> _recentLocations = [
    {
      'title': 'Keton Apartments',
      'subtitle': '677 Galadimawa - Lokogoma Road, Makurdi',
    },
    {
      'title': 'Wurukum Market',
      'subtitle': 'Wurukum, Makurdi, Benue State',
    },
    {
      'title': 'Modern Market',
      'subtitle': 'High Level, Makurdi',
    },
    {
      'title': 'North Bank',
      'subtitle': 'Makurdi, Benue State',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fromController.text = 'Current Location';
    
    // Auto-focus destination field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _toFocusNode.requestFocus();
    });

    // Listen to destination changes for search
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

  List<Map<String, String>> get _filteredLocations {
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
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Header with input fields
            _buildHeader(),
            
            // Divider
            Container(
              height: 1,
              color: AppColors.divider,
            ),
            
            // Content
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildDefaultContent()
                  : _buildSearchResults(),
            ),
            
            // Continue button (if destination is selected)
            if (_toController.text.isNotEmpty) _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        children: [
          // Top bar
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Where to?',
                  style: TextStyle(
                    color: AppColors.textPrimary,
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
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
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
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _fromController,
                        enabled: false,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Pickup location',
                          hintStyle: TextStyle(color: AppColors.textHint),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.my_location,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      onPressed: () {
                        // TODO: Get current location
                      },
                    ),
                  ],
                ),
                
                // Connecting line
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Container(
                    width: 2,
                    height: 20,
                    color: AppColors.grey600,
                  ),
                ),
                
                // To field
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _toController,
                        focusNode: _toFocusNode,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Where to?',
                          hintStyle: TextStyle(color: AppColors.textHint),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_toController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () {
                          _toController.clear();
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
                onChanged: (value) {
                  setState(() => _isScheduled = value);
                },
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: 12),
              const Text(
                'Schedule for later',
                style: TextStyle(
                  color: AppColors.textPrimary,
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

  Widget _buildDefaultContent() {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      children: [
        // Saved places
        _buildSectionHeader('Saved places'),
        const SizedBox(height: 8),
        ..._savedPlaces.map((place) => _buildLocationItem(
              icon: place['icon'] == 'home' ? Icons.home_outlined : Icons.work_outline,
              title: place['title']!,
              subtitle: place['subtitle']!,
              onTap: () {
                // TODO: Navigate to add saved place
              },
            )),
        
        const SizedBox(height: 24),
        
        // Recent locations
        _buildSectionHeader('Recent'),
        const SizedBox(height: 8),
        ..._recentLocations.map((location) => _buildLocationItem(
              icon: Icons.history,
              title: location['title']!,
              subtitle: location['subtitle']!,
              onTap: () {
                setState(() {
                  _toController.text = location['title']!;
                });
              },
            )),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_filteredLocations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "$_searchQuery"',
              style: const TextStyle(
                color: AppColors.textSecondary,
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
        _buildSectionHeader('Search results'),
        const SizedBox(height: 8),
        ..._filteredLocations.map((location) => _buildLocationItem(
              icon: Icons.location_on,
              title: location['title']!,
              subtitle: location['subtitle']!,
              onTap: () {
                setState(() {
                  _toController.text = location['title']!;
                });
                _toFocusNode.unfocus();
              },
            )),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textSecondary,
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
              ),
              child: Icon(
                icon,
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
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RideOptionsScreen(
                    from: _fromController.text,
                    to: _toController.text,
                    isScheduled: _isScheduled,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
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