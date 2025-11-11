// import 'package:flutter/material.dart';
// import '../../constants/colors.dart';
// import '../../constants/app_dimensions.dart';
// import '../../services/driver_service.dart';

// class DriverDashboard extends StatefulWidget {
//   const DriverDashboard({super.key});

//   @override
//   State<DriverDashboard> createState() => _DriverDashboardState();
// }

// class _DriverDashboardState extends State<DriverDashboard> {
//   final DriverService _driverService = DriverService();
  
//   bool _isOnline = false;
//   int _currentTab = 0;

//   @override
//   void initState() {
//     super.initState();
//     _loadDriverStats();
//   }

//   Future<void> _loadDriverStats() async {
//     try {
//       final response = await _driverService.getDriverProfile();
//       if (response.isSuccess && mounted) {
//         final data = response.data as Map<String, dynamic>;
//         debugPrint('✅ Driver stats loaded: ${data['total_rides']} rides, ${data['rating']} rating');
//       }
//     } catch (e) {
//       debugPrint('❌ Error loading driver stats: $e');
//     }
//   }

//   void _toggleOnlineStatus() {
//     setState(() => _isOnline = !_isOnline);
    
//     String message = _isOnline ? '🟢 You\'re now online' : '🔴 You\'re now offline';
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: _isOnline ? Colors.green : Colors.red,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         elevation: 0,
//         title: const Text(
//           'Driver Dashboard',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 20,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: GestureDetector(
//               onTap: _toggleOnlineStatus,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: _isOnline ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(
//                     color: _isOnline ? Colors.green : Colors.red,
//                     width: 1,
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 8,
//                       height: 8,
//                       decoration: BoxDecoration(
//                         color: _isOnline ? Colors.green : Colors.red,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                     const SizedBox(width: 6),
//                     Text(
//                       _isOnline ? 'Online' : 'Offline',
//                       style: TextStyle(
//                         color: _isOnline ? Colors.green : Colors.red,
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: IndexedStack(
//         index: _currentTab,
//         children: [
//           _buildEarningsTab(),
//           _buildRidesTab(),
//           _buildProfileTab(),
//         ],
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         backgroundColor: Colors.grey[900],
//         elevation: 0,
//         currentIndex: _currentTab,
//         selectedItemColor: AppColors.primary,
//         unselectedItemColor: Colors.grey[600],
//         onTap: (index) {
//           setState(() => _currentTab = index);
//         },
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.trending_up),
//             label: 'Earnings',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.directions_car),
//             label: 'Rides',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person),
//             label: 'Profile',
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEarningsTab() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(AppDimensions.paddingLarge),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   AppColors.primary,
//                   AppColors.primary.withOpacity(0.7),
//                 ],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: AppColors.primary.withOpacity(0.3),
//                   blurRadius: 20,
//                   spreadRadius: 2,
//                 ),
//               ],
//             ),
//             child: const Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Total Earnings',
//                   style: TextStyle(
//                     color: Colors.white70,
//                     fontSize: 14,
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   '₦45,230.50',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 32,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 SizedBox(height: 16),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'This Week',
//                           style: TextStyle(color: Colors.white70, fontSize: 12),
//                         ),
//                         SizedBox(height: 4),
//                         Text(
//                           '₦8,450',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'This Month',
//                           style: TextStyle(color: Colors.white70, fontSize: 12),
//                         ),
//                         SizedBox(height: 4),
//                         Text(
//                           '₦28,900',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 24),
//           const Text(
//             'Quick Stats',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildStatCard('Completed Rides', '127', Icons.check_circle),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: _buildStatCard('Acceptance Rate', '94%', Icons.trending_up),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildStatCard('Avg. Rating', '4.8', Icons.star),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: _buildStatCard('Total Cancellations', '3', Icons.cancel),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRidesTab() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(AppDimensions.paddingLarge),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (!_isOnline)
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.orange.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.orange, width: 1),
//               ),
//               child: const Row(
//                 children: [
//                   Icon(Icons.info, color: Colors.orange),
//                   SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'You\'re offline',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         SizedBox(height: 2),
//                         Text(
//                           'Go online to receive ride requests',
//                           style: TextStyle(color: Colors.orange, fontSize: 12),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           else
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.green.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.green, width: 1),
//               ),
//               child: const Row(
//                 children: [
//                   Icon(Icons.check_circle, color: Colors.green),
//                   SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       'You\'re online and ready to receive rides',
//                       style: TextStyle(color: Colors.green, fontSize: 12),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           const SizedBox(height: 24),
//           const Text(
//             'Active Rides',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 12),
//           _buildRideRequestCard(
//             rideId: 'RD-001',
//             pickup: '123 Lekki Road, Lagos',
//             destination: 'Victoria Island, Lagos',
//             distance: '12.5 km',
//             fare: '₦4,500',
//             riderName: 'John Doe',
//             riderRating: 4.8,
//             profileImage: null,
//           ),
//           const SizedBox(height: 12),
//           _buildRideRequestCard(
//             rideId: 'RD-002',
//             pickup: 'Ikoyi Crescent, Lagos',
//             destination: 'Ajah, Lagos',
//             distance: '18.3 km',
//             fare: '₦6,200',
//             riderName: 'Jane Smith',
//             riderRating: 4.9,
//             profileImage: null,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProfileTab() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(AppDimensions.paddingLarge),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.grey[900],
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Column(
//               children: [
//                 Container(
//                   width: 80,
//                   height: 80,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[700],
//                     borderRadius: BorderRadius.circular(40),
//                   ),
//                   child: const Icon(
//                     Icons.person,
//                     color: Colors.white,
//                     size: 40,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 const Text(
//                   'John Driver',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 const Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.star, color: AppColors.primary, size: 16),
//                     SizedBox(width: 4),
//                     Text(
//                       '4.8 (127 ratings)',
//                       style: TextStyle(color: Colors.grey, fontSize: 12),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 24),
//           const Text(
//             'Vehicle Information',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 12),
//           _buildInfoItem('Vehicle Type', 'Toyota Camry'),
//           _buildInfoItem('Color', 'Silver'),
//           _buildInfoItem('License Plate', 'ABC-123-XYZ'),
//           _buildInfoItem('Status', 'Approved', statusColor: Colors.green),
//           const SizedBox(height: 24),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: () {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('Edit profile feature coming soon'),
//                     duration: Duration(seconds: 2),
//                   ),
//                 );
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.primary,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//               ),
//               child: const Text(
//                 'Edit Profile',
//                 style: TextStyle(color: Colors.white, fontSize: 16),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatCard(String label, String value, IconData icon) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.grey[900],
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: AppColors.primary, size: 24),
//           const SizedBox(height: 8),
//           Text(
//             label,
//             style: const TextStyle(color: Colors.grey, fontSize: 12),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRideRequestCard({
//     required String rideId,
//     required String pickup,
//     required String destination,
//     required String distance,
//     required String fare,
//     required String riderName,
//     required double riderRating,
//     required String? profileImage,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.grey[900],
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey[800]!, width: 1),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     rideId,
//                     style: const TextStyle(
//                       color: Colors.grey,
//                       fontSize: 12,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     riderName,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//               Row(
//                 children: [
//                   const Icon(Icons.star, color: AppColors.primary, size: 16),
//                   const SizedBox(width: 4),
//                   Text(
//                     riderRating.toString(),
//                     style: const TextStyle(color: Colors.white, fontSize: 14),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               const Icon(Icons.location_on, color: AppColors.primary, size: 18),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       pickup,
//                       style: const TextStyle(color: Colors.white, fontSize: 13),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       destination,
//                       style: const TextStyle(color: Colors.grey, fontSize: 12),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   const Icon(Icons.directions_car, color: Colors.grey, size: 16),
//                   const SizedBox(width: 4),
//                   Text(
//                     distance,
//                     style: const TextStyle(color: Colors.grey, fontSize: 12),
//                   ),
//                 ],
//               ),
//               Text(
//                 fare,
//                 style: const TextStyle(
//                   color: AppColors.primary,
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: ElevatedButton.icon(
//                   onPressed: () {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text('Ride $rideId accepted'),
//                         backgroundColor: Colors.green,
//                       ),
//                     );
//                   },
//                   icon: const Icon(Icons.check),
//                   label: const Text('Accept'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: ElevatedButton.icon(
//                   onPressed: () {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text('Ride $rideId declined'),
//                         backgroundColor: Colors.red,
//                       ),
//                     );
//                   },
//                   icon: const Icon(Icons.close),
//                   label: const Text('Decline'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.red,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoItem(String label, String value, {Color? statusColor}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(color: Colors.grey, fontSize: 14),
//           ),
//           Row(
//             children: [
//               if (statusColor != null)
//                 Container(
//                   width: 8,
//                   height: 8,
//                   decoration: BoxDecoration(
//                     color: statusColor,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//               if (statusColor != null) const SizedBox(width: 8),
//               Text(
//                 value,
//                 style: TextStyle(
//                   color: statusColor ?? Colors.white,
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }