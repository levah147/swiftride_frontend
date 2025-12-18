// ==================== widgets/location_list_items.dart ====================
// REUSABLE LIST ITEM COMPONENTS - Saved, Recent, Suggestions

import 'package:flutter/material.dart';
import '../../../../../models/location.dart';
import '../../../../../services/geocoding_service.dart';

// ============================================
// SECTION HEADER
// ============================================

class LocationSectionHeader extends StatelessWidget {
  final String title;

  const LocationSectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ============================================
// ADD SAVED PLACE ITEM (Home/Work)
// ============================================

class AddSavedPlaceItem extends StatelessWidget {
  final String type;
  final VoidCallback onTap;

  const AddSavedPlaceItem({
    super.key,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = type == 'home' ? Icons.home_outlined : Icons.work_outline;
    final title = type == 'home' ? 'Add home' : 'Add work';
    final subtitle = type == 'home' 
        ? 'Set your home location' 
        : 'Set your work location';

    return _BaseLocationItem(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      colorScheme: colorScheme,
    );
  }
}

// ============================================
// SAVED LOCATION ITEM
// ============================================

class SavedLocationItem extends StatelessWidget {
  final SavedLocation location;
  final VoidCallback onTap;

  const SavedLocationItem({
    super.key,
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _BaseLocationItem(
      icon: location.icon,
      title: location.displayName,
      subtitle: location.address,
      onTap: onTap,
      colorScheme: colorScheme,
    );
  }
}

// ============================================
// RECENT LOCATION ITEM
// ============================================

class RecentLocationItem extends StatelessWidget {
  final RecentLocation location;
  final VoidCallback onTap;

  const RecentLocationItem({
    super.key,
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtitle = location.subtitle.isNotEmpty 
        ? location.subtitle 
        : location.address;

    return _BaseLocationItem(
      icon: Icons.history,
      title: location.placeName,
      subtitle: subtitle,
      onTap: onTap,
      colorScheme: colorScheme,
    );
  }
}

// ============================================
// PLACE SUGGESTION ITEM
// ============================================

class PlaceSuggestionItem extends StatelessWidget {
  final PlaceSuggestion suggestion;
  final VoidCallback onTap;

  const PlaceSuggestionItem({
    super.key,
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _BaseLocationItem(
      icon: Icons.location_on,
      title: suggestion.mainText,
      subtitle: suggestion.secondaryText,
      onTap: onTap,
      colorScheme: colorScheme,
    );
  }
}

// ============================================
// BASE LOCATION ITEM (Private, Reusable)
// ============================================

class _BaseLocationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _BaseLocationItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _buildIconContainer(),
            const SizedBox(width: 16),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconContainer() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: colorScheme.onSurfaceVariant,
        size: 20,
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}