// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Neon accent palette ──────────────────────────────────────
class AppColors {
  AppColors._();

  // Backgrounds
  static const bg0      = Color(0xFF080B12);   // deepest void
  static const bg1      = Color(0xFF0D1117);   // card bg
  static const bg2      = Color(0xFF161B26);   // elevated card
  static const bg3      = Color(0xFF1E2636);   // input fill

  // Neon accents
  static const neonCyan   = Color(0xFF00E5FF);
  static const neonPurple = Color(0xFFBB00FF);
  static const neonGreen  = Color(0xFF00FF88);
  static const neonOrange = Color(0xFFFF6B00);
  static const neonRed    = Color(0xFFFF1744);

  // Category colours
  static const catCar        = Color(0xFFFF6B00);
  static const catBicycle    = Color(0xFF00FF88);
  static const catMotorcycle = Color(0xFFBB00FF);
  static const catRunning    = Color(0xFF00E5FF);

  // Rank tier colours
  static const tierBronze   = Color(0xFFCD7F32);
  static const tierSilver   = Color(0xFFC0C0C0);
  static const tierGold     = Color(0xFFFFD700);
  static const tierPlatinum = Color(0xFFE5E4E2);
  static const tierDiamond  = Color(0xFF00BFFF);
  static const tierElite    = Color(0xFFBB00FF);
  static const tierLegend   = Color(0xFFFF6B00);

  // Text
  static const textPrimary   = Color(0xFFE8EAED);
  static const textSecondary = Color(0xFF8B9CB1);
  static const textHint      = Color(0xFF4A5568);

  // Borders
  static const borderSubtle = Color(0xFF1E2D3D);
  static const borderActive = Color(0xFF00E5FF);
}

class AppTextStyles {
  AppTextStyles._();

  static const _orbitron = 'Orbitron';
  static const _rajdhani = 'Rajdhani';

  // Display – used for race numbers, gap distance
  static const displayXL = TextStyle(
    fontFamily: _orbitron, fontSize: 48, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: 2,
  );
  static const displayLG = TextStyle(
    fontFamily: _orbitron, fontSize: 32, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: 1.5,
  );

  // Headings
  static const h1 = TextStyle(
    fontFamily: _rajdhani, fontSize: 26, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: 0.5,
  );
  static const h2 = TextStyle(
    fontFamily: _rajdhani, fontSize: 20, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const h3 = TextStyle(
    fontFamily: _rajdhani, fontSize: 17, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body
  static const body = TextStyle(
    fontFamily: _rajdhani, fontSize: 15, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static const bodySmall = TextStyle(
    fontFamily: _rajdhani, fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // Label
  static const label = TextStyle(
    fontFamily: _rajdhani, fontSize: 12, fontWeight: FontWeight.w600,
    color: AppColors.textSecondary, letterSpacing: 1.2,
  );
}

// ── Theme definition ─────────────────────────────────────────
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg0,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.neonCyan,
      secondary: AppColors.neonPurple,
      surface: AppColors.bg1,
      error: AppColors.neonRed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg0,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyles.h2,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),
    fontFamily: 'Rajdhani',
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bg3,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.neonCyan, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.neonRed),
      ),
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
      labelStyle: AppTextStyles.bodySmall,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.neonCyan,
        foregroundColor: AppColors.bg0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTextStyles.h3.copyWith(color: AppColors.bg0),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.neonCyan,
        side: const BorderSide(color: AppColors.neonCyan),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTextStyles.h3,
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.borderSubtle),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bg1,
      selectedItemColor: AppColors.neonCyan,
      unselectedItemColor: AppColors.textHint,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.bg2,
      contentTextStyle: AppTextStyles.body,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ── Gradient helpers ─────────────────────────────────────────
extension GradientX on AppColors {
  static const neonGlow = LinearGradient(
    colors: [AppColors.neonCyan, AppColors.neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const cardGlow = LinearGradient(
    colors: [Color(0xFF0D1B2A), Color(0xFF131D2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

Color categoryColor(String cat) => switch (cat) {
  'car'        => AppColors.catCar,
  'bicycle'    => AppColors.catBicycle,
  'motorcycle' => AppColors.catMotorcycle,
  'running'    => AppColors.catRunning,
  _            => AppColors.neonCyan,
};

Color tierColor(String tier) => switch (tier) {
  'bronze'   => AppColors.tierBronze,
  'silver'   => AppColors.tierSilver,
  'gold'     => AppColors.tierGold,
  'platinum' => AppColors.tierPlatinum,
  'diamond'  => AppColors.tierDiamond,
  'elite'    => AppColors.tierElite,
  'legend'   => AppColors.tierLegend,
  _          => AppColors.textHint,
};