// ==================== widgets/driver_fab.dart ====================
// FLOATING ACTION BUTTON - Beautiful refresh button
// Only shows when driver is online

import 'package:flutter/material.dart';

class DriverFab extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onRefresh;

  const DriverFab({
    super.key,
    required this.isOnline,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOnline) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    
    return FloatingActionButton.extended(
      onPressed: onRefresh,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text(
        'Refresh',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}