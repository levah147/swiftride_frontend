
// ==================== widgets/dialogs/delete_account_dialog.dart ====================
import 'package:flutter/material.dart';
import 'package:swiftride/constants/app_strings.dart';

class DeleteAccountDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const DeleteAccountDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text(
        AppStrings.deleteAccountTitle,
        style: TextStyle(color: Colors.white),
      ),
      content: const Text(
        AppStrings.deleteAccountMessage,
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            AppStrings.cancel,
            style: TextStyle(color: Colors.white70),
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
