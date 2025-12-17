// ==================== ride_tracking_screen.dart ====================
// RIDE TRACKING SCREEN - Complete with initial data loading + WebSocket
// Real-time driver location updates via WebSocket

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../presentation/screens/ride_booking/controllers/ride_booking_controller.dart';
import '../../../services/socket_service.dart';
import '../../../services/ride_service.dart';
import '../../../presentation/screens/ride_booking/widgets/driver_card_widget.dart';
import '../../../models/ride.dart';
import 'dart:async';
import 'dart:math';

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
  // Services
  final _rideService = RideService();
  final _socketService = SocketService();
  final _socketAuthProvider = SocketAuthProvider();
  
  // Map
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  // Subscriptions
  StreamSubscription? _locationSubscription;
  StreamSubscription? _statusSubscription;
  
  // State
  bool _isLoading = true;
  Ride? _currentRide;
  LatLng? _driverLocation;
  int? _eta;
  
  // Driver info (extracted from ride)
  String _driverName = '';
  String _driverPhone = '';
  double _driverRating = 0.0;
  String _vehicleInfo = '';
  String? _licensePlate;

  @override
  void initState() {
    super.initState();
    
    // ✅ STEP 1: Load initial ride data FIRST
    _loadInitialRideData();
  }

  // ✅ NEW METHOD: Load ride details from backend
  Future<void> _loadInitialRideData() async {
    try {
      setState(() => _isLoading = true);

      debugPrint('📱 Loading initial ride data for: ${widget.rideId}');

      // ✅ STEP 1: Fetch ride details from backend
      final response = await _rideService.getRideDetails(widget.rideId);
      
      if (!response.isSuccess || response.data == null) {
        _showError('Failed to load ride details');
        setState(() => _isLoading = false);
        return;
      }

      final ride = response.data!;
      debugPrint('✅ Ride loaded: ${ride.id}');
      debugPrint('   - Status: ${ride.status.displayName}');
      
      // ✅ STEP 2: Update UI with ride data
      setState(() {
        _currentRide = ride;
        
        // Extract driver info if already assigned
        if (ride.driver != null) {
          _driverName = ride.driver!.name;
          _driverPhone = ride.driver!.phoneNumber;
          _driverRating = ride.driver!.rating;
          _vehicleInfo = '${ride.driver!.vehicleColor} ${ride.driver!.vehicleModel}';
          _licensePlate = ride.driver!.licensePlate;
          
          debugPrint('✅ Driver info loaded: $_driverName');
        }
        
        // Set initial map markers
        _markers = _buildInitialMarkers(ride);
        
        _isLoading = false;
      });

      // ✅ STEP 3: Connect to WebSocket for real-time updates
      await _connectToWebSocket();

      // ✅ STEP 4: Setup listeners AFTER connection
      _listenToDriverLocation();
      _listenToRideStatus();

      // ✅ STEP 5: Fit map to show route
      await Future.delayed(const Duration(milliseconds: 500));
      _fitMapToRoute();
      
    } catch (e) {
      debugPrint('❌ Error loading ride data: $e');
      _showError('Failed to load ride details: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  // ✅ NEW METHOD: Connect to WebSocket
  Future<void> _connectToWebSocket() async {
    try {
      debugPrint('🔌 Connecting to WebSocket...');
      
      final token = await _socketAuthProvider.getToken();
      if (token == null) {
        debugPrint('❌ Cannot connect: missing auth token');
        _showError('Authentication required');
        return;
      }

      await _socketService.connectToRide(widget.rideId, token);
      debugPrint('✅ Connected to WebSocket for ride: ${widget.rideId}');
      
    } catch (e) {
      debugPrint('❌ WebSocket connection error: $e');
      _showError('Could not connect to real-time updates');
    }
  }

  // ✅ UPDATED: Listen to driver location
  void _listenToDriverLocation() {
    _locationSubscription = _socketService.driverLocationStream.listen(
      (update) {
        debugPrint('📍 Driver location update: ${update.location.latitude}, ${update.location.longitude}');
        
        if (mounted) {
          setState(() {
            _driverLocation = update.location;
            _updateDriverMarker(update.location, update.heading);
          });

          // Animate camera to follow driver (smooth)
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(update.location),
          );
        }
      },
      onError: (error) {
        debugPrint('❌ Location stream error: $error');
      },
    );
  }

  // ✅ UPDATED: Listen to ride status
  void _listenToRideStatus() {
    _statusSubscription = _socketService.rideStatusStream.listen(
      (update) {
        debugPrint('📡 Ride status update: ${update.status}');
        
        if (mounted) {
          // Update ride status
          if (_currentRide != null) {
            setState(() {
              _currentRide = _currentRide!.copyWith(
                status: RideStatus.fromString(update.status),
              );
            });
          }

          // Handle completion
          if (update.status == 'completed') {
            Navigator.pushReplacementNamed(
              context,
              '/ride-completion',
              arguments: {'ride_id': widget.rideId},
            );
          }
        }
      },
      onError: (error) {
        debugPrint('❌ Status stream error: $error');
      },
    );
  }

  // ✅ NEW METHOD: Build initial markers
  Set<Marker> _buildInitialMarkers(Ride ride) {
    final markers = <Marker>{};
    
    // Pickup marker (Green)
    markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(ride.pickupLatitude, ride.pickupLongitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Pickup',
          snippet: ride.pickupAddress,
        ),
      ),
    );
    
    // Destination marker (Red)
    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(ride.destinationLatitude, ride.destinationLongitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: ride.destinationAddress,
        ),
      ),
    );
    
    // Driver marker (Blue) - if driver assigned
    if (ride.driver != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(ride.pickupLatitude, ride.pickupLongitude), // Initial position
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: ride.driver!.name,
            snippet: '$_vehicleInfo • $_licensePlate',
          ),
        ),
      );
    }
    
    debugPrint('✅ Created ${markers.length} markers');
    return markers;
  }

  // ✅ UPDATED: Update driver marker with rotation
  void _updateDriverMarker(LatLng location, double? heading) {
    _markers.removeWhere((m) => m.markerId.value == 'driver');
    
    _markers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: _driverName,
          snippet: '$_vehicleInfo • $_licensePlate',
        ),
        rotation: heading ?? 0.0,
        anchor: const Offset(0.5, 0.5),
      ),
    );
  }

  // ✅ NEW METHOD: Fit map to show entire route
  Future<void> _fitMapToRoute() async {
    if (_mapController == null || _currentRide == null) return;
    
    try {
      // Calculate bounds including pickup, destination, and driver
      double minLat = _currentRide!.pickupLatitude;
      double maxLat = _currentRide!.pickupLatitude;
      double minLng = _currentRide!.pickupLongitude;
      double maxLng = _currentRide!.pickupLongitude;

      // Include destination
      minLat = min(minLat, _currentRide!.destinationLatitude);
      maxLat = max(maxLat, _currentRide!.destinationLatitude);
      minLng = min(minLng, _currentRide!.destinationLongitude);
      maxLng = max(maxLng, _currentRide!.destinationLongitude);

      // Include driver location if available
      if (_driverLocation != null) {
        minLat = min(minLat, _driverLocation!.latitude);
        maxLat = max(maxLat, _driverLocation!.latitude);
        minLng = min(minLng, _driverLocation!.longitude);
        maxLng = max(maxLng, _driverLocation!.longitude);
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      
      // Animate camera with padding
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100), // 100px padding
      );
      
      debugPrint('✅ Map fitted to route');
    } catch (e) {
      debugPrint('❌ Error fitting map: $e');
    }
  }

  // ✅ NEW METHOD: Show error message
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Show loading state
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error if no ride data
    if (_currentRide == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Ride Tracking'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Could not load ride details',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              debugPrint('✅ Map created');
            },
            initialCameraPosition: CameraPosition(
              target: _driverLocation ?? 
                     LatLng(_currentRide!.pickupLatitude, _currentRide!.pickupLongitude),
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: false,
            zoomGesturesEnabled: true,
          ),

          // Driver card (only show if driver assigned)
          if (_currentRide!.driver != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 100,
              child: DriverCardWidget(
                driver: _currentRide!.driver!,
                eta: _eta,
                onCallTap: () => _callDriver(_driverPhone),
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
                child: _buildStatusBanner(_currentRide!.status),
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

          // Re-center button
          Positioned(
            right: 16,
            bottom: 20,
            child: FloatingActionButton(
              heroTag: 'recenter',
              backgroundColor: Colors.white,
              mini: true,
              onPressed: _fitMapToRoute,
              child: Icon(Icons.my_location, color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(RideStatus status) {
    IconData icon;
    String message;
    Color color;

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
        if (_eta != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$_eta min',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  void _callDriver(String phone) {
    // TODO: Implement call functionality with url_launcher
    debugPrint('📞 Calling driver: $phone');
    // Launch tel:$phone
  }

  void _messageDriver() {
    // TODO: Implement in-app messaging
    debugPrint('💬 Messaging driver');
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
    debugPrint('🗑️ Disposing ride tracking screen');
    _mapController?.dispose();
    _locationSubscription?.cancel();
    _statusSubscription?.cancel();
    _socketService.disconnect();
    super.dispose();
  }
}

// ✅ ADD: Extension for Ride copyWith
extension RideCopyWith on Ride {
  Ride copyWith({
    RideStatus? status,
  }) {
    return Ride(
      id: id,
      userId: userId,
      driverId: driverId,
      rideType: rideType,
      status: status ?? this.status,
      pickupAddress: pickupAddress,
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
      destinationAddress: destinationAddress,
      destinationLatitude: destinationLatitude,
      destinationLongitude: destinationLongitude,
      fare: fare,
      distance: distance,
      estimatedDuration: estimatedDuration,
      createdAt: createdAt,
      completedAt: completedAt,
      driver: driver,
    );
  }
}