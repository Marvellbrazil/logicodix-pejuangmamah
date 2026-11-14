import 'package:flutter/material.dart';

abstract final class Surfaces {
  static const base = Color(0xFF070F11);
  static const surface = Color(0xFF0B1416);
  static const raised = Color(0xFF111D20);
  static const overlay = Color(0xFF17262A);
  static const line = Color(0xFF21363B);
  static const lineSoft = Color(0xFF17272B);
}

abstract final class Accent {
  static const teal = Color(0xFF2EE6C5);
  static const tealDeep = Color(0xFF0F8C7B);
  static const tealInk = Color(0xFF04231F);
  static const tealWash = Color(0x1F2EE6C5);
  static const amber = Color(0xFFF5B33C);
  static const amberWash = Color(0x1FF5B33C);
  static const danger = Color(0xFFFF6B6B);
  static const dangerWash = Color(0x1FFF6B6B);
  static const success = Color(0xFF57D9A3);
}

abstract final class TextTone {
  static const primary = Color(0xFFE9F6F4);
  static const secondary = Color(0xFF93ABAF);
  static const muted = Color(0xFF64808A);
}

abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

abstract final class Radii {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get pillAll => BorderRadius.circular(pill);
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Accent.teal,
    onPrimary: Accent.tealInk,
    primaryContainer: Accent.tealWash,
    onPrimaryContainer: Accent.teal,
    secondary: Accent.amber,
    onSecondary: Accent.tealInk,
    secondaryContainer: Accent.amberWash,
    onSecondaryContainer: Accent.amber,
    error: Accent.danger,
    onError: Accent.tealInk,
    errorContainer: Accent.dangerWash,
    onErrorContainer: Accent.danger,
    surface: Surfaces.surface,
    onSurface: TextTone.primary,
    surfaceContainerLowest: Surfaces.base,
    surfaceContainerLow: Surfaces.surface,
    surfaceContainer: Surfaces.raised,
    surfaceContainerHigh: Surfaces.overlay,
    surfaceContainerHighest: Surfaces.overlay,
    onSurfaceVariant: TextTone.secondary,
    outline: Surfaces.line,
    outlineVariant: Surfaces.lineSoft,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: TextTone.primary,
    onInverseSurface: Surfaces.base,
    inversePrimary: Accent.tealDeep,
    surfaceTint: Colors.transparent,
  );

  const textTheme = TextTheme(
    displaySmall: TextStyle(
      fontSize: 34,
      height: 1.1,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.9,
      color: TextTone.primary,
    ),
    headlineMedium: TextStyle(
      fontSize: 26,
      height: 1.15,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: TextTone.primary,
    ),
    headlineSmall: TextStyle(
      fontSize: 22,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: TextTone.primary,
    ),
    titleLarge: TextStyle(
      fontSize: 19,
      height: 1.25,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: TextTone.primary,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 1.3,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      color: TextTone.primary,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      height: 1.35,
      fontWeight: FontWeight.w600,
      color: TextTone.primary,
    ),
    bodyLarge: TextStyle(
      fontSize: 15,
      height: 1.55,
      fontWeight: FontWeight.w400,
      color: TextTone.primary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w400,
      color: TextTone.secondary,
    ),
    bodySmall: TextStyle(
      fontSize: 12.5,
      height: 1.45,
      fontWeight: FontWeight.w400,
      color: TextTone.muted,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: TextTone.primary,
    ),
    labelMedium: TextStyle(
      fontSize: 12.5,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
      color: TextTone.secondary,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: TextTone.muted,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: Surfaces.base,
    canvasColor: Surfaces.base,
    textTheme: textTheme,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: Surfaces.base,
      foregroundColor: TextTone.primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: TextTone.primary,
      ),
    ),
    cardTheme: CardThemeData(
      color: Surfaces.raised,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.lgAll,
        side: const BorderSide(color: Surfaces.lineSoft),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Surfaces.lineSoft, thickness: 1, space: 1),
    iconTheme: const IconThemeData(color: TextTone.secondary, size: 22),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Surfaces.raised,
      hintStyle: const TextStyle(color: TextTone.muted, fontSize: 15),
      labelStyle: const TextStyle(color: TextTone.secondary, fontSize: 15),
      floatingLabelStyle: const TextStyle(color: Accent.teal, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md + 2,
      ),
      border: OutlineInputBorder(
        borderRadius: Radii.mdAll,
        borderSide: const BorderSide(color: Surfaces.lineSoft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: Radii.mdAll,
        borderSide: const BorderSide(color: Surfaces.lineSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: Radii.mdAll,
        borderSide: const BorderSide(color: Accent.teal, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: Radii.mdAll,
        borderSide: const BorderSide(color: Accent.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: Radii.mdAll,
        borderSide: const BorderSide(color: Accent.danger, width: 1.6),
      ),
      errorStyle: const TextStyle(color: Accent.danger, fontSize: 12.5),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Accent.teal,
        foregroundColor: Accent.tealInk,
        disabledBackgroundColor: Surfaces.overlay,
        disabledForegroundColor: TextTone.muted,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        shape: RoundedRectangleBorder(borderRadius: Radii.mdAll),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TextTone.primary,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        side: const BorderSide(color: Surfaces.line),
        shape: RoundedRectangleBorder(borderRadius: Radii.mdAll),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Accent.teal,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Surfaces.raised,
      selectedColor: Accent.tealWash,
      disabledColor: Surfaces.raised,
      side: const BorderSide(color: Surfaces.lineSoft),
      labelStyle: const TextStyle(
        color: TextTone.secondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: Radii.pillAll),
      padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
    ),    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Surfaces.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      elevation: 0,
      height: 66,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 23,
          color: states.contains(WidgetState.selected)
              ? Accent.teal
              : TextTone.muted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? Accent.teal
              : TextTone.muted,
        ),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Surfaces.raised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Surfaces.raised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: Radii.lgAll),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Surfaces.overlay,
      contentTextStyle: const TextStyle(color: TextTone.primary, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: Radii.mdAll),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Accent.tealInk
            : TextTone.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Accent.teal
            : Surfaces.overlay,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Accent.teal,
      linearTrackColor: Surfaces.overlay,
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: Accent.teal,
      inactiveTrackColor: Surfaces.overlay,
      thumbColor: Accent.teal,
      overlayColor: Accent.tealWash,
    ),
  );
}
