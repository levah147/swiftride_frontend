// ==================== widgets/route_stop_item.dart ====================
// Individual stop item widget with search field and actions

import 'package:flutter/material.dart';
import '../../../../../models/route_stop.dart';

class RouteStopItem extends StatelessWidget {
  final RouteStop stop;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback? onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onUseCurrentLocation;
  final bool canMoveUp;
  final bool canMoveDown;
  final bool isFirst;
  final bool isLast;

  const RouteStopItem({
    super.key,
    required this.stop,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.onRemove,
    this.onMoveUp,
    this.onMoveDown,
    this.onUseCurrentLocation,
    this.canMoveUp = false,
    this.canMoveDown = false,
    this.isFirst = false,
    this.isLast = false,
  });

  Color _getDotColor(BuildContext context, StopType type) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case StopType.pickup:
        return colorScheme.primary;
      case StopType.destination:
        return colorScheme.error;
      case StopType.waypoint:
        return colorScheme.onSurfaceVariant;
    }
  }

  String _getHintText(StopType type) {
    switch (type) {
      case StopType.pickup:
        return 'Pickup location';
      case StopType.destination:
        return 'Dropoff location';
      case StopType.waypoint:
        return 'Add stop';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dotColor = _getDotColor(context, stop.type);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Colored dot indicator
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.surface,
              width: 2,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Search text field
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: _getHintText(stop.type),
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),

        // Action buttons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Current location button (only for pickup)
            if (stop.type == StopType.pickup && onUseCurrentLocation != null)
              IconButton(
                icon: Icon(
                  Icons.my_location,
                  color: colorScheme.primary,
                  size: 20,
                ),
                onPressed: onUseCurrentLocation,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

            // Reorder buttons (only for waypoints)
            if (stop.type == StopType.waypoint) ...[
              const SizedBox(width: 8),

              // Up arrow
              if (canMoveUp)
                InkWell(
                  onTap: onMoveUp,
                  child: Icon(
                    Icons.arrow_upward,
                    color: colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                )
              else
                Icon(
                  Icons.arrow_upward,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                  size: 18,
                ),

              const SizedBox(width: 4),

              // Down arrow
              if (canMoveDown)
                InkWell(
                  onTap: onMoveDown,
                  child: Icon(
                    Icons.arrow_downward,
                    color: colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                )
              else
                Icon(
                  Icons.arrow_downward,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                  size: 18,
                ),
            ],

            // Remove button (only for waypoints)
            if (stop.type == StopType.waypoint && onRemove != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: onRemove,
                child: Icon(
                  Icons.close,
                  color: colorScheme.error.withOpacity(0.7),
                  size: 20,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
