// ==================== driver_rides_screen.dart ====================
// MAIN DRIVER RIDES SCREEN - Production Architecture
// Clean, modular, theme-aware design

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controller/driver_controller.dart';
import 'widgets/driver_app_bar.dart';
import 'widgets/driver_status_banner.dart';
import 'widgets/available_rides_section.dart';
import 'widgets/active_rides_section.dart';
import 'widgets/driver_fab.dart';

/// Main driver rides screen with clean architecture
/// Follows Flutter's recommended UI/ViewModel pattern
class DriverRidesScreen extends StatelessWidget {
  const DriverRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DriverController()..refreshRides(),
      child: const _DriverRidesView(),
    );
  }
}

/// Private view that consumes the controller
/// Separates presentation from business logic
class _DriverRidesView extends StatelessWidget {
  const _DriverRidesView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DriverController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: DriverAppBar(
        isOnline: controller.isOnline,
        isToggling: controller.isToggling,
        onToggle: controller.toggleAvailability,
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshRides,
        color: theme.colorScheme.primary,
        child: _buildBody(context, controller, theme),
      ),
      floatingActionButton: DriverFab(
        isOnline: controller.isOnline,
        onRefresh: controller.refreshRides,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    DriverController controller,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          DriverStatusBanner(
            isOnline: controller.isOnline,
            isLoading: controller.isLoadingRides,
          ),
          
          const SizedBox(height: 20),
          
          // Error message if any
          if (controller.error != null)
            _ErrorBanner(message: controller.error!),
          
          // Content based on online status
          if (controller.isOnline) ...[
            const SizedBox(height: 16),
            
            // Available rides section
            AvailableRidesSection(
              rides: controller.availableRides,
              isLoading: controller.isLoadingRides,
            ),
            
            const SizedBox(height: 32),
            
            // Active rides section
            ActiveRidesSection(
              rides: controller.activeRides,
            ),
          ] else
            _OfflinePrompt(theme: theme),
        ],
      ),
    );
  }
}

/// Error banner widget
class _ErrorBanner extends StatelessWidget {
  final String message;
  
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Offline prompt widget
class _OfflinePrompt extends StatelessWidget {
  final ThemeData theme;
  
  const _OfflinePrompt({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.power_settings_new,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'You\'re Offline',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Go online to start receiving ride requests',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}