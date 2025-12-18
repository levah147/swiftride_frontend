// ==================== widgets/destination_header.dart ====================
// HEADER COMPONENT - Search inputs, schedule toggle

import 'package:flutter/material.dart';
import '../../../../../constants/app_dimensions.dart';

class DestinationHeader extends StatelessWidget {
  final TextEditingController fromController;
  final TextEditingController toController;
  final FocusNode toFocusNode;
  final bool isScheduled;
  final ValueChanged<bool> onScheduledChanged;
  final VoidCallback onBack;
  final VoidCallback onClearDestination;

  const DestinationHeader({
    super.key,
    required this.fromController,
    required this.toController,
    required this.toFocusNode,
    required this.isScheduled,
    required this.onScheduledChanged,
    required this.onBack,
    required this.onClearDestination,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        children: [
          _buildTopBar(colorScheme),
          const SizedBox(height: 20),
          _buildLocationInputs(colorScheme),
          const SizedBox(height: 16),
          _buildScheduleToggle(colorScheme),
        ],
      ),
    );
  }

  Widget _buildTopBar(ColorScheme colorScheme) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: onBack,
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Where to?',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInputs(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _LocationInputField(
            controller: fromController,
            hintText: 'Pickup location',
            dotColor: colorScheme.primary,
            enabled: false,
            colorScheme: colorScheme,
            trailing: IconButton(
              icon: Icon(Icons.my_location, color: colorScheme.primary, size: 20),
              onPressed: () {},
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Container(
              width: 2,
              height: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          _LocationInputField(
            controller: toController,
            focusNode: toFocusNode,
            hintText: 'Where to?',
            dotColor: colorScheme.error,
            enabled: true,
            colorScheme: colorScheme,
            trailing: toController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant, size: 20),
                    onPressed: onClearDestination,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleToggle(ColorScheme colorScheme) {
    return Row(
      children: [
        Switch(
          value: isScheduled,
          onChanged: onScheduledChanged,
          activeColor: colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Text(
          'Schedule for later',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ============================================
// PRIVATE INPUT FIELD COMPONENT
// ============================================

class _LocationInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final Color dotColor;
  final bool enabled;
  final ColorScheme colorScheme;
  final Widget? trailing;

  const _LocationInputField({
    required this.controller,
    this.focusNode,
    required this.hintText,
    required this.dotColor,
    required this.enabled,
    required this.colorScheme,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}