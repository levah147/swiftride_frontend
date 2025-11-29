// // ==================== widgets/dialogs/logout_dialog.dart ====================
// import 'package:flutter/material.dart';
// import '../../constants/app_strings.dart';

// class LogoutDialog extends StatelessWidget {
//   final VoidCallback onConfirm;

//   const LogoutDialog({
//     super.key,
//     required this.onConfirm,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       backgroundColor: Colors.grey[900],
//       title: const Text(
//         AppStrings.logoutTitle,
//         style: TextStyle(color: Colors.white),
//       ),
//       content: const Text(
//         AppStrings.logoutMessage,
//         style: TextStyle(color: Colors.white70),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text(
//             AppStrings.cancel,
//             style: TextStyle(color: Colors.white70),
//           ),
//         ),
//         TextButton(
//           onPressed: () {
//             Navigator.pop(context);
//             onConfirm();
//           },
//           child: const Text(
//             AppStrings.confirmLogout,
//             style: TextStyle(color: Colors.red),
//           ),
//         ),
//       ],
//     );
//   }
// }
