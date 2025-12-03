// ==================== widgets/rides_tab_bar.dart ====================
import 'package:flutter/material.dart';
import '../../../../constants/app_strings.dart';

class RidesTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;

  const RidesTabBar({
    super.key,
    required this.controller,
  });

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    // 🎨 Get theme colors
    final colorScheme = Theme.of(context).colorScheme;

    return TabBar(
      controller: controller,
      indicatorColor: colorScheme.primary,
      indicatorWeight: 3,
      labelColor: colorScheme.onSurface,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      labelStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      tabs: const [
        Tab(text: AppStrings.upcomingRides),
        Tab(text: AppStrings.pastRides),
      ],
    );
  }
}