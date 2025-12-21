// ==================== widgets/route_stops_input.dart ====================
// Container widget for all route stops with visual connectors

import 'package:flutter/material.dart';
import '../../../../../constants/app_dimensions.dart';
import '../../../../../models/route_stop.dart';
import 'route_stop_item.dart';

class RouteStopsInput extends StatelessWidget {
  final List<RouteStop> stops;
  final Map<String, TextEditingController> controllers;
  final Map<String, FocusNode> focusNodes;
  final Function(String stopId, String query) onStopChanged;
  final VoidCallback? onAddStop;
  final Function(String stopId)? onRemoveStop;
  final Function(String stopId)? onMoveStopUp;
  final Function(String stopId)? onMoveStopDown;
  final VoidCallback? onUseCurrentLocationForPickup;
  final bool canAddMoreStops;
  final int maxStops;

  const RouteStopsInput({
    super.key,
    required this.stops,
    required this.controllers,
    required this.focusNodes,
    required this.onStopChanged,
    this.onAddStop,
    this.onRemoveStop,
    this.onMoveStopUp,
    this.onMoveStopDown,
    this.onUseCurrentLocationForPickup,
    this.canAddMoreStops = true,
    this.maxStops = 5,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Render all stops with connectors
          ...List.generate(stops.length, (index) {
            final stop = stops[index];
            final isFirst = index == 0;
            final isLast = index == stops.length - 1;
            final isWaypoint = stop.type == StopType.waypoint;

            // Determine if this waypoint can move up/down
            final canMoveUp =
                isWaypoint && index > 1; // Can't move above pickup
            final canMoveDown = isWaypoint &&
                index < stops.length - 1; // Can't move below destination

            return Column(
              children: [
                // Stop item
                RouteStopItem(
                  stop: stop,
                  controller: controllers[stop.id]!,
                  focusNode: focusNodes[stop.id]!,
                  onChanged: (query) => onStopChanged(stop.id, query),
                  onRemove:
                      isWaypoint ? () => onRemoveStop?.call(stop.id) : null,
                  onMoveUp:
                      canMoveUp ? () => onMoveStopUp?.call(stop.id) : null,
                  onMoveDown:
                      canMoveDown ? () => onMoveStopDown?.call(stop.id) : null,
                  onUseCurrentLocation: stop.type == StopType.pickup
                      ? onUseCurrentLocationForPickup
                      : null,
                  canMoveUp: canMoveUp,
                  canMoveDown: canMoveDown,
                  isFirst: isFirst,
                  isLast: isLast,
                ),

                // Connector line (except after last stop)
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Container(
                      width: 2,
                      height: 24,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                    ),
                  ),
              ],
            );
          }),

          // Add stop button
          if (canAddMoreStops && stops.length < maxStops) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: onAddStop,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add stop',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
