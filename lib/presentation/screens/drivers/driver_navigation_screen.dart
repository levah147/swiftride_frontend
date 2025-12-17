import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../models/driver_active_ride.dart';
import '../../../services/map_service.dart';
import '../../../services/socket_service.dart';
import '../../../constants/colors.dart';

class DriverNavigationScreen extends StatefulWidget {
  final DriverActiveRide ride;
  final void Function()? onArrived;
  final void Function()? onStart;
  final void Function()? onComplete;
  const DriverNavigationScreen({
    super.key,
    required this.ride,
    this.onArrived,
    this.onStart,
    this.onComplete,
  });

  @override
  State<DriverNavigationScreen> createState() => _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends State<DriverNavigationScreen> {
  final MapService _mapService = MapService();
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _posSub;
  bool _loading = true;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _driverLatLng;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _listenToPosition();
    await _buildStaticMarkers();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _listenToPosition() async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _updateDriver(position);
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_updateDriver, onError: (e) => debugPrint('GPS error: $e'));
  }

  void _updateDriver(Position pos) {
    final latLng = LatLng(pos.latitude, pos.longitude);
    _driverLatLng = latLng;
    _markers.removeWhere((m) => m.markerId.value == 'driver');
    _markers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'You'),
      ),
    );
    _fitCamera();
    _loadPolylines();
    if (mounted) setState(() {});

    // Push live location to rider via WS if connected
    SocketService().sendDriverLocation(
      latitude: pos.latitude,
      longitude: pos.longitude,
      heading: pos.heading,
      speed: pos.speed * 3.6,
      rideId: widget.ride.id,
    );
  }

  Future<void> _buildStaticMarkers() async {
    _markers.addAll([
      Marker(
        markerId: const MarkerId('pickup'),
        position:
            LatLng(widget.ride.pickupLatitude, widget.ride.pickupLongitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Pickup'),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(
            widget.ride.destinationLatitude, widget.ride.destinationLongitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Destination'),
      ),
    ]);
  }

  Future<void> _loadPolylines() async {
    if (_driverLatLng == null) return;
    try {
      final routeToPickup = await _mapService.getRoute(
        origin: _driverLatLng!,
        destination:
            LatLng(widget.ride.pickupLatitude, widget.ride.pickupLongitude),
        alternatives: false,
      );
      final pickupToDrop = await _mapService.getRoute(
        origin: LatLng(widget.ride.pickupLatitude, widget.ride.pickupLongitude),
        destination: LatLng(
            widget.ride.destinationLatitude, widget.ride.destinationLongitude),
        alternatives: false,
      );
      _polylines = {
        _mapService.createPolyline(routeToPickup, polylineId: 'to_pickup'),
        _mapService.createPolyline(pickupToDrop, polylineId: 'to_drop'),
      };
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Polyline error: $e');
    }
  }

  Future<void> _fitCamera() async {
    if (_mapController == null) return;
    final points = [
      if (_driverLatLng != null) _driverLatLng!,
      LatLng(widget.ride.pickupLatitude, widget.ride.pickupLongitude),
      LatLng(widget.ride.destinationLatitude, widget.ride.destinationLongitude),
    ];
    if (points.length < 2) return;
    final swLat = points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    final swLng =
        points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    final neLat = points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    final neLng =
        points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
    final bounds = LatLngBounds(
      southwest: LatLng(swLat, swLng),
      northeast: LatLng(neLat, neLng),
    );
    await _mapController!
        .animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Navigation', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(widget.ride.pickupLatitude,
                        widget.ride.pickupLongitude),
                    zoom: 14,
                  ),
                  onMapCreated: (c) => _mapController = c,
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: _buildCard(context),
                ),
              ],
            ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.ride.pickupLocation} → ${widget.ride.destinationLocation}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                widget.ride.riderName,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onArrived ??
                      () {
                        Navigator.pop(context);
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Arrived'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onStart ??
                      () {
                        Navigator.pop(context);
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text('Start'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onComplete ??
                      () {
                        Navigator.pop(context);
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Complete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
