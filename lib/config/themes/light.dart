import 'package:flutter/material.dart';
import 'package:app_eps/config/themes/colors_extension.dart';

ThemeData buildLightTheme() {
  const brightness = Brightness.light;

  const Color background = Color(0xFFFCFCFC);
  const Color foreground = Color(0xFF000000);
  const Color card = Color(0xFFFFFFFF);
  const Color cardForeground = Color(0xFFFCFCFC);
  const Color popover = Color(0xFFFCFCFC);
  const Color popoverForeground = Color(0xFF000000);
  const Color primary = Color(0xFF06b6d4);
  const Color primaryForeground = Color(0xFFFFFFFF);
  const Color secondary = Color(0xFFEBEBEB);
  const Color secondaryForeground = Color(0xFF000000);
  const Color muted = Color(0xFFF5F5F5);
  const Color mutedForeground = Color(0xFF525252);
  const Color accent = Color(0xFFEBEBEB);
  const Color accentForeground = Color(0xFF000000);
  const Color standardBase = Color(0xFFA957F7);
  const Color successBase = Color(0xFF20C45F);
  const Color destructive = Color(0xFFFFE4E4);
  const Color destructiveBase = Color(0xFFF14445);
  const Color destructiveForeground = Color(0xFF971B1A);
  const Color warningBase = Color(0xFFEBB517);
  const Color infoBase = Color(0xFF00A4E8);
  const Color border = Color(0xFF000000);
  const Color input = Color(0xFFFCFCFC);
  const Color ring = Color(0xFFE4E4E4);

  final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: primary,
    onPrimary: primaryForeground,
    secondary: secondary,
    onSecondary: secondaryForeground,
    surface: background,
    onSurface: foreground,
    error: destructiveBase,
    onError: destructiveForeground,
    outline: ring,
    tertiary: muted,
    onTertiary: mutedForeground,
  );

  return ThemeData(
    brightness: brightness,
    useMaterial3: true,
    colorScheme: lightColorScheme,
    scaffoldBackgroundColor: lightColorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: lightColorScheme.surface,
      foregroundColor: foreground,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: foreground),
      titleTextStyle: const TextStyle(color: foreground, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    cardTheme: CardTheme(
      color: card,
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(
          color: cardForeground,
          width: 1,
        ),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 14.0, color: foreground),
      bodyMedium: TextStyle(color: foreground),
      titleLarge: TextStyle(color: foreground),
      titleMedium: TextStyle(color: foreground),
      titleSmall: TextStyle(color: foreground),
    ),
    inputDecorationTheme: InputDecorationTheme(
      prefixIconColor: primary,
      filled: true,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
      fillColor: input,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ring, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: destructiveBase, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: destructiveBase, width: 1),
      ),
      labelStyle: const TextStyle(color: mutedForeground),
      hintStyle: const TextStyle(color: mutedForeground),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: primaryForeground,
        backgroundColor: primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: const TextStyle(fontSize: 16),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: primaryForeground,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(
          color: input,
          width: 1,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      showCheckmark: false,
      selectedColor: primary,
      secondaryLabelStyle: const TextStyle(color: primaryForeground, fontWeight: FontWeight.w700),
      labelStyle: const TextStyle(color: secondaryForeground),
    ),
    extensions: const <ThemeExtension<dynamic>>[
      ColorsExtension(
        secondary: Color(0xFFEBEBEB),
        standard: Color(0xFFF4EAFF),
        standardBase: Color(0xFFA957F7),
        standardForeground: Color(0xFF6C20A9),
        success: Color(0xFFDDFAE7),
        successBase: Color(0xFF20C45F),
        successForeground: Color(0xFF166634),
        destructive: Color(0xFFFFE4E4),
        destructiveBase: Color(0xFFF14445),
        destructiveForeground: Color(0xFF971B1A),
        warning: Color(0xFFFDF8C1),
        warningBase: Color(0xFFEBB517),
        warningForeground: Color(0xFF854F15),
        info: Color(0xFFDDF2FF),
        infoBase: Color(0xFF00A4E8),
        infoForeground: Color(0xFF065884),
      ),
    ],
  );
}
