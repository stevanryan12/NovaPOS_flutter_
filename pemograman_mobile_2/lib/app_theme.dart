import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─── Premium Emerald Design System (2026 Redesign) ───
/// Clean, modern, high-end SaaS POS design system with elegant Emerald Green brand.
/// Variable names are preserved for backward compatibility with all screens.
class AppTheme {
  AppTheme._();

  // ── Core Palette (Light Mode - Premium) ──
  static const Color background      = Color(0xFFFAFAFA); // Clean white-grey
  static const Color backgroundAlt   = Color(0xFFF0FDF4); // Emerald 50 tint
  static const Color surface         = Colors.white;
  static const Color surfaceLight    = Color(0xFFFAFAFA);
  static const Color surfaceBorder   = Color(0xFFE5E7EB); // Gray 200 soft border

  // ── Premium Dark (For Headers & Cards) ──
  static const Color slate900        = Color(0xFF064E3B); // Emerald 900
  static const Color slate800        = Color(0xFF065F46); // Emerald 800
  static const Color slate700        = Color(0xFF047857); // Emerald 700
  static const Color slate600        = Color(0xFF059669); // Emerald 600

  // ── Brand Primary (Emerald Green — replaces orange "gold") ──
  // NOTE: Variable names kept as "gold" to avoid breaking all other screens
  static const Color gold            = Color(0xFF059669); // Emerald 600
  static const Color goldLight       = Color(0xFF10B981); // Emerald 500
  static const Color goldDark        = Color(0xFF047857); // Emerald 700
  static const Color goldMuted       = Color(0x18059669); // Emerald 600 @ 9%
  static const Color goldSubtle      = Color(0x0A059669); // Emerald 600 @ 4%

  // ── Secondary (Teal) ──
  static const Color secondary       = Color(0xFF0D9488); // Teal 600
  static const Color secondaryLight  = Color(0xFF14B8A6); // Teal 500
  static const Color secondaryMuted  = Color(0x180D9488);

  // ── Accent (Blue) ──
  static const Color accent          = Color(0xFF2563EB); // Blue 600
  static const Color accentLight     = Color(0xFF3B82F6); // Blue 500
  static const Color accentMuted     = Color(0x182563EB);

  // ── Text (Neutral Gray for ultra-modern look) ──
  static const Color textPrimary     = Color(0xFF111827); // Gray 900
  static const Color textSecondary   = Color(0xFF6B7280); // Gray 500
  static const Color textMuted       = Color(0xFF9CA3AF); // Gray 400

  // ── Semantic ──
  static const Color success         = Color(0xFF059669); // Emerald Green
  static const Color successBg       = Color(0xFFECFDF5);
  static const Color error           = Color(0xFFDC2626);
  static const Color errorBg         = Color(0xFFFEF2F2);
  static const Color info            = Color(0xFF2563EB); // Modern Blue
  static const Color infoBg          = Color(0xFFEFF6FF);
  static const Color warning         = Color(0xFFF59E0B); // Amber 500
  static const Color warningBg       = Color(0xFFFFFBEB);

  // ── Radii (Modern, Premium Corners) ──
  static const double radiusCard     = 20.0;
  static const double radiusButton   = 14.0;
  static const double radiusInput    = 14.0;
  static const double radiusChip     = 24.0;
  static const double radiusSmall    = 10.0;

  // ── Shadows (Extremely soft and professional) ──
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: gold.withOpacity(0.18),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // ── Card Decoration ──
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radiusCard),
    border: Border.all(color: surfaceBorder.withOpacity(0.5), width: 1),
    boxShadow: cardShadow,
  );

  static BoxDecoration get cardDecorationGold => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radiusCard),
    border: Border.all(color: gold.withOpacity(0.15), width: 1),
    boxShadow: cardShadow,
  );

  static BoxDecoration get cardDecorationElevated => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radiusCard),
    border: Border.all(color: surfaceBorder.withOpacity(0.4), width: 1),
    boxShadow: elevatedShadow,
  );

  // ── Gradient Decorations ──
  static BoxDecoration get primaryGradientDecoration => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF059669), // Emerald 600
        Color(0xFF0D9488), // Teal 600
      ],
    ),
    borderRadius: BorderRadius.circular(radiusCard),
    boxShadow: glowShadow,
  );

  static BoxDecoration get headerGradientDecoration => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF064E3B), // Emerald 900
        Color(0xFF065F46), // Emerald 800
        Color(0xFF047857), // Emerald 700
      ],
    ),
    borderRadius: const BorderRadius.only(
      bottomLeft: Radius.circular(28),
      bottomRight: Radius.circular(28),
    ),
  );

  // ── Input Decoration ──
  static InputDecoration searchInputDecoration({String hint = 'Cari...'}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 14),
      prefixIcon: const Icon(Icons.search_rounded, color: textSecondary, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: surfaceBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: gold, width: 1.5),
      ),
    );
  }

  static InputDecoration formInputDecoration({required String label}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 13),
      floatingLabelStyle: GoogleFonts.inter(color: gold, fontWeight: FontWeight.w600),
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: surfaceBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: surfaceBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: gold, width: 1.5),
      ),
    );
  }

  // ── Button Styles ──
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: gold,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusButton),
    ),
    textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1),
  );

  static ButtonStyle get outlinedGoldButton => OutlinedButton.styleFrom(
    foregroundColor: gold,
    side: const BorderSide(color: gold, width: 1.5),
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusButton),
    ),
    textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
  );

  // ── Icon Container ──
  static Widget iconContainer({
    required IconData icon,
    Color color = gold,
    double size = 44,
    double iconSize = 22,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }

  // ── Badge / Pill widget ──
  static Widget badge({
    required String text,
    Color color = gold,
    double fontSize = 10,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radiusChip),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  // ── Section Title ──
  static Widget sectionTitle(String text, {EdgeInsets? padding}) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  // ── Full ThemeData ──
  static ThemeData get themeData => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    primaryColor: gold,
    colorScheme: const ColorScheme.light(
      primary: gold,
      secondary: secondary,
      tertiary: accent,
      surface: surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: gold),
      titleTextStyle: GoogleFonts.inter(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: gold,
      unselectedItemColor: textSecondary,
    ),
    cardTheme: CardThemeData(
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusCard),
        side: BorderSide(color: surfaceBorder.withOpacity(0.5), width: 1),
      ),
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusCard),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: slate800,
      contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
      behavior: SnackBarBehavior.floating,
    ),
    dividerColor: surfaceBorder,
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.inter(color: textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineMedium: GoogleFonts.inter(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleLarge: GoogleFonts.inter(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.inter(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.inter(color: textPrimary, fontSize: 14),
      bodyMedium: GoogleFonts.inter(color: textSecondary, fontSize: 13),
      bodySmall: GoogleFonts.inter(color: textMuted, fontSize: 11),
      labelLarge: GoogleFonts.inter(color: gold, fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );
}
