// ==================== widgets/home_map_widget.dart ====================
// HOME MAP WIDGET - Google Maps component for home screen
// Displays user location and allows pin placement 

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../screens/home/controllers/home_controller.dart';

class HomeMapWidget extends StatefulWidget {
  final Function(LatLng)? onLocationSelected;
  final bool showUserLocation;
  final Set<Marker>? additionalMarkers;
  final Set<Polyline>? polylines;

  const HomeMapWidget({
    super.key,
    this.onLocationSelected,
    this.showUserLocation = true,
    this.additionalMarkers,
    this.polylines,
  });

  @override
  State<HomeMapWidget> createState() => _HomeMapWidgetState();
}

class _HomeMapWidgetState extends State<HomeMapWidget> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  bool _isMoving = false;

  // Default location (Makurdi, Nigeria)
  static const LatLng _defaultLocation = LatLng(7.7300, 8.5375);

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: Use Consumer to safely access HomeController
    return Consumer<HomeController>(
      builder: (context, controller, child) {
        // Use current location or default
        final initialPosition = controller.currentLatLng ?? _defaultLocation;

        return Stack(
          children: [
            // Google Map
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: initialPosition,
                zoom: 15,
                tilt: 0,
              ),
              myLocationEnabled: widget.showUserLocation && controller.currentPosition != null,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              markers: _buildMarkers(),
              polylines: widget.polylines ?? {},
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              style: Theme.of(context).brightness == Brightness.dark 
                  ? _darkMapStyle 
                  : null,
              padding: const EdgeInsets.only(bottom: 300), // Space for bottom sheet
            ),

            // Center pin (for location selection)
            if (widget.onLocationSelected != null)
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: Matrix4.translationValues(
                    0,
                    _isMoving ? -20 : -40,
                    0,
                  ),
                  child: Icon(
                    Icons.location_on,
                    size: _isMoving ? 50 : 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),

            // My location button
            if (widget.showUserLocation)
              Positioned(
                right: 16,
                bottom: 320,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () => _goToCurrentLocation(controller),
                  child: const Icon(Icons.my_location, color: Colors.black87),
                ),
              ),
          ],
        );
      },
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    // Apply dark style if needed
    if (Theme.of(context).brightness == Brightness.dark) {
      controller.setMapStyle(_darkMapStyle);
    }
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _isMoving = true;
      _selectedLocation = position.target;
    });
  }

  void _onCameraIdle() {
    setState(() {
      _isMoving = false;
    });
    
    // Notify parent of location selection
    if (_selectedLocation != null && widget.onLocationSelected != null) {
      widget.onLocationSelected!(_selectedLocation!);
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    
    // Add additional markers
    if (widget.additionalMarkers != null) {
      markers.addAll(widget.additionalMarkers!);
    }
    
    return markers;
  }

  Future<void> _goToCurrentLocation(HomeController controller) async {
    if (controller.currentLatLng != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(controller.currentLatLng!, 15),
      );
    }
  }

  // Dark mode map style
  static const String _darkMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#1d2c4d"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#8ec3b9"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#1a3646"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#2c6675"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#255763"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#0e1626"}]
    }
  ]
  ''';

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}