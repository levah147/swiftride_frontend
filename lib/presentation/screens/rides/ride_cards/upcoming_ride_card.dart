// ==================== widgets/ride_cards/upcoming_ride_card.dart ====================
import 'package:flutter/material.dart';
import '../../../../constants/app_dimensions.dart';
import '../../../../models/ride.dart';

class UpcomingRideCard extends StatelessWidget {
  final Ride ride;

  const UpcomingRideCard({
    super.key,
    required this.ride,
  });

  String _getStatusText(RideStatus status) {
    switch (status) {
      case RideStatus.pending:
        return 'Finding driver...';
      case RideStatus.driverAssigned:
        return 'Driver assigned';
      case RideStatus.driverArriving:
        return 'Driver arriving';
      case RideStatus.inProgress:
        return 'Ride in progress';
      case RideStatus.completed:
        return 'Completed';
      case RideStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 Get theme colors
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingLarge),
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.schedule,
              color: colorScheme.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(ride.status),
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ride.pickupAddress} → ${ride.destinationAddress}',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.more_vert,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ],
      ),
    );
  }
}