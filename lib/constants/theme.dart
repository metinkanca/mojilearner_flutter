import 'package:flutter/material.dart';

class AppTheme {
  // Old palette
  static const Color primaryOld = Color(0xFF6366F1); 
  static const Color secondary = Color(0xFFA855F7); 
  
  // New Palette based on Design
  static const Color primary = Color(0xFF84cc16); // Lime green
  static const Color skyBlue = Color(0xFF38bdf8);
  static const Color grassGreen = Color(0xFF22c55e);
  static const Color darkBackground = Color(0xFF0F172A);
  
  static const Color text = Color(0xFF1F2937); // Darker text for light mode
  static const Color textLight = Color(0xFFF8FAFC);
  
  static const double radius = 24.0; // Rounder
  static const double padding = 16.0;

  // Restored / Mapped legacy properties for compatibility
  static const Color background = Color(0xFFF1F5F9); // Light background for other screens
  static const Color card = Colors.white; 
  static const Color textSecondary = Color(0xFF64748B); // Slate 500

  // Retro Theme Colors
  static const Color retroSky = Color(0xFF639bff);
  static const Color retroGrass = Color(0xFF6abe30);
  static const Color retroGrassDark = Color(0xFF4b8f1d);
  static const Color retroDark = Color(0xFF211f1f);
  static const Color retroLight = Color(0xFFfbf7f3);
  static const Color retroUi = Color(0xFFeec39a);
  static const Color retroPrimary = Color(0xFFd95763);
  static const Color retroAccent = Color(0xFFfbf236);
  
  // Aliases/Additional Retro Colors
  static const Color retroBlue = retroSky;
  static const Color retroGreen = retroGrass;
  static const Color retroOrange = Color(0xFFdf7126);
}
