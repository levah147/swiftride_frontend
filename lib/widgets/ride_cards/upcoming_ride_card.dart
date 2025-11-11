// ==================== widgets/ride_cards/upcoming_ride_card.dart ====================
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/app_dimensions.dart';
import '../../models/ride.dart';

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
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingLarge),
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.schedule,
              color: Colors.white,
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
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ride.pickupAddress} → ${ride.destinationAddress}',
                  style: const TextStyle(
                    color: Colors.white,
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
            color: Colors.grey[400],
            size: 20,
          ),
        ],
      ),
    );
  }
}
