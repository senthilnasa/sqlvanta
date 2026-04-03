import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF1565C0); // Deep blue
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color accent = Color(0xFF00ACC1); // Cyan accent

  // Dark theme surface colors (SQLyog-inspired)
  static const Color darkBackground = Color(0xFF1E1E1E);
  static const Color darkSurface = Color(0xFF252526);
  static const Color darkSidebar = Color(0xFF2D2D2D);
  static const Color darkBorder = Color(0xFF3C3C3C);
  static const Color darkTabBar = Color(0xFF2D2D30);

  // Light theme surface colors
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSidebar = Color(0xFFEEEEEE);
  static const Color lightBorder = Color(0xFFDDDDDD);

  // Editor
  static const Color editorDarkBackground = Color(0xFF1E1E1E);
  static const Color editorLightBackground = Color(0xFFFFFFFF);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // SQL keyword colors (syntax highlighting)
  static const Color sqlKeyword = Color(0xFF569CD6);
  static const Color sqlString = Color(0xFFCE9178);
  static const Color sqlComment = Color(0xFF6A9955);
  static const Color sqlFunction = Color(0xFFDCDCAA);
  static const Color sqlNumber = Color(0xFFB5CEA8);
  static const Color sqlNull = Color(0xFF4EC9B0);

  // Connection color tags
  static const List<Color> connectionTags = [
    Color(0xFF4CAF50), // green — dev
    Color(0xFF2196F3), // blue — staging
    Color(0xFFF44336), // red — production
    Color(0xFFFF9800), // orange — qa
    Color(0xFF9C27B0), // purple — analytics
    Color(0xFF00BCD4), // cyan
  ];
}
