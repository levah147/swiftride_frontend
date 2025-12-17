// ==================== widgets/ride_card.dart ====================
// RIDE CARD BASE WIDGET - Reusable card component
// DRY principle - used by both available and active ride cards

import 'package:flutter/material.dart';

class RideCard extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const RideCard({
    super.key,
    required this.child,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? theme.colorScheme.surface : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}