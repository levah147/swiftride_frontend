// ==================== widgets/rides_list.dart ====================
import 'package:flutter/material.dart';
import '../../../../constants/app_dimensions.dart';
import '../../../../models/ride.dart';
import '../../rides/ride_cards/past_ride_card.dart';
import '../../rides/ride_cards/upcoming_ride_card.dart';

class RidesList extends StatelessWidget {
  final List<Ride> rides;
  final bool isUpcoming;
  final Future<void> Function() onRefresh;

  const RidesList({
    super.key,
    required this.rides,
    required this.isUpcoming,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // 🎨 Get theme colors
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        itemCount: rides.length,
        itemBuilder: (context, index) => _buildRideCard(rides[index]),
      ),
    );
  }

  Widget _buildRideCard(Ride ride) {
    return isUpcoming
        ? UpcomingRideCard(ride: ride)
        : PastRideCard(ride: ride);
  }
}