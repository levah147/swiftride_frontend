// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'dart:async';
// import '../../constants/colors.dart';
// import '../../constants/app_dimensions.dart';

// class NewHomeScreen extends StatefulWidget {
//   final Function(String, {Map<String, dynamic>? data}) onNavigate;

//   const NewHomeScreen({
//     super.key,
//     required this.onNavigate,
//   });

//   @override
//   State<NewHomeScreen> createState() => _NewHomeScreenState();
// }

// class _NewHomeScreenState extends State<NewHomeScreen> {
//   // Map and Location
//   GoogleMapController? _mapController;
//   Position? _currentPosition;
//   bool _isLoadingLocation = true;
//   String _currentCity = 'Detecting...';
  
//   // Ride Booking State
//   final TextEditingController _pickupController = TextEditingController();
//   final TextEditingController _destinationController = TextEditingController();
//   final FocusNode _destinationFocusNode = FocusNode();
  
//   // Map Markers and Polylines
//   final Set<Marker> _markers = {};
//   final Set<Polyline> _polylines = {};
//   LatLng? _pickupLocation;
//   LatLng? _dropoffLocation;
  
//   // UI State
//   bool _showDestinationField = false;
//   bool _isLoadingRoute = false;
//   double? _estimatedDistance;
//   double? _estimatedFare;
//   int? _estimatedDuration;
  
//   // Ride Types
//   final List<Map<String, dynamic>> _rideTypes = [
//     {
//       'id': 'swift',
//       'name': 'SwiftRide',
//       'icon': Icons.directions_car,
//       'pricePerKm': 100.0, // NGN per km
//       'baseFare': 500.0,   // NGN base fare
//       'eta': '2 min',
//     },
//     {
//       'id': 'premium',
//       'name': 'Premium',
//       'icon': Icons.airport_shuttle,
//       'pricePerKm': 150.0, // NGN per km
//       'baseFare': 800.0,   // NGN base fare
//       'eta': '5 min',
//     },
//   ];
//   String _selectedRideType = 'swift';

//   @override
//   void initState() {
//     super.initState();
//     _initializeLocation();
//     _pickupController.text = 'Current Location';
    
//     // Auto-focus destination field after a short delay
//     Future.delayed(const Duration(milliseconds: 300), () {
//       setState(() => _showDestinationField = true);
//       _destinationFocusNode.requestFocus();
//     });
//   }

//   Future<void> _initializeLocation() async {
//     try {
//       // Check location permission
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         setState(() => _isLoadingLocation = false);
//         return;
//       }

//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           setState(() => _isLoadingLocation = false);
//           return;
//         }
//       }

//       // Get current position
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );

//       // Get address from coordinates
//       List<Placemark> placemarks = await placemarkFromCoordinates(
//         position.latitude,
//         position.longitude,
//       );

//       if (placemarks.isNotEmpty) {
//         setState(() {
//           _currentPosition = position;
//           _pickupLocation = LatLng(position.latitude, position.longitude);
//           _currentCity = placemarks.first.locality ?? 'Current Location';
//           _isLoadingLocation = false;
//         });

//         // Add pickup marker
//         _addPickupMarker(_pickupLocation!);
        
//         // Move camera to current location
//         _moveToCurrentLocation();
//       }
//     } catch (e) {
//       debugPrint('Location error: $e');
//       setState(() => _isLoadingLocation = false);
//     }
//   }

//   void _addPickupMarker(LatLng position) {
//     setState(() {
//       _markers.add(
//         Marker(
//           markerId: const MarkerId('pickup'),
//           position: position,
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//           infoWindow: const InfoWindow(title: 'Pickup Location'),
//         ),
//       );
//     });
//   }

//   void _moveToCurrentLocation() {
//     if (_currentPosition != null) {
//       _mapController?.animateCamera(
//         CameraUpdate.newCameraPosition(
//           CameraPosition(
//             target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
//             zoom: 16.0,
//             tilt: 45.0,
//           ),
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // Full screen map
//           _buildMap(),
          
//           // Top search bar
//           _buildSearchBar(),
          
//           // Bottom ride details
//           _buildRideDetails(),
          
//           // Recenter button
//           _buildRecenterButton(),
//         ],
//       ),
//     );
//   }

//   Widget _buildMap() {
//     return GoogleMap(
//       initialCameraPosition: CameraPosition(
//         target: _currentPosition != null
//             ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
//             : const LatLng(7.7304, 8.5378), // Default to Makurdi
//         zoom: 16.0,
//         tilt: 45.0,
//       ),
//       onMapCreated: (GoogleMapController controller) {
//         _mapController = controller;
//         _updateMapStyle();
//       },
//       myLocationEnabled: true,
//       myLocationButtonEnabled: false,
//       zoomControlsEnabled: false,
//       compassEnabled: true,
//       mapToolbarEnabled: false,
//       buildingsEnabled: true,
//       trafficEnabled: true,
//       markers: _markers,
//       polylines: _polylines,
//       onTap: (LatLng position) {
//         if (!_showDestinationField) return;
//         _setDropoffLocation(position);
//       },
//     );
//   }
  
