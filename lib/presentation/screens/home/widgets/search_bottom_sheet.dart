// ==================== widgets/search_bottom_sheet.dart ====================
// SEARCH BOTTOM SHEET - Draggable destination search UI
// Bolt-style draggable sheet with search and quick actions

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../screens/home/controllers/home_controller.dart';
import 'vehicle_selector_widget.dart';
import 'quick_destinations_widget.dart';
import 'recent_locations_widget.dart';

class SearchBottomSheet extends StatefulWidget {
  final VoidCallback onDestinationTap;
  final Function(String)? onSearchChanged;

  const SearchBottomSheet({
    super.key,
    required this.onDestinationTap,
    this.onSearchChanged,
  });

  @override
  State<SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<SearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();
    
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: const [0.4, 0.9],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // City name
              if (controller.currentCity.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_city,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        controller.currentCity,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Search field
              _buildSearchField(),
              
              const SizedBox(height: 20),

              // Quick destinations (Home/Work)
              QuickDestinationsWidget(
                homeAddress: controller.homeAddress,
                workAddress: controller.workAddress,
                onHomeTap: () => _handleQuickDestination('home'),
                onWorkTap: () => _handleQuickDestination('work'),
              ),

              const SizedBox(height: 24),

              // Vehicle selector
              if (controller.availableVehicles.isNotEmpty) ...[
                Text(
                  'Choose a ride',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                VehicleSelectorWidget(
                  vehicles: controller.availableVehicles,
                  selectedVehicle: controller.selectedVehicle,
                  onVehicleSelected: controller.selectVehicle,
                  isLoading: controller.isLoadingVehicles,
                ),
                const SizedBox(height: 24),
              ],

              // Recent locations
              RecentLocationsWidget(
                recentLocations: controller.recentLocations,
                onLocationTap: _handleRecentLocation,
                isLoading: controller.isLoadingRecent,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchField() {
    return GestureDetector(
      onTap: widget.onDestinationTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey[600], size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Where to?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Now',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey[700]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleQuickDestination(String type) {
    // TODO: Implement quick destination navigation
    debugPrint('Quick destination: $type');
  }

  void _handleRecentLocation(String locationId) {
    // TODO: Implement recent location selection
    debugPrint('Recent location: $locationId');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sheetController.dispose();
    super.dispose();
  }
}