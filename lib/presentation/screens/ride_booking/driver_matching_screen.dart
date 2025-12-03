// ==================== driver_matching_screen.dart ====================
// DRIVER MATCHING SCREEN - Refactored with WebSocket integration
// Real-time driver search and matching

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../presentation/screens/ride_booking/controllers/ride_booking_controller.dart';
import '../../../services/socket_service.dart';
import 'dart:async';

class DriverMatchingScreen extends StatefulWidget {
  final String rideId;
  final LatLng from; // ✅ FIXED: Added missing 'from' parameter

  const DriverMatchingScreen({
    super.key,
    required this.rideId,
    required this.from, // ✅ FIXED: Added as required parameter
  });

  @override
  State<DriverMatchingScreen> createState() => _DriverMatchingScreenState();
}

class _DriverMatchingScreenState extends State<DriverMatchingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  StreamSubscription? _driverMatchSubscription;
  int _searchingSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Listen to driver match stream
    _listenToDriverMatch();

    // Start timer
    _startTimer();
  }

  void _listenToDriverMatch() {
    final socketService = SocketService();

    _driverMatchSubscription = socketService.driverMatchStream.listen(
      (match) {
        debugPrint('✅ Driver matched: ${match.driverName}');

        // Navigate to tracking screen
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/ride-tracking',
            arguments: {'ride_id': widget.rideId},
          );
        }
      },
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _searchingSeconds++;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RideBookingController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // ✅ Instead of default
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Cancel button
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.close, color: colorScheme.onSurface), // ✅
                  onPressed: _showCancelDialog,
                ),
              ),

              const Spacer(),

              // Searching animation
              RotationTransition(
                turns: _animationController,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: colorScheme.primary, width: 3), // ✅
                  ),
                  child: Icon(
                    Icons.search,
                    size: 60,
                    color: colorScheme.primary, // ✅
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Status text
              Text(
                'Finding you a driver',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface, // ✅
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'Searching... ${_formatDuration(_searchingSeconds)}',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant, // ✅
                ),
              ),

              const Spacer(),

              // Ride details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface, // ✅
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (controller.selectedVehicle != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.directions_car, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            controller.selectedVehicle!.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          if (controller.estimatedFare != null)
                            Text(
                              '₦${controller.estimatedFare!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 24),
                    ],
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 20, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.pickupAddress ?? 'Pickup',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 20, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.destinationAddress ?? 'Destination',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel ride?'),
        content: const Text('Are you sure you want to cancel this ride?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              final controller = context.read<RideBookingController>();
              await controller.cancelRide('User cancelled');

              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to home
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _driverMatchSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
