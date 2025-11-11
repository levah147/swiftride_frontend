import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors - Vibrant Electric Blue (modern, premium feel)
  static const Color primary = Color(0xFF0066FF); // Vibrant electric blue
  static const Color primaryDark = Color(0xFF0052CC);
  static const Color primaryLight = Color(0xFF3D8BFF);
  static const Color primaryVeryLight = Color(0xFFE6F0FF);

  // Secondary colors - Energetic Purple (premium, modern)
  static const Color secondary = Color(0xFF7C3AED); // Vibrant purple
  static const Color secondaryDark = Color(0xFF5B21B6);
  static const Color secondaryLight = Color(0xFF9F7AEA);

  // Accent colors - Electric Cyan (energy, movement)
  static const Color accent = Color(0xFF00D9FF); // Bright cyan
  static const Color accentDark = Color(0xFF00B8D4);
  static const Color accentLight = Color(0xFF4DE6FF);

  // Background colors (Dark theme optimized)
  static const Color backgroundPrimary = Color(0xFF0A0A0A); // Deep black
  static const Color backgroundSecondary = Color(0xFF1A1A1A); // Slightly lighter
  static const Color surface = Color(0xFF262626); // Card/surface color
  static const Color surfaceLight = Color(0xFF333333); // Elevated surfaces

  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color.fromARGB(255, 0, 0, 0);
  
  // Grey shades (optimized for dark theme)
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

  // Text colors (Dark theme)
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure white
  static const Color textSecondary = Color(0xFFB3B3B3); // Light grey
  static const Color textTertiary = Color(0xFF808080); // Medium grey
  static const Color textHint = Color(0xFF666666); // Dark grey
  static const Color textDisabled = Color(0xFF4D4D4D); // Very dark grey

  // Status colors (Modern, saturated)
  static const Color success = Color(0xFF10B981); // Modern green
  static const Color successLight = Color(0xFF34D399);
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444); // Modern red
  static const Color errorLight = Color(0xFFF87171);
  static const Color info = Color(0xFF3B82F6); // Modern blue
  static const Color infoLight = Color(0xFF60A5FA);

  // Ride-hailing specific colors
  static const Color pickup = Color(0xFF10B981); // Green for pickup
  static const Color dropoff = Color(0xFFEF4444); // Red for dropoff
  static const Color route = Color(0xFF0066FF); // Blue for route
  static const Color driver = Color(0xFFF59E0B); // Amber for driver location
  static const Color activeRide = Color(0xFF7C3AED); // Purple for active rides

  // Social login colors
  static const Color google = Color(0xFF4285F4);
  static const Color facebook = Color(0xFF1877F2);
  static const Color apple = Color(0xFFFFFFFF);

  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0066FF), Color(0xFF00D9FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF0066FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Transparent overlays
  static const Color overlay = Color(0xCC000000); // 80% black
  static const Color overlayMedium = Color(0x99000000); // 60% black
  static const Color overlayLight = Color(0x66000000); // 40% black
  static const Color overlayVeryLight = Color(0x33000000); // 20% black

  // Shimmer/Loading colors
  static const Color shimmerBase = Color(0xFF262626);
  static const Color shimmerHighlight = Color(0xFF333333);

  // Border colors
  static const Color border = Color(0xFF333333);
  static const Color borderLight = Color(0xFF404040);
  static const Color borderDark = Color(0xFF262626);

  // Special UI colors
  static const Color divider = Color(0xFF2A2A2A);
  static const Color shadow = Color(0x40000000);
  static const Color ripple = Color(0x1AFFFFFF);
}