// ==================== widgets/route_preview_widget.dart ====================
// ROUTE PREVIEW - Display route information and alternatives

import 'package:flutter/material.dart';
import '../../../../models/route_info.dart';

class RoutePreviewWidget extends StatelessWidget {
  final RouteInfo route;
  final List<RouteInfo>? alternativeRoutes;
  final Function(RouteInfo)? onRouteSelected;

  const RoutePreviewWidget({
    super.key,
    required this.route,
    this.alternativeRoutes,
    this.onRouteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary route
          _RouteCard(
            route: route,
            isSelected: true,
            onTap: onRouteSelected != null ? () => onRouteSelected!(route) : null,
          ),

          // Alternative routes
          if (alternativeRoutes != null && alternativeRoutes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Alternative routes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ...alternativeRoutes!.map((altRoute) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RouteCard(
                route: altRoute,
                isSelected: false,
                onTap: onRouteSelected != null ? () => onRouteSelected!(altRoute) : null,
              ),
            )),
          ],
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final RouteInfo route;
  final bool isSelected;
  final VoidCallback? onTap;

  const _RouteCard({
    required this.route,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Distance & duration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.formattedDistance,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.blue : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    route.formattedDuration,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Traffic indicator
            if (route.hasTraffic && route.trafficLevel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: route.trafficLevel!.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  route.trafficLevel!.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    color: route.trafficLevel!.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // Route summary
            if (route.routeSummary != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  route.routeSummary!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}