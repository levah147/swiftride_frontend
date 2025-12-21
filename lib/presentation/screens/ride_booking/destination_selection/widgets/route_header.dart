// ==================== widgets/route_header.dart ====================
// Simple header with title and close button

import 'package:flutter/material.dart';
import '../../../../../constants/app_dimensions.dart';

class RouteHeader extends StatelessWidget {
  final VoidCallback onClose;

  const RouteHeader({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLarge,
        vertical: AppDimensions.paddingMedium,
      ),
      child: Row(
        children: [
          Text(
            'Your route',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close, color: colorScheme.onSurface),
            onPressed: onClose,
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
