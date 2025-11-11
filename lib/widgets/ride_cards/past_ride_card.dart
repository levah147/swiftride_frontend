
// ==================== widgets/ride_cards/past_ride_card.dart ====================
import 'package:flutter/material.dart';
import 'package:swiftride/models/ride.dart';

import '../../constants/app_dimensions.dart';

class PastRideCard extends StatelessWidget {
  final Ride ride;

  const PastRideCard({
    super.key,
    required this.ride,
  });

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final DateTime rideDate = ride.completedAt ?? ride.createdAt;
    final String formattedDate = '${rideDate.day} ${_getMonthName(rideDate.month)}';
    final String formattedTime =
        '${rideDate.hour.toString().padLeft(2, '0')}:${rideDate.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingLarge),
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              ride.status == RideStatus.completed
                  ? Icons.check_circle
                  : Icons.cancel,
              color: ride.status == RideStatus.completed
                  ? Colors.green
                  : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$formattedDate • $formattedTime',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
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
                const SizedBox(height: 4),
                Text(
                  '₦${ride.fare?.toStringAsFixed(0) ?? '0'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (ride.status == RideStatus.completed)
            Icon(
              Icons.refresh,
              color: Colors.grey[400],
              size: 20,
            ),
        ],
      ),
    );
  }
}
