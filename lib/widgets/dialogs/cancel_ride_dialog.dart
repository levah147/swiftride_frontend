
// ==================== widgets/dialogs/cancel_ride_dialog.dart ====================
import 'package:flutter/material.dart';
import 'package:swiftride/constants/app_strings.dart';

class CancelRideDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const CancelRideDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text(
        AppStrings.cancelRideTitle,
        style: TextStyle(color: Colors.white),
      ),
      content: const Text(
        AppStrings.cancelRideMessage,
        style: TextStyle(color: Colors.grey),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onCancel();
          },
          child: const Text(
            AppStrings.keepRide,
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text(
            AppStrings.confirmDelete,
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
