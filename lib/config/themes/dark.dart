import 'package:flutter/material.dart';
import 'package:app_eps/config/themes/colors_extension.dart';

ThemeData buildDarkTheme() {
  const brightness = Brightness.dark;

  const Color background = Color(0xFF000000);
  const Color foreground = Color(0xFFFFFFFF);
  const Color card = Color(0xFF090909);
  const Color cardForeground = Color(0xFF353535);
  const Color popover = Color(0xFF121212);
  const Color popoverForeground = Color(0xFFFFFFFF);
  const Color primary = Color(0xFF06b6d4);
  const Color primaryForeground = Color(0xFF000000);
  const Color secondary = Color(0xFF222222);
  const Color secondaryForeground = Color(0xFFFFFFFF);
  const Color muted = Color(0xFF1D1D1D);
  const Color mutedForeground = Color(0xFFA4A4A4);
  const Color accent = Color(0xFF333333);
  const Color accentForeground = Color(0xFFFFFFFF);
  const Color standardBase = Color(0xFFA957F7);
  const Color successBase = Color(0xFF20C45F);
  const Color destructive = Color(0x807F201F);
  const Color destructiveBase = Color(0xFFF14445);
  const Color destructiveForeground = Color(0xFFFBA7A6);
  const Color warningBase = Color(0xFFEBB517);
  const Color infoBase = Color(0xFF00A4E8);
  const Color border = Color(0xFF353535);
  const Color input = Color(0xFF000000);
  const Color ring = Color(0xFFFFFFFF);

  final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.dark,
  ).copyWith(
    primary: primary,
    onPrimary: primaryForeground,
    secondary: secondary,
    onSecondary: secondaryForeground,
    surface: background,
    onSurface: foreground,
    error: destructiveBase,
    onError: destructiveForeground,
    outline: cardForeground,
    tertiary: muted,
    onTertiary: mutedForeground,
  );

  return ThemeData(
    brightness: brightness,
    useMaterial3: true,
    colorScheme: darkColorScheme,
    scaffoldBackgroundColor: darkColorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: darkColorScheme.surface,
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
      fillColor: input,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ring, width: 1),
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
          borderRadius: BorderRadius.circular(10),
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
          color: border,
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
        secondary: Color(0xFF222222),
        standard: Color(0x80581A88),
        standardBase: Color(0xFFA957F7),
        standardForeground: Color(0xFFD9B5FF),
        success: Color(0x8012522D),
        successBase: Color(0xFF20C45F),
        successForeground: Color(0xFF84EFAA),
        destructive: Color(0x807F201F),
        destructiveBase: Color(0xFFF14445),
        destructiveForeground: Color(0xFFFBA7A6),
        warning: Color(0x80713F11),
        warningBase: Color(0xFFEBB517),
        warningForeground: Color(0xFFFFE141),
        info: Color(0x80124A6C),
        infoBase: Color(0xFF00A4E8),
        infoForeground: Color(0xFF7FD4FC),
      ),
    ],
  );
}
