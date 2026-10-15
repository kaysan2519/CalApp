import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF10B981); // Emerald Green
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryLight = Color(0xFF34D399);

  // Macro Semantic Colors
  static const Color protein = Color(0xFF6366F1); // Indigo
  static const Color carbs = Color(0xFFF97316);   // Energetic Warm Orange
  static const Color fat = Color(0xFFF59E0B);     // Golden Amber
  static const Color calories = Color(0xFF10B981);// Emerald Green

  // Dark Theme Surfaces
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B);    // Slate 800
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkCardElevated = Color(0xFF243248);
  static const Color darkBorder = Color(0xFF334155);    // Slate 700
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Light Theme Surfaces
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Status & Feedback
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Gradients for Modern Visual Accents
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF162032)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient proteinGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient carbsGradient = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient fatGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient waterGradient = LinearGradient(
    colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
