// ==================== widgets/driver_app_bar.dart ====================
// DRIVER APP BAR - Professional, reusable component
// Handles online/offline toggle with beautiful UI

import 'package:flutter/material.dart';

class DriverAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isOnline;
  final bool isToggling;
  final VoidCallback onToggle;

  const DriverAppBar({
    super.key,
    required this.isOnline,
    required this.isToggling,
    required this.onToggle,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        'Driver Console',
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _OnlineToggleButton(
            isOnline: isOnline,
            isToggling: isToggling,
            onToggle: onToggle,
          ),
        ),
      ],
    );
  }
}

/// Online/Offline toggle button with loading state
class _OnlineToggleButton extends StatelessWidget {
  final bool isOnline;
  final bool isToggling;
  final VoidCallback onToggle;

  const _OnlineToggleButton({
    required this.isOnline,
    required this.isToggling,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = isOnline 
        ? const Color(0xFF10B981) // Success green
        : const Color(0xFFEF4444); // Error red
    
    return GestureDetector(
      onTap: isToggling ? null : onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: statusColor.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isToggling)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              )
            else
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 8),
            Text(
              isOnline ? 'Online' : 'Offline',
              style: theme.textTheme.labelLarge?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}