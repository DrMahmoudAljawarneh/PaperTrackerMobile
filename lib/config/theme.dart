import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paper_tracker/config/theme_preset.dart';
import 'package:paper_tracker/models/paper.dart';

class _ThemePalette {
  final Color primary, primaryLight, primaryDark, accent;
  final Color surface, card, cardLight, background;
  final Color textPrimary, textSecondary, textMuted, divider;
  final Color error, success, warning;
  final List<Color> gradientColors;

  const _ThemePalette({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.accent,
    required this.surface,
    required this.card,
    required this.cardLight,
    required this.background,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
    required this.error,
    required this.success,
    required this.warning,
    required this.gradientColors,
  });

  _ThemePalette copyWith({Color? accent}) {
    return _ThemePalette(
      primary: primary,
      primaryLight: primaryLight,
      primaryDark: primaryDark,
      accent: accent ?? this.accent,
      surface: surface,
      card: card,
      cardLight: cardLight,
      background: background,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textMuted: textMuted,
      divider: divider,
      error: error,
      success: success,
      warning: warning,
      gradientColors: gradientColors,
    );
  }
}

const Color _error = Color(0xFFEF4444);
const Color _success = Color(0xFF22C55E);
const Color _warning = Color(0xFFF59E0B);

// ── Dark Palettes ───────────────────────────────────────────
const _indigoDark = _ThemePalette(
  primary: Color(0xFF6C63FF),
  primaryLight: Color(0xFF8B83FF),
  primaryDark: Color(0xFF4A42E8),
  accent: Color(0xFF00D9FF),
  surface: Color(0xFF1E1E2E),
  card: Color(0xFF2A2A3C),
  cardLight: Color(0xFF32324A),
  background: Color(0xFF14141F),
  textPrimary: Color(0xFFF0F0F5),
  textSecondary: Color(0xFF9CA3AF),
  textMuted: Color(0xFF6B7280),
  divider: Color(0xFF374151),
  error: _error,
  success: _success,
  warning: _warning,
  gradientColors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
);

const _emeraldDark = _ThemePalette(
  primary: Color(0xFF059669),
  primaryLight: Color(0xFF34D399),
  primaryDark: Color(0xFF047857),
  accent: Color(0xFF6EE7B7),
  surface: Color(0xFF1A2E1A),
  card: Color(0xFF243C24),
  cardLight: Color(0xFF2D4A2D),
  background: Color(0xFF0F1F0F),
  textPrimary: Color(0xFFECFDF5),
  textSecondary: Color(0xFFA7F3D0),
  textMuted: Color(0xFF6EE7B7),
  divider: Color(0xFF374151),
  error: _error,
  success: _success,
  warning: _warning,
  gradientColors: [Color(0xFF0F1F0F), Color(0xFF1A2E1A), Color(0xFF243C24)],
);

const _sunsetDark = _ThemePalette(
  primary: Color(0xFFEA580C),
  primaryLight: Color(0xFFFB923C),
  primaryDark: Color(0xFFC2410C),
  accent: Color(0xFFFBBF24),
  surface: Color(0xFF2E1A1A),
  card: Color(0xFF3C2424),
  cardLight: Color(0xFF4A2E2E),
  background: Color(0xFF1F0F0F),
  textPrimary: Color(0xFFFFF7ED),
  textSecondary: Color(0xFFFDBA74),
  textMuted: Color(0xFFFB923C),
  divider: Color(0xFF374151),
  error: _error,
  success: _success,
  warning: _warning,
  gradientColors: [Color(0xFF1F0F0F), Color(0xFF2E1A1A), Color(0xFF3C2424)],
);

const _oceanDark = _ThemePalette(
  primary: Color(0xFF2563EB),
  primaryLight: Color(0xFF60A5FA),
  primaryDark: Color(0xFF1D4ED8),
  accent: Color(0xFF38BDF8),
  surface: Color(0xFF1A1E2E),
  card: Color(0xFF24283C),
  cardLight: Color(0xFF2E324A),
  background: Color(0xFF0F1420),
  textPrimary: Color(0xFFEFF6FF),
  textSecondary: Color(0xFF93C5FD),
  textMuted: Color(0xFF60A5FA),
  divider: Color(0xFF374151),
  error: _error,
  success: _success,
  warning: _warning,
  gradientColors: [Color(0xFF0F1420), Color(0xFF1A1E2E), Color(0xFF24283C)],
);

const _roseDark = _ThemePalette(
  primary: Color(0xFFD946EF),
  primaryLight: Color(0xFFF0ABFC),
  primaryDark: Color(0xFFA21CAF),
  accent: Color(0xFFF472B6),
  surface: Color(0xFF2E1A2E),
  card: Color(0xFF3C243C),
  cardLight: Color(0xFF4A2E4A),
  background: Color(0xFF1F0F1F),
  textPrimary: Color(0xFFFDF4FF),
  textSecondary: Color(0xFFF5D0FE),
  textMuted: Color(0xFFF0ABFC),
  divider: Color(0xFF374151),
  error: _error,
  success: _success,
  warning: _warning,
  gradientColors: [Color(0xFF1F0F1F), Color(0xFF2E1A2E), Color(0xFF3C243C)],
);

// ── Light Palettes ──────────────────────────────────────────
const _indigoLight = _ThemePalette(
  primary: Color(0xFF5A52E6),
  primaryLight: Color(0xFF7C73FF),
  primaryDark: Color(0xFF4A42E8),
  accent: Color(0xFF00D9FF),
  surface: Color(0xFFFFFFFF),
  card: Color(0xFFFFFFFF),
  cardLight: Color(0xFFF3F4F6),
  background: Color(0xFFF9FAFB),
  textPrimary: Color(0xFF111827),
  textSecondary: Color(0xFF4B5563),
  textMuted: Color(0xFF9CA3AF),
  divider: Color(0xFFE5E7EB),
  error: _error,
  success: _success,
  warning: _warning,
  gradientColors: [Color(0xFFEDE9FE), Color(0xFFC7D2FE), Color(0xFFA5B4FC)],
);

const _emeraldLight = _ThemePalette(
  primary: Color(0xFF059669),
  primaryLight: Color(0xFF34D399),
  primaryDark: Color(0xFF047857),
  accent: Color(0xFF10B981),
  surface: Color(0xFFFFFFFF),
  card: Color(0xFFFFFFFF),
  cardLight: Color(0xFFF0FDF4),
  background: Color(0xFFF0FDF4),
  textPrimary: Color(0xFF111827),
  textSecondary: Color(0xFF4B5563),
  textMuted: Color(0xFF9CA3AF),
  divider: Color(0xFFD1FAE5),
  error: _error,
  success: _success,
  warning: _warning,
  gradientColors: [Color(0xFFD1FAE5), Color(0xFFA7F3D0), Color(0xFF6EE7B7)],
);

const _sunsetLight = _ThemePalette(
  primary: Color(0xFFEA580C),
  primaryLight: Color(0xFFFB923C),
  primaryDark: Color(0xFFC2410C),
  accent: Color(0xFFFBBF24),
  surface: Color(0xFFFFFFFF),
  card: Color(0xFFFFFFFF),
  cardLight: Color(0xFFFFF7ED),
  background: Color(0xFFFFF7ED),
  textPrimary: Color(0xFF111827),
  textSecondary: Color(0xFF4B5563),
  textMuted: Color(0xFF9CA3AF),
  divider: Color(0xFFFED7AA),
  error: _error,
  success: _success,
  warning: _warning,
  gradientColors: [Color(0xFFFFEDD5), Color(0xFFFED7AA), Color(0xFFFDBA74)],
);

const _oceanLight = _ThemePalette(
  primary: Color(0xFF2563EB),
  primaryLight: Color(0xFF60A5FA),
  primaryDark: Color(0xFF1D4ED8),
  accent: Color(0xFF38BDF8),
  surface: Color(0xFFFFFFFF),
  card: Color(0xFFFFFFFF),
  cardLight: Color(0xFFEFF6FF),
  background: Color(0xFFEFF6FF),
  textPrimary: Color(0xFF111827),
  textSecondary: Color(0xFF4B5563),
  textMuted: Color(0xFF9CA3AF),
  divider: Color(0xFFBFDBFE),
  error: _error,
  success: _success,
  warning: _warning,
  gradientColors: [Color(0xFFDBEAFE), Color(0xFFBFDBFE), Color(0xFF93C5FD)],
);

const _roseLight = _ThemePalette(
  primary: Color(0xFFD946EF),
  primaryLight: Color(0xFFF0ABFC),
  primaryDark: Color(0xFFA21CAF),
  accent: Color(0xFFF472B6),
  surface: Color(0xFFFFFFFF),
  card: Color(0xFFFFFFFF),
  cardLight: Color(0xFFFDF4FF),
  background: Color(0xFFFDF4FF),
  textPrimary: Color(0xFF111827),
  textSecondary: Color(0xFF4B5563),
  textMuted: Color(0xFF9CA3AF),
  divider: Color(0xFFF5D0FE),
  error: _error,
  success: _success,
  warning: _warning,
  gradientColors: [Color(0xFFFAE8FF), Color(0xFFF5D0FE), Color(0xFFF0ABFC)],
);

// ── Map preset → (dark, light) ─────────────────────────────
const _palettes = <ThemePreset, (_ThemePalette, _ThemePalette)>{
  ThemePreset.indigo: (_indigoDark, _indigoLight),
  ThemePreset.emerald: (_emeraldDark, _emeraldLight),
  ThemePreset.sunset: (_sunsetDark, _sunsetLight),
  ThemePreset.ocean: (_oceanDark, _oceanLight),
  ThemePreset.rose: (_roseDark, _roseLight),
};

// ─────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  // Backward-compatible static color constants (Indigo default)
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B83FF);
  static const Color primaryDark = Color(0xFF4A42E8);
  static const Color accentColor = Color(0xFF00D9FF);
  static const Color surfaceColor = Color(0xFF1E1E2E);
  static const Color cardColor = Color(0xFF2A2A3C);
  static const Color cardColorLight = Color(0xFF32324A);
  static const Color backgroundColor = Color(0xFF14141F);
  static const Color errorColor = Color(0xFFFF6B6B);
  static const Color successColor = Color(0xFF4ADE80);
  static const Color warningColor = Color(0xFFFFD93D);
  static const Color textPrimary = Color(0xFFF0F0F5);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color dividerColor = Color(0xFF374151);

  static const Color primaryColorL = Color(0xFF5A52E6);
  static const Color surfaceColorL = Color(0xFFFFFFFF);
  static const Color cardColorL = Color(0xFFFFFFFF);
  static const Color cardColorLightL = Color(0xFFF3F4F6);
  static const Color backgroundColorL = Color(0xFFF9FAFB);
  static const Color textPrimaryL = Color(0xFF111827);
  static const Color textSecondaryL = Color(0xFF4B5563);
  static const Color textMutedL = Color(0xFF9CA3AF);
  static const Color dividerColorL = Color(0xFFE5E7EB);

  // Convenience getters for the default (Indigo) themes
  static ThemeData get darkTheme =>
      getTheme(ThemePreset.indigo, Brightness.dark);
  static ThemeData get lightTheme =>
      getTheme(ThemePreset.indigo, Brightness.light);

  // ── Public theme selector ─────────────────────────────────
  static ThemeData getTheme(ThemePreset preset, Brightness brightness,
      {Color? customAccent}) {
    final isDark = brightness == Brightness.dark;
    final pair = _palettes[preset]!;
    var p = isDark ? pair.$1 : pair.$2;
    if (customAccent != null) {
      p = p.copyWith(accent: customAccent);
    }
    return _buildTheme(p, brightness);
  }

  // ── ThemeData builder ─────────────────────────────────────
  static ThemeData _buildTheme(_ThemePalette p, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: p.primary,
              secondary: p.accent,
              surface: p.surface,
              error: p.error,
              onPrimary: Colors.white,
              onSecondary: Colors.black,
              onSurface: p.textPrimary,
              onError: Colors.white,
            )
          : ColorScheme.light(
              primary: p.primary,
              secondary: p.accent,
              surface: p.surface,
              error: p.error,
              onPrimary: Colors.white,
              onSecondary: Colors.black,
              onSurface: p.textPrimary,
              onError: Colors.white,
            ),
      scaffoldBackgroundColor: p.background,
      cardColor: p.card,
      dividerColor: p.divider,
      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          displayLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
              letterSpacing: -0.5),
          displayMedium: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
              letterSpacing: -0.5),
          headlineLarge: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w600, color: p.textPrimary),
          headlineMedium: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w600, color: p.textPrimary),
          titleLarge: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w600, color: p.textPrimary),
          titleMedium: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w500, color: p.textPrimary),
          bodyLarge: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w400, color: p.textPrimary),
          bodyMedium: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w400, color: p.textSecondary),
          labelLarge: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: p.textPrimary),
          labelMedium: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: p.textSecondary),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? p.background : p.surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
            fontSize: 22, fontWeight: FontWeight.w600, color: p.textPrimary),
        iconTheme: IconThemeData(color: p.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isDark
              ? BorderSide.none
              : BorderSide(color: p.divider, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          side: BorderSide(color: p.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.cardLight,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: p.divider, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: p.primary, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: p.error, width: 1)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: p.textMuted),
        labelStyle: TextStyle(color: p.textSecondary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.cardLight,
        selectedColor: p.primary.withValues(alpha: 0.3),
        labelStyle: TextStyle(color: p.textPrimary, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        selectedItemColor: p.primary,
        unselectedItemColor: p.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.card,
        contentTextStyle: TextStyle(color: p.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.outfit(
            fontSize: 20, fontWeight: FontWeight.w600, color: p.textPrimary),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.primary,
        unselectedLabelColor: p.textMuted,
        indicatorColor: p.primary,
        labelStyle:
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  // ── Status Colors (fixed, not theme-dependent) ────────────
  static Color statusColor(PaperStatus status) {
    switch (status) {
      case PaperStatus.idea:
        return const Color(0xFFA78BFA);
      case PaperStatus.drafting:
        return const Color(0xFF60A5FA);
      case PaperStatus.writing:
        return const Color(0xFF38BDF8);
      case PaperStatus.internalReview:
        return const Color(0xFFFBBF24);
      case PaperStatus.submitted:
        return const Color(0xFF34D399);
      case PaperStatus.underReview:
        return const Color(0xFFF97316);
      case PaperStatus.revision:
        return const Color(0xFFFF6B6B);
      case PaperStatus.accepted:
        return const Color(0xFF4ADE80);
      case PaperStatus.published:
        return const Color(0xFF22D3EE);
      case PaperStatus.rejected:
        return const Color(0xFFEF4444);
    }
  }

  static Color priorityColor(PaperPriority priority) {
    switch (priority) {
      case PaperPriority.high:
        return const Color(0xFFEF4444);
      case PaperPriority.medium:
        return const Color(0xFFFBBF24);
      case PaperPriority.low:
        return const Color(0xFF4ADE80);
    }
  }

  // ── Decorations ───────────────────────────────────────────
  static BoxDecoration glassmorphismDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return BoxDecoration(
      color: theme.cardColor
          .withValues(alpha: isDark ? 0.6 : 0.8),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration gradientDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                surface,
                surface.withValues(alpha: 0.8),
                primary.withValues(alpha: 0.3),
              ]
            : [
                surface,
                theme.scaffoldBackgroundColor,
                primary.withValues(alpha: 0.1),
              ],
      ),
    );
  }
}
