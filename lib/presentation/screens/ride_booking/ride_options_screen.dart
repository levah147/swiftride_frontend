// ==================== screens/ride_options_screen.dart ====================
// RIDE OPTIONS SCREEN - Production Ready
// No hardcoded data, real location integration
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:swiftride/routes/app_routes.dart';
import 'package:swiftride/routes/route_arguments.dart';
import '../../../../../constants/app_dimensions.dart';
import '../../../../../models/vehicle_type.dart';
import '../../../presentation/screens/ride_booking/controllers/ride_booking_controller.dart';
import '../../../../../services/auth_service.dart';
import 'driver_matching_screen.dart';

class RideOptionsScreen extends StatefulWidget {
  final String from;
  final String to;
  final bool isScheduled;
  final LatLng pickupLatLng;
  final LatLng destinationLatLng;
  final String pickupAddress;
  final String destinationAddress;
  final String? city;

  const RideOptionsScreen({
    super.key,
    required this.from,
    required this.to,
    required this.isScheduled,
    required this.pickupLatLng,
    required this.destinationLatLng,
    required this.pickupAddress,
    required this.destinationAddress,
    this.city,
  });

  @override
  State<RideOptionsScreen> createState() => _RideOptionsScreenState();
}

class _RideOptionsScreenState extends State<RideOptionsScreen> {
  int _selectedIndex = 0;
  late List<VehicleType> _availableVehicles;
  double? _estimatedDistance;
  bool _isLoadingFare = false;
  bool _isBooking = false;
  String _paymentMethod = 'cash'; // 'cash' or 'wallet'

  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _loadAvailableVehicles();
    _calculateDistance();
  }

  void _loadAvailableVehicles() {
    final city = widget.city ?? 'Makurdi';
    setState(() {
      _availableVehicles = VehicleTypes.getVehiclesForCity(city);
    });
  }

  /// Calculate distance between pickup and destination
  void _calculateDistance() {
    setState(() => _isLoadingFare = true);

    // Calculate straight-line distance using Haversine formula
    // In production, you should use Google Directions API for accurate road distance
    final distance = _calculateHaversineDistance(
      widget.pickupLatLng.latitude,
      widget.pickupLatLng.longitude,
      widget.destinationLatLng.latitude,
      widget.destinationLatLng.longitude,
    );

    setState(() {
      _estimatedDistance = distance;
      _isLoadingFare = false;
    });

    debugPrint('📏 Calculated distance: ${distance.toStringAsFixed(2)} km');
  }

  /// Haversine formula to calculate distance between two coordinates
  double _calculateHaversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2));

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Choose a ride',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildRouteSummary(colorScheme),
          const SizedBox(height: 16),
          if (_estimatedDistance != null) _buildTripInfo(colorScheme),
          const SizedBox(height: 24),
          Expanded(
            child: _buildVehicleList(colorScheme),
          ),
          if (_estimatedDistance != null) _buildBookButton(colorScheme),
        ],
      ),
    );
  }

  Widget _buildRouteSummary(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingLarge),
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 30,
                color: colorScheme.onSurfaceVariant,
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  shape: BoxShape.circle,
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
                  widget.from,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.to,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (widget.isScheduled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule,
                    color: colorScheme.primary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Scheduled',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTripInfo(ColorScheme colorScheme) {
    final estimatedTime =
        (_estimatedDistance! * 3).toInt(); // Rough estimate: 3 min per km

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
      child: Row(
        children: [
          _buildInfoChip(
            icon: Icons.straighten,
            label: '${_estimatedDistance!.toStringAsFixed(1)} km',
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 12),
          _buildInfoChip(
            icon: Icons.access_time,
            label: '$estimatedTime min',
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleList(ColorScheme colorScheme) {
    if (_isLoadingFare || _estimatedDistance == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Calculating fares...',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding:
          const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
      itemCount: _availableVehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _availableVehicles[index];
        final isSelected = _selectedIndex == index;
        final fare = vehicle.calculateFare(_estimatedDistance!);

        return GestureDetector(
          onTap: () => setState(() => _selectedIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? vehicle.color.withOpacity(0.1)
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? vehicle.color
                    : colorScheme.outline.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: vehicle.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    vehicle.icon,
                    color: vehicle.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            vehicle.name,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: vehicle.color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'SELECTED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${vehicle.description} • ${vehicle.estimatedTime}',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      vehicle.formatPrice(fare),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: vehicle.color,
                        size: 20,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookButton(ColorScheme colorScheme) {
    final selectedVehicle = _availableVehicles[_selectedIndex];
    final fare = selectedVehicle.calculateFare(_estimatedDistance!);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _showPaymentMethodSheet(colorScheme),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: colorScheme.outline.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _paymentMethod == 'cash'
                          ? Icons.money
                          : Icons.account_balance_wallet,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _paymentMethod == 'cash' ? 'Cash' : 'Wallet',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonHeightLarge,
              child: ElevatedButton(
                onPressed: _isBooking
                    ? null
                    : () => _handleBookRide(selectedVehicle, fare),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedVehicle.color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  disabledBackgroundColor:
                      selectedVehicle.color.withOpacity(0.5),
                ),
                child: _isBooking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.isScheduled
                                ? 'Schedule ${selectedVehicle.name}'
                                : 'Book ${selectedVehicle.name}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${selectedVehicle.formatPrice(fare)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle ride booking with real location data
  Future<void> _handleBookRide(VehicleType selectedVehicle, double fare) async {
    setState(() => _isBooking = true);

    try {
      final controller = context.read<RideBookingController>();

      // Get authenticated user
      final userResponse = await _authService.getCurrentUser();
      if (!userResponse.isSuccess || userResponse.data == null) {
        throw Exception('Please login to book a ride');
      }
      final user = userResponse.data!;

      // Set pickup location in controller with real coordinates
      await controller.setPickupLocation(
        widget.pickupLatLng,
        widget.pickupAddress,
      );

      // Set destination in controller with real coordinates
      await controller.setDestinationLocation(
        widget.destinationLatLng,
        widget.destinationAddress,
      );

      // Set selected vehicle
      await controller.selectVehicle(selectedVehicle);

      debugPrint('📱 Booking ride:');
      debugPrint('   User: ${user.id}');
      debugPrint(
          '   From: ${widget.pickupAddress} (${widget.pickupLatLng.latitude}, ${widget.pickupLatLng.longitude})');
      debugPrint(
          '   To: ${widget.destinationAddress} (${widget.destinationLatLng.latitude}, ${widget.destinationLatLng.longitude})');
      debugPrint('   Vehicle: ${selectedVehicle.name}');
      debugPrint('   Distance: ${_estimatedDistance!.toStringAsFixed(2)} km');
      debugPrint('   Fare: ${selectedVehicle.formatPrice(fare)}');

      // Book the ride
      final success = await controller.bookRide(user.id);

      if (!success) {
        throw Exception(controller.error ?? 'Failed to book ride');
      }

      // Verify ride was created
      if (controller.activeRide == null) {
        throw Exception('Ride created but no ride ID returned');
      }

      debugPrint('✅ Ride booked successfully: ${controller.activeRide!.id}');

      // Navigate to driver matching screen
      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.driverMatching,
          arguments: DriverMatchingArguments(
            rideId: controller.activeRide!.id,
            from: widget.pickupLatLng,
            to: widget.destinationAddress,
            rideType: {
              'id': selectedVehicle.id,
              'name': selectedVehicle.name,
              'price': selectedVehicle.formatPrice(fare),
              'icon': selectedVehicle.icon.codePoint,
              'color': selectedVehicle.color.value,
            },
            isScheduled: widget.isScheduled,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Booking error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  /// Show payment method selection bottom sheet
  void _showPaymentMethodSheet(ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select payment method',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Cash option
              _buildPaymentOption(
                icon: Icons.money,
                title: 'Cash',
                subtitle: 'Pay with cash after the ride',
                value: 'cash',
                colorScheme: colorScheme,
              ),

              const SizedBox(height: 12),

              // Wallet option
              _buildPaymentOption(
                icon: Icons.account_balance_wallet,
                title: 'Wallet',
                subtitle: 'Pay from your wallet balance',
                value: 'wallet',
                colorScheme: colorScheme,
                badge: 'Coming soon',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required ColorScheme colorScheme,
    String? badge,
  }) {
    final isSelected = _paymentMethod == value;
    final hasComingSoon = badge != null;

    return GestureDetector(
      onTap: hasComingSoon
          ? null
          : () {
              setState(() => _paymentMethod = value);
              Navigator.pop(context);
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? colorScheme.primaryContainer : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: colorScheme.onSecondaryContainer,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

// Add this import at the top if not already present
