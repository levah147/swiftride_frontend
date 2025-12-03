// ==================== screens/home_screen.dart ====================
// HOME SCREEN - Theme-aware version
// Main entry point for ride booking

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/screens/home/controllers/home_controller.dart';
import '../../../presentation/screens/home/widgets/home_map_widget.dart';
import '../../../presentation/screens/home/widgets/search_bottom_sheet.dart';
import '../ride_booking/destination_selection_screen.dart';

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

              // Search bottom sheet
              SearchBottomSheet(
                onDestinationTap: _navigateToDestinationSelection,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    // 🎨 Get theme colors
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

            // City name
            Expanded(
              child: Consumer<HomeController>(
                builder: (context, controller, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller.currentCity,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (controller.isLoadingLocation)
                        Text(
                          'Detecting location...',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
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

  void _navigateToDestinationSelection() {
    final controller = context.read<HomeController>();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DestinationSelectionScreen(),
      ),
    );
  }
}