// ==================== widgets/rides_empty_state.dart ====================
import 'package:flutter/material.dart';
import '../../../../constants/app_dimensions.dart';

class RidesEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onPressed;

  const RidesEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // 🎨 Get theme colors
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIconContainer(colorScheme),
        const SizedBox(height: 24),
        _buildTitle(colorScheme),
        const SizedBox(height: 12),
        _buildSubtitle(colorScheme),
        if (buttonText != null && onPressed != null) ...[
          const SizedBox(height: 24),
          _buildActionButton(colorScheme),
        ],
      ],
    );
  }

  Widget _buildIconContainer(ColorScheme colorScheme) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(60),
      ),
      child: Icon(
        icon,
        color: colorScheme.onSurfaceVariant,
        size: 40,
      ),
    );
  }

  Widget _buildTitle(ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSubtitle(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Text(
        subtitle,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildActionButton(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingLarge),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            buttonText!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}