import 'package:flutter/material.dart';

/// Application-wide color constants and theme definitions.
///
/// Curated modern educational design palette matching Material 3:
/// - Primary Blue: #3478E5
/// - Dark Navy Text: #25364A
/// - Light Blue Background: #EAF6FC
/// - White Cards: #FFFFFF
/// - Success Green: #20B96B
/// - Error Red: #E5484D
/// - Secondary Text: #718096
/// - Borders: #DCE6EF
/// - Light Surface: #F4F9FD
class AppColors {
  AppColors._();

  // Primary Theme Colors
  static const Color primaryBlue = Color(0xFF3478E5);
  static const Color primaryDark = Color(0xFF1E5BB8);
  static const Color primaryCyan = Color(0xFF00B4D8);
  static const Color lightBlue = Color(0xFFEAF6FC);
  static const Color lightBlueAlt = Color(0xFFF4F9FD);
  static const Color surfaceLight = Color(0xFFF4F9FD);

  // Purple Accent (for student performance / badges)
  static const Color purpleStart = Color(0xFF7C3AED);
  static const Color purpleEnd = Color(0xFF6366F1);
  static const Color purpleDark = Color(0xFF5B21B6);

  // Card and Surface Colors
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x0D000000); // Subtle 5% shadow

  // Text Colors
  static const Color textPrimary = Color(0xFF25364A); // Dark navy text
  static const Color textSecondary = Color(0xFF718096); // Slate gray
  static const Color textLight = Color(0xFFA0AEC0);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Functional Status Colors
  static const Color green = Color(0xFF20B96B); // Success / Present
  static const Color greenLight = Color(0xFFE8F8F0);
  static const Color greenText = Color(0xFF137A44);

  static const Color red = Color(0xFFE5484D); // Error / Absent
  static const Color redLight = Color(0xFFFEECEE);
  static const Color redText = Color(0xFF9E1B23);

  static const Color orange = Color(0xFFF59E0B);
  static const Color orangeLight = Color(0xFFFEF3C7);

  static const Color yellow = Color(0xFFEAB308);

  // Border Colors
  static const Color borderLight = Color(0xFFDCE6EF); // Subtle modern border
  static const Color borderMedium = Color(0xFFCBD5E1);

  // Background Colors
  static const Color backgroundLight = Color(0xFFEAF6FC); // Clean light blue bg
  static const Color backgroundCard = cardWhite;

  // Icon Colors
  static const Color iconPrimary = primaryBlue;
  static const Color iconSecondary = textSecondary;
  static const Color iconWhite = textWhite;

  // Modern Subtle Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3478E5), Color(0xFF2B62C2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient welcomeGradient = LinearGradient(
    colors: [Color(0xFF3478E5), Color(0xFF1D54B3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [purpleStart, purpleEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [cardWhite, surfaceLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
