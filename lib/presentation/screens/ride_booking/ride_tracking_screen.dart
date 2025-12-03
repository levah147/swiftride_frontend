// ==================== ride_tracking_screen.dart ====================
// RIDE TRACKING SCREEN - Refactored with live GPS tracking
// Real-time driver location updates via WebSocket

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../presentation/screens/ride_booking/controllers/ride_booking_controller.dart';
import '../../../services/socket_service.dart';
import '../../../presentation/screens/ride_booking/widgets/driver_card_widget.dart';
import '../../../models/ride.dart';
import 'dart:async';

class RideTrackingScreen extends StatefulWidget {
  final String rideId;

  const RideTrackingScreen({
    super.key,
    required this.rideId,
  });

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  GoogleMapController? _mapController;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _statusSubscription;
  
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _driverLocation;
  int? _eta;

  @override
  void initState() {
    super.initState();
    _listenToDriverLocation();
    _listenToRideStatus();
  }

  void _listenToDriverLocation() {
    final socketService = SocketService();
    
    _locationSubscription = socketService.driverLocationStream.listen(
      (update) {
        debugPrint('📍 Driver location update: ${update.location}');
        
        if (mounted) {
          setState(() {
            _driverLocation = update.location;
            _updateDriverMarker(update.location);
          });

          // Animate camera to follow driver
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(update.location),
          );
        }
      },
    );
  }

  void _listenToRideStatus() {
    final socketService = SocketService();
    
    _statusSubscription = socketService.rideStatusStream.listen(
      (update) {
        debugPrint('📡 Ride status: ${update.status}');
        
        if (update.status == 'completed') {
          // Navigate to completion screen
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/ride-completion',
              arguments: {'ride_id': widget.rideId},
            );
          }
        }
      },
    );
  }

  void _updateDriverMarker(LatLng location) {
    _markers.removeWhere((m) => m.markerId.value == 'driver');
    
    _markers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Driver'),
        rotation: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RideBookingController>();
    final ride = controller.activeRide;

    if (ride == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _driverLocation ?? 
                     LatLng(ride.pickupLatitude, ride.pickupLongitude),
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Driver card
          if (ride.driver != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 100,
              child: DriverCardWidget(
                driver: ride.driver!,
                eta: _eta,
                onCallTap: () => _callDriver(ride.driver!.phoneNumber),  // ✅ CORRECT
                onMessageTap: () => _messageDriver(),
              ),
            ),

          // Status banner
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: _buildStatusBanner(ride.status),
              ),
            ),
          ),

          // Cancel button
          Positioned(
            left: 16,
            bottom: 20,
            child: FloatingActionButton(
              heroTag: 'cancel',
              backgroundColor: Colors.white,
              onPressed: _showCancelDialog,
              child: const Icon(Icons.close, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: Changed parameter type from String to RideStatus enum
  Widget _buildStatusBanner(RideStatus status) {
    IconData icon;
    String message;
    Color color;

    // ✅ FIXED: Use enum cases instead of string matching
    switch (status) {
      case RideStatus.pending:
        icon = Icons.search;
        message = 'Finding driver...';
        color = Colors.orange;
        break;
      case RideStatus.driverAssigned:
        icon = Icons.check_circle;
        message = 'Driver assigned';
        color = Colors.blue;
        break;
      case RideStatus.driverArriving:
        icon = Icons.location_on;
        message = 'Driver arriving';
        color = Colors.blue;
        break;
      case RideStatus.inProgress:
        icon = Icons.directions_car;
        message = 'Ride in progress';
        color = Colors.green;
        break;
      case RideStatus.completed:
        icon = Icons.check_circle;
        message = 'Ride completed';
        color = Colors.teal;
        break;
      case RideStatus.cancelled:
        icon = Icons.cancel;
        message = 'Ride cancelled';
        color = Colors.red;
        break;
    }

    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _callDriver(String phone) {
    // TODO: Implement call functionality
    debugPrint('Calling driver: $phone');
  }

  void _messageDriver() {
    // TODO: Implement messaging
    debugPrint('Messaging driver');
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel ride?'),
        content: const Text('Are you sure you want to cancel?'),
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
                Navigator.pop(context); // Go back
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _locationSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }
}