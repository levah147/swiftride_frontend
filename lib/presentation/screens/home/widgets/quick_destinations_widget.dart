// ==================== widgets/quick_destinations_widget.dart ====================
// QUICK DESTINATIONS - Home and Work shortcuts

import 'package:flutter/material.dart';

class QuickDestinationsWidget extends StatelessWidget {
  final String? homeAddress;
  final String? workAddress;
  final VoidCallback? onHomeTap;
  final VoidCallback? onWorkTap;

  const QuickDestinationsWidget({
    super.key,
    this.homeAddress,
    this.workAddress,
    this.onHomeTap,
    this.onWorkTap,
  });

  @override
  Widget build(BuildContext context) {
    if (homeAddress == null && workAddress == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (homeAddress != null)
          _QuickDestinationTile(
            icon: Icons.home_outlined,
            title: 'Home',
            subtitle: homeAddress!,
            onTap: onHomeTap,
          ),
        
        if (homeAddress != null && workAddress != null)
          const SizedBox(height: 12),
        
        if (workAddress != null)
          _QuickDestinationTile(
            icon: Icons.work_outline,
            title: 'Work',
            subtitle: workAddress!,
            onTap: onWorkTap,
          ),
      ],
    );
  }
}

class _QuickDestinationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _QuickDestinationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}