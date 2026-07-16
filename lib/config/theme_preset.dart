import 'package:flutter/material.dart';

enum ThemePreset {
  indigo(
    'Indigo Dream',
    Icons.auto_awesome,
    Color(0xFF6C63FF),
    Color(0xFF00D9FF),
  ),
  emerald(
    'Emerald Forest',
    Icons.eco,
    Color(0xFF059669),
    Color(0xFF6EE7B7),
  ),
  sunset(
    'Warm Sunset',
    Icons.wb_sunny,
    Color(0xFFEA580C),
    Color(0xFFFBBF24),
  ),
  ocean(
    'Ocean Breeze',
    Icons.water_drop,
    Color(0xFF2563EB),
    Color(0xFF38BDF8),
  ),
  rose(
    'Rose Garden',
    Icons.local_florist,
    Color(0xFFD946EF),
    Color(0xFFF472B6),
  );

  final String displayName;
  final IconData icon;
  final Color primaryColor;
  final Color accentColor;

  const ThemePreset(
    this.displayName,
    this.icon,
    this.primaryColor,
    this.accentColor,
  );
}
