import 'package:flutter/material.dart';

/// Application-wide color constants and theme definitions.
/// 
/// This file centralizes all color definitions to ensure consistency
/// across the entire application. Based on the modern dashboard design
/// with light blue backgrounds and purple gradient accents.
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary Colors - Based on dashboard theme
  static const Color primaryBlue = Color(0xFF4A90E2); // Main blue
  static const Color primaryCyan = Color(0xFF50E3C2); // Cyan accent
  static const Color lightBlue = Color(0xFFE8F4F8); // Light blue background
  static const Color lightBlueAlt = Color(0xFFF0F8FF); // Alternative light blue

  // Purple Gradient Colors (for CGPA card and important sections)
  static const Color purpleStart = Color(0xFF9B59B6); // Purple gradient start
  static const Color purpleEnd = Color(0xFF6C5CE7); // Purple gradient end
  static const Color purpleDark = Color(0xFF8E44AD); // Dark purple

  // Card and Surface Colors
  static const Color cardWhite = Color(0xFFFFFFFF); // White cards
  static const Color cardShadow = Color(0x1A000000); // Card shadow (10% opacity)

  // Text Colors
  static const Color textPrimary = Color(0xFF2C3E50); // Dark text
  static const Color textSecondary = Color(0xFF7F8C8D); // Gray text
  static const Color textLight = Color(0xFF95A5A6); // Light gray text
  static const Color textWhite = Color(0xFFFFFFFF); // White text

  // Accent Colors
  static const Color orange = Color(0xFFFF6B6B); // Orange for labels/badges
  static const Color green = Color(0xFF2ECC71); // Green for success/positive
  static const Color red = Color(0xFFE74C3C); // Red for errors/negative
  static const Color yellow = Color(0xFFF39C12); // Yellow for warnings

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [purpleStart, purpleEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [cardWhite, lightBlueAlt],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Background Colors
  static const Color backgroundLight = Color(0xFFBFE7F5); // Main app background - Updated color
  static const Color backgroundCard = cardWhite; // Card background

  // Border Colors
  static const Color borderLight = Color(0xFFE0E0E0); // Light border
  static const Color borderMedium = Color(0xFFBDBDBD); // Medium border

  // Icon Colors
  static const Color iconPrimary = primaryBlue; // Primary icon color
  static const Color iconSecondary = textSecondary; // Secondary icon color
  static const Color iconWhite = textWhite; // White icons
}