//   Widget _buildSearchBar() {
//     return Positioned(
//       top: MediaQuery.of(context).padding.top + 16,
//       left: 0,
//       right: 0,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0),
//         child: Column(
//           children: [
//             // Current Location
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 10,
//                     offset: const Offset(0, 5),
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.my_location, color: AppColors.primary, size: 20),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: TextField(
//                       controller: _pickupController,
//                       style: const TextStyle(fontSize: 16),
//                       decoration: const InputDecoration(
//                         hintText: 'Current Location',
//                         border: InputBorder.none,
//                         isDense: true,
//                         contentPadding: EdgeInsets.zero,
//                       ),
//                       readOnly: true,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
            
//             // Destination Field (Animated)
//             if (_showDestinationField) ...[
//               const SizedBox(height: 12),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       blurRadius: 10,
//                       offset: const Offset(0, 5),
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.location_on, color: AppColors.error, size: 20),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: TextField(
//                         controller: _destinationController,
//                         focusNode: _destinationFocusNode,
//                         style: const TextStyle(fontSize: 16),
//                         decoration: const InputDecoration(
//                           hintText: 'Where to?',
//                           border: InputBorder.none,
//                           isDense: true,
//                           contentPadding: EdgeInsets.zero,
//                         ),
//                         onChanged: (value) {
//                           // Handle search as user types
//                           if (value.length > 2) {
//                             _searchPlaces(value);
//                           }
//                         },
//                       ),
//                     ),
//                     if (_destinationController.text.isNotEmpty)
//                       IconButton(
//                         icon: const Icon(Icons.close, size: 20),
//                         onPressed: () {
//                           _destinationController.clear();
//                           setState(() {
//                             _dropoffLocation = null;
//                             _markers.removeWhere((m) => m.markerId.value == 'dropoff');
//                             _polylines.clear();
//                           });
//                         },
//                       ),
//                   ],
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
  
//   Widget _buildRecenterButton() {
//     return Positioned(
//       right: 16,
//       bottom: _dropoffLocation != null ? 240 : 160,
//       child: FloatingActionButton(
//         onPressed: _moveToCurrentLocation,
//         backgroundColor: Colors.white,
//         child: const Icon(Icons.my_location, color: AppColors.primary),
//       ),
//     );
//   }
  
//   Widget _buildRideDetails() {
//     if (_dropoffLocation == null) return const SizedBox.shrink();
    
//     final rideType = _rideTypes.firstWhere((rt) => rt['id'] == _selectedRideType);
    
//     return Positioned(
//       left: 0,
//       right: 0,
//       bottom: 0,
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 10,
//               offset: Offset(0, -2),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Ride Type Selector
//             SizedBox(
//               height: 100,
//               child: ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: _rideTypes.length,
//                 itemBuilder: (context, index) {
//                   final type = _rideTypes[index];
//                   final isSelected = _selectedRideType == type['id'];
                  
//                   return GestureDetector(
//                     onTap: () => setState(() => _selectedRideType = type['id']),
//                     child: Container(
//                       width: 120,
//                       margin: const EdgeInsets.only(right: 12),
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey[100],
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(
//                           color: isSelected ? AppColors.primary : Colors.transparent,
//                           width: 2,
//                         ),
//                       ),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Icon(type['icon'], color: isSelected ? AppColors.primary : Colors.grey[600]),
//                           Text(
//                             type['name'],
//                             style: TextStyle(
//                               color: isSelected ? AppColors.primary : Colors.black87,
//                               fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                             ),
//                           ),
//                           Text(
//                             '${_estimatedFare?.toStringAsFixed(0) ?? '--'} NGN',
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           Text(
//                             '${_estimatedDuration != null ? '~${_estimatedDuration! ~/ 60} min' : '--'} • ${_estimatedDistance?.toStringAsFixed(1) ?? '--'} km',
//                             style: TextStyle(
//                               color: Colors.grey[600],
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
            
//             const SizedBox(height: 16),
            
//             // Confirm Button
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _confirmRide,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.primary,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: const Text(
//                   'Confirm Ride',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _searchPlaces(String query) async {
//     // Implement place search using Google Places API
//     debugPrint('Searching for: $query');
//   }
  
//   void _setDropoffLocation(LatLng position) async {
//     setState(() {
//       _isLoadingRoute = true;
//       _dropoffLocation = position;
      
//       // Update marker
//       _markers.removeWhere((m) => m.markerId.value == 'dropoff');
//       _markers.add(
//         Marker(
//           markerId: const MarkerId('dropoff'),
//           position: position,
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//           infoWindow: const InfoWindow(title: 'Destination'),
//         ),
//       );
//     });
    
//     // Get address for the selected location
//     final placemarks = await placemarkFromCoordinates(
//       position.latitude,
//       position.longitude,
//     );
    
//     if (placemarks.isNotEmpty) {
//       final place = placemarks.first;
//       final address = '${place.street}, ${place.subLocality ?? ''} ${place.locality ?? ''}'.trim();
      
//       if (mounted) {
//         setState(() {
//           _destinationController.text = address;
//         });
//       }
//     }
    
//     // Calculate route
//     if (_currentPosition != null) {
//       await _calculateRoute();
//     }
    
//     if (mounted) {
//       setState(() => _isLoadingRoute = false);
//     }
//   }
  
//   Future<void> _calculateRoute() async {
//     if (_currentPosition == null || _dropoffLocation == null) return;
    
//     try {
//       // In a real app, you would use the Google Maps Directions API here
//       // For now, we'll just draw a straight line between the points
//       // and calculate a simple fare estimate
      
//       // Calculate distance in km
//       final distanceInMeters = Geolocator.distanceBetween(
//         _currentPosition!.latitude,
//         _currentPosition!.longitude,
//         _dropoffLocation!.latitude,
//         _dropoffLocation!.longitude,
//       );
      
//       final distanceInKm = distanceInMeters / 1000;
      
//       // Calculate duration estimate (assuming average speed of 30 km/h)
//       final durationInSeconds = (distanceInKm / 30) * 3600;
      
//       // Update route on map
//       _updateRouteOnMap();
      
//       // Calculate fare
//       final rideType = _rideTypes.firstWhere((rt) => rt['id'] == _selectedRideType);
//       final fare = rideType['baseFare'] + (distanceInKm * rideType['pricePerKm']);
      
//       setState(() {
//         _estimatedDistance = distanceInKm;
//         _estimatedDuration = durationInSeconds.toInt();
//         _estimatedFare = fare;
//       });
//     } catch (e) {
//       debugPrint('Error calculating route: $e');
//     }
//   }
  
//   void _updateRouteOnMap() {
//     if (_pickupLocation == null || _dropoffLocation == null) return;
    
//     setState(() {
//       _polylines.clear();
//       _polylines.add(
//         Polyline(
//           polylineId: const PolylineId('route'),
//           points: [_pickupLocation!, _dropoffLocation!],
//           color: AppColors.primary,
//           width: 5,
//           startCap: Cap.roundCap,
//           endCap: Cap.roundCap,
//         ),
//       );
//     });
    
//     // Update camera to show the entire route
//     _fitToPoints();
//   }
  
//   void _fitToPoints() {
//     if (_pickupLocation == null || _dropoffLocation == null) return;
    
//     // Calculate bounds
//     double minLat = _pickupLocation!.latitude < _dropoffLocation!.latitude 
//         ? _pickupLocation!.latitude 
//         : _dropoffLocation!.latitude;
//     double maxLat = _pickupLocation!.latitude > _dropoffLocation!.latitude 
//         ? _pickupLocation!.latitude 
//         : _dropoffLocation!.latitude;
//     double minLng = _pickupLocation!.longitude < _dropoffLocation!.longitude 
//         ? _pickupLocation!.longitude 
//         : _dropoffLocation!.longitude;
//     double maxLng = _pickupLocation!.longitude > _dropoffLocation!.longitude 
//         ? _pickupLocation!.longitude 
//         : _dropoffLocation!.longitude;
    
//     // Add padding
//     final padding = 0.01;
//     minLat -= padding;
//     maxLat += padding;
//     minLng -= padding;
//     maxLng += padding;
    
//     // Create bounds
//     final bounds = LatLngBounds(
//       southwest: LatLng(minLat, minLng),
//       northeast: LatLng(maxLat, maxLng),
//     );
    
//     // Update camera
//     _mapController?.animateCamera(
//       CameraUpdate.newLatLngBounds(bounds, 50),
//     );
//   }
  
//   void _updateMapStyle() async {
//     // You can load a custom map style from a JSON file
//     // For now, we'll use a simple dark style
//     String style = '''
//       [
//         {
//           "elementType": "geometry",
//           "stylers": [
//             {
//               "color": "#242f3e"
//             }
//           ]
//         },
//         {
//           "elementType": "labels.text.fill",
//           "stylers": [
//             {
//               "color": "#746855"
//             }
//           ]
//         },
//         {
//           "elementType": "labels.text.stroke",
//           "stylers": [
//             {
//               "color": "#242f3e"
//             }
//           ]
//         }
//       ]
//     ''';
//     _mapController?.setMapStyle(style);
//   }
  
//   void _confirmRide() {
//     if (_dropoffLocation == null) return;
    
//     // Show loading
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => const Center(
//         child: CircularProgressIndicator(),
//       ),
//     );
    
//     // In a real app, you would call your API to book the ride
//     // For now, just show a success message
//     Future.delayed(const Duration(seconds: 2), () {
//       Navigator.pop(context); // Dismiss loading
      
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Ride Requested'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(Icons.check_circle, color: Colors.green, size: 64),
//               const SizedBox(height: 16),
//               const Text('Finding you a driver...'),
//               const SizedBox(height: 8),
//               Text(
//                 '${_estimatedFare?.toStringAsFixed(0) ?? '--'} NGN • ${_estimatedDistance?.toStringAsFixed(1) ?? '--'} km',
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('OK'),
//             ),
//           ],
//         ),
//       );
//     });
//   }

//   @override
//   void dispose() {
//     _mapController?.dispose();
//     _pickupController.dispose();
//     _destinationController.dispose();
//     _destinationFocusNode.dispose();
//     super.dispose();
//   }
// }
