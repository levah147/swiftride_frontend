// import 'package:flutter/material.dart';
// import 'package:swiftride/presentation/screens/support/support_home_screen.dart';
// import '../../../../../constants/app_strings.dart';
// import '../../../../../constants/app_dimensions.dart';
// import '../../../../../widgets/common/menu_section_widget.dart';
// import '../../../../../widgets/common/menu_item_widget.dart';
// import '../../../wallet/wallet_screen.dart';

// /// Rider menu section showing rider-specific options
// /// Used by: Riders ONLY (non-drivers)
// class RiderMenuSectionWidget extends StatelessWidget {
//   final Color textColor;
//   final Color? cardColor;
//   final Color? secondaryText;
//   final String selectedLanguage;

//   const RiderMenuSectionWidget({
//     Key? key,
//     required this.textColor,
//     required this.cardColor,
//     required this.secondaryText,
//     this.selectedLanguage = 'English - GB',
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // Services Section
//         Padding(
//           padding: const EdgeInsets.symmetric(
//               horizontal: AppDimensions.paddingLarge),
//           child: MenuSectionWidget(
//             backgroundColor: cardColor,
//             items: [
//               MenuItemWidget(
//                 icon: Icons.payment,
//                 title: AppStrings.payment,
//                 textColor: textColor,
//                 cardColor: cardColor,
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const WalletScreen(
//                         isDriver: false, // Set to true for drivers
//                       ),
//                     ),
//                   );
//                 },
//               ),
//               MenuItemWidget(
//                 icon: Icons.local_offer_outlined,
//                 title: AppStrings.promotions,
//                 textColor: textColor,
//                 cardColor: cardColor,
//                 onTap: () {
//                   Navigator.pushNamed(context, '/promotions');
//                 },
//               ),
//               MenuItemWidget(
//                 icon: Icons.history,
//                 title: AppStrings.myRides,
//                 textColor: textColor,
//                 cardColor: cardColor,
//                 onTap: () {
//                   // Navigate to rides screen (tab 1)
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content:
//                           Text('Check the Rides tab for your ride history'),
//                       duration: Duration(seconds: 2),
//                     ),
//                   );
//                 },
//               ),
//               MenuItemWidget(
//                 icon: Icons.receipt_long,
//                 title: AppStrings.expenseYourRides,
//                 textColor: textColor,
//                 cardColor: cardColor,
//                 onTap: () {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('Expense feature coming soon'),
//                       duration: Duration(seconds: 2),
//                     ),
//                   );
//                 },
//               ),
//               MenuItemWidget(
//                 icon: Icons.support_agent,
//                 title: AppStrings.support,
//                 textColor: textColor,
//                 cardColor: cardColor,
//                 onTap: () {
//                   // ScaffoldMessenger.of(context).showSnackBar(
//                   //   const SnackBar(
//                   //     content: Text('Support feature coming soon'),
//                   //     duration: Duration(seconds: 2),
//                   //   ),
//                   // );

//                   Navigator.pushNamed(context, '/support');
//                 },
//               ),
//               MenuItemWidget(
//                 icon: Icons.info_outline,
//                 title: AppStrings.about,
//                 textColor: textColor,
//                 cardColor: cardColor,
//                 onTap: () {
//                   _showAboutDialog(context);
//                 },
//               ),
//             ],
//           ),
//         ),

//         const SizedBox(height: 16),

//         // Preferences Section
//         Padding(
//           padding: const EdgeInsets.symmetric(
//               horizontal: AppDimensions.paddingLarge),
//           child: MenuSectionWidget(
//             backgroundColor: cardColor,
//             items: [
//               MenuItemWidget(
//                 icon: Icons.language,
//                 title: AppStrings.language,
//                 subtitle: selectedLanguage,
//                 textColor: textColor,
//                 cardColor: cardColor,
//                 subtitleColor: secondaryText,
//                 onTap: () 
//                 {
//                   Navigator.pushNamed(context, '/settings/language');
//                 }
//                 // {
//                 //   ScaffoldMessenger.of(context).showSnackBar(
//                 //     const SnackBar(
//                 //       content: Text('Language selection coming soon'),
//                 //       duration: Duration(seconds: 2),
//                 //     ),
//                 //   );
//                 // },
//               ),
//               MenuItemWidget(
//                 icon: Icons.notifications_outlined,
//                 title: AppStrings.communicationPreferences,
//                 textColor: textColor,
//                 cardColor: cardColor,
//                 onTap: () {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('Communication preferences coming soon'),
//                       duration: Duration(seconds: 2),
//                     ),
//                   );
//                 },
//               ),
//               MenuItemWidget(
//                 icon: Icons.calendar_today,
//                 title: AppStrings.calendars,
//                 textColor: textColor,
//                 cardColor: cardColor,
//                 onTap: () {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('Calendar integration coming soon'),
//                       duration: Duration(seconds: 2),
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   void _showAboutDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('About SwiftRide'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: const [
//             Text('SwiftRide',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//             SizedBox(height: 8),
//             Text('Version 1.0.0'),
//             SizedBox(height: 16),
//             Text('Your reliable ride-hailing service'),
//             SizedBox(height: 8),
//             Text('© 2024 SwiftRide. All rights reserved.'),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }
// }
