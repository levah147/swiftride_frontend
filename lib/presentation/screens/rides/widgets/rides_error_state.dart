// ==================== widgets/rides_error_state.dart ====================
import 'package:flutter/material.dart';
import '../../../../constants/app_strings.dart';

class RidesErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const RidesErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // 🎨 Get theme colors
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildErrorIcon(colorScheme),
          const SizedBox(height: 16),
          _buildErrorTitle(colorScheme),
          const SizedBox(height: 8),
          _buildErrorMessage(colorScheme),
          const SizedBox(height: 24),
          _buildRetryButton(colorScheme),
        ],
      ),
    );
  }

  Widget _buildErrorIcon(ColorScheme colorScheme) {
    return Icon(
      Icons.error_outline,
      color: colorScheme.onSurfaceVariant,
      size: 64,
    );
  }

  Widget _buildErrorTitle(ColorScheme colorScheme) {
    return Text(
      AppStrings.failedToLoadRides,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildErrorMessage(ColorScheme colorScheme) {
    return Text(
      error,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 14,
      ),
    );
  }

  Widget _buildRetryButton(ColorScheme colorScheme) {
    return ElevatedButton(
      onPressed: onRetry,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      ),
      child: const Text(AppStrings.retry),
    );
  }
}