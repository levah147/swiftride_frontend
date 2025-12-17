// ==================== widgets/active_rides_section.dart ====================
// ACTIVE RIDES SECTION - Clean, modular component
// Displays currently active rides

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/driver_active_ride.dart';
import '../../../../constants/colors.dart';
import '../driver_controller.dart';
import '../driver_navigation_screen.dart';
import 'ride_card.dart';

class ActiveRidesSection extends StatelessWidget {
  final List<DriverActiveRide> rides;

  const ActiveRidesSection({
    super.key,
    required this.rides,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.drive_eta_rounded,
          title: 'Active Ride',
          hasRide: rides.isNotEmpty,
          theme: theme,
        ),
        const SizedBox(height: 16),
        _buildContent(context, theme),
      ],
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    if (rides.isEmpty) {
      return _EmptyState(
        icon: Icons.event_available_rounded,
        message: 'No active rides at the moment',
        theme: theme,
      );
    }

    return Column(
      children: rides
          .map((ride) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ActiveRideCard(ride: ride),
              ))
          .toList(),
    );
  }
}

/// Individual active ride card
class ActiveRideCard extends StatelessWidget {
  final DriverActiveRide ride;

  const ActiveRideCard({
    super.key,
    required this.ride,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.read<DriverController>();

    return RideCard(
      gradient: LinearGradient(
        colors: [
          theme.colorScheme.primary.withOpacity(0.08),
          theme.colorScheme.primary.withOpacity(0.02),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 16),
          _buildRoute(theme),
          const SizedBox(height: 16),
          _buildDetails(theme),
          const SizedBox(height: 16),
          _buildActions(context, controller),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                child: Text(
                  ride.riderName[0].toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ride.riderName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        _StatusChip(status: ride.status, theme: theme),
      ],
    );
  }

  Widget _buildRoute(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              Container(
                width: 2,
                height: 30,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride.pickupLocation,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  ride.destinationLocation,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _DetailItem(
            icon: Icons.payments_rounded,
            label: 'Fare',
            value: ride.formattedFare,
            theme: theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DetailItem(
            icon: Icons.route_rounded,
            label: 'Distance',
            value: ride.formattedDistance,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, DriverController controller) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _navigateToMap(context, controller),
            style: ElevatedButton.styleFrom(
              // backgroundColor: theme.colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.primary,

              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.navigation_rounded, size: 20),
            label: const Text(
              'Navigate',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleStartRide(context, controller),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.play_circle_rounded, size: 20),
            label: const Text(
              'Start',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToMap(BuildContext context, DriverController controller) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DriverNavigationScreen(
          ride: ride,
          onArrived: () => _handleArrived(context, controller),
          onStart: () => _handleStartRide(context, controller),
          onComplete: () => _handleComplete(context, controller),
        ),
      ),
    );
  }

  Future<void> _handleArrived(
    BuildContext context,
    DriverController controller,
  ) async {
    // Mark as arrived logic
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.white),
            SizedBox(width: 12),
            Text('Marked as arrived'),
          ],
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _handleStartRide(
    BuildContext context,
    DriverController controller,
  ) async {
    final success = await controller.startRide(ride.id);
    
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(success ? 'Ride started!' : 'Unable to start ride'),
          ],
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _handleComplete(
    BuildContext context,
    DriverController controller,
  ) async {
    final success = await controller.completeRide(ride.id);
    
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(success ? 'Ride completed!' : 'Unable to complete ride'),
          ],
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

/// Section header
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool hasRide;
  final ThemeData theme;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.hasRide,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (hasRide) ...[
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Status chip
class _StatusChip extends StatelessWidget {
  final String status;
  final ThemeData theme;

  const _StatusChip({
    required this.status,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'in_progress':
        color = AppColors.info;
        break;
      case 'arrived':
        color = AppColors.warning;
        break;
      default:
        color = theme.colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Detail item
class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final ThemeData theme;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}