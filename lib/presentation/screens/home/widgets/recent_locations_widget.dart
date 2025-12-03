// ==================== widgets/recent_locations_widget.dart ====================
// RECENT LOCATIONS - List of recent destinations

import 'package:flutter/material.dart';
import '../../../../models/location.dart';

class RecentLocationsWidget extends StatelessWidget {
  final List<RecentLocation> recentLocations;
  final Function(String) onLocationTap;
  final bool isLoading;

  const RecentLocationsWidget({
    super.key,
    required this.recentLocations,
    required this.onLocationTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (recentLocations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...recentLocations.take(5).map((location) => _RecentLocationTile(
          location: location,
          onTap: () => onLocationTap(location.id),
        )),
      ],
    );
  }
}

class _RecentLocationTile extends StatelessWidget {
  final RecentLocation location;
  final VoidCallback onTap;

  const _RecentLocationTile({
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.history, size: 20),
      ),
      title: Text(
        location.address,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: location.placeName != null
          ? Text(
              location.placeName!,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            )
          : null,
      onTap: onTap,
    );
  }
}