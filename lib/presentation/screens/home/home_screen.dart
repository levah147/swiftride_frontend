// ==================== screens/home_screen.dart ====================
// ENHANCED HOME SCREEN - With location error handling and manual city selection
// Shows users when city detection fails

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/screens/home/controllers/home_controller.dart';
import '../../../presentation/screens/home/widgets/home_map_widget.dart';
import '../../../presentation/screens/home/widgets/search_bottom_sheet.dart';
import '../ride_booking/destination_selection/destination_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeController>(
      create: (context) {
        final controller = HomeController();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.initialize();
        });
        return controller;
      },
      builder: (context, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Map
              const HomeMapWidget(
                showUserLocation: true,
              ),

              // Top bar
              _buildTopBar(context),

              // ✅ NEW: Error banner (shows when location detection fails)
              _buildErrorBanner(context),

              // Search bottom sheet
              Consumer<HomeController>(
                builder: (context, controller, child) {
                  return SearchBottomSheet(
                    onDestinationTap: () => _navigateToDestinationSelection(context, controller),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Menu button
            IconButton(
              icon: Icon(
                Icons.menu,
                color: colorScheme.onSurface,
              ),
              onPressed: () {
                // TODO: Open drawer
              },
            ),

            const SizedBox(width: 8),

            // City name (tappable for manual selection)
            Expanded(
              child: Consumer<HomeController>(
                builder: (context, controller, child) {
                  return InkWell(
                    onTap: controller.showLocationError 
                        ? () => _showCitySelectionDialog(context, controller)
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                controller.currentCity,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: controller.showLocationError
                                      ? Colors.orange
                                      : colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (controller.showLocationError)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                              ),
                          ],
                        ),
                        if (controller.isLoadingLocation)
                          Text(
                            'Detecting location...',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          )
                        else if (controller.showLocationError)
                          Text(
                            'Tap to change city',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Notifications
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: colorScheme.onSurface,
              ),
              onPressed: () {
                // TODO: Open notifications
              },
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Error banner widget
  Widget _buildErrorBanner(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, child) {
        if (!controller.showLocationError || controller.errorMessage == null) {
          return const SizedBox.shrink();
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 80, left: 16, right: 16),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: Colors.orange.shade50,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Location Detection Issue',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            controller.errorMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      onPressed: controller.clearError,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ NEW: Manual city selection dialog
  void _showCitySelectionDialog(BuildContext context, HomeController controller) {
    // Common Nigerian cities
    final cities = [
      'Abuja', 'Lagos', 'Port Harcourt', 'Kano', 'Ibadan',
      'Kaduna', 'Benin City', 'Enugu', 'Jos', 'Ilorin',
      'Aba', 'Makurdi', 'Calabar', 'Warri', 'Maiduguri',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Your City'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: cities.length,
            itemBuilder: (context, index) {
              final city = cities[index];
              return ListTile(
                leading: Icon(
                  Icons.location_city,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(city),
                trailing: controller.currentCity == city
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  controller.setManualCity(city);
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('City changed to $city'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.refresh(); // Try auto-detect again
              Navigator.pop(context);
            },
            child: const Text('Retry Auto-Detect'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _navigateToDestinationSelection(BuildContext context, HomeController controller) {
    final pickupAddress = controller.currentPosition != null 
        ? 'Current Location' 
        : 'Set pickup location';
    
    final pickupLatLng = controller.currentLatLng;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DestinationSelectionScreen(
          pickupAddress: pickupAddress,
          pickupLatLng: pickupLatLng,
        ),
      ),
    );
  }
}