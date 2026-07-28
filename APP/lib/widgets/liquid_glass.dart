import 'dart:ui' as ui;

import 'package:flutter/material.dart';

abstract final class LiquidGlassColors {
  static const background = Color(0xFF06101E);
  static const backgroundDeep = Color(0xFF0A0D19);
  static const primary = Color(0xFF69B8FF);
  static const secondary = Color(0xFF9B83FF);
  static const aqua = Color(0xFF39E2DB);
  static const text = Color(0xFFF5F9FF);
  static const textMuted = Color(0xFFAAB9CC);
  static const glass = Color(0x8A182638);
  static const glassStrong = Color(0xB31A2738);
  static const glassSoft = Color(0x521C2A3C);
  static const border = Color(0x42FFFFFF);
}

ThemeData buildLiquidGlassTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  const scheme = ColorScheme.dark(
    primary: LiquidGlassColors.primary,
    secondary: LiquidGlassColors.secondary,
    tertiary: LiquidGlassColors.aqua,
    surface: LiquidGlassColors.glass,
    onSurface: LiquidGlassColors.text,
    error: Color(0xFFFF7A88),
  );

  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(18),
    side: const BorderSide(color: LiquidGlassColors.border),
  );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: LiquidGlassColors.glassStrong,
    dividerColor: Colors.white.withValues(alpha: 0.10),
    cardTheme: CardThemeData(
      color: LiquidGlassColors.glass,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: rounded,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white.withValues(alpha: 0.10),
      thickness: 1,
      space: 1,
    ),
    splashColor: Colors.white.withValues(alpha: 0.10),
    highlightColor: Colors.white.withValues(alpha: 0.06),
    hoverColor: Colors.white.withValues(alpha: 0.07),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: LiquidGlassColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: LiquidGlassColors.glassStrong,
      indicatorColor: LiquidGlassColors.primary.withValues(alpha: 0.22),
      shadowColor: Colors.black.withValues(alpha: 0.30),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? LiquidGlassColors.text
              : LiquidGlassColors.textMuted,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
        ),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      dividerColor: Colors.transparent,
      indicatorColor: LiquidGlassColors.primary,
      labelColor: LiquidGlassColors.text,
      unselectedLabelColor: LiquidGlassColors.textMuted,
      overlayColor: WidgetStatePropertyAll(
        Colors.white.withValues(alpha: 0.07),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: LiquidGlassColors.glassStrong,
      selectedItemColor: LiquidGlassColors.primary,
      unselectedItemColor: LiquidGlassColors.textMuted,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.07),
      labelStyle: const TextStyle(color: LiquidGlassColors.textMuted),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
      prefixIconColor: LiquidGlassColors.textMuted,
      suffixIconColor: LiquidGlassColors.textMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: LiquidGlassColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: LiquidGlassColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: LiquidGlassColors.primary,
          width: 1.5,
        ),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: LiquidGlassColors.primary,
      selectionColor: LiquidGlassColors.primary.withValues(alpha: 0.30),
      selectionHandleColor: LiquidGlassColors.primary,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: LiquidGlassColors.glassStrong,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: rounded,
      titleTextStyle: const TextStyle(
        color: LiquidGlassColors.text,
        fontSize: 21,
        fontWeight: FontWeight.w800,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: LiquidGlassColors.glassStrong,
      modalBackgroundColor: LiquidGlassColors.glassStrong,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: Colors.black.withValues(alpha: 0.50),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: LiquidGlassColors.border),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: LiquidGlassColors.glassStrong,
      contentTextStyle: const TextStyle(color: LiquidGlassColors.text),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: rounded,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: LiquidGlassColors.glassStrong,
      surfaceTintColor: Colors.transparent,
      shape: rounded,
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(
          LiquidGlassColors.glassStrong,
        ),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(rounded),
        side: const WidgetStatePropertyAll(
          BorderSide(color: LiquidGlassColors.border),
        ),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      textColor: LiquidGlassColors.text,
      iconColor: LiquidGlassColors.textMuted,
      selectedColor: LiquidGlassColors.primary,
      selectedTileColor: LiquidGlassColors.glassSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    ),
    dataTableTheme: DataTableThemeData(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LiquidGlassColors.border),
      ),
      headingRowColor: WidgetStatePropertyAll(
        Colors.white.withValues(alpha: 0.075),
      ),
      dataRowColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? LiquidGlassColors.primary.withValues(alpha: 0.16)
            : Colors.transparent,
      ),
      headingTextStyle: const TextStyle(
        color: LiquidGlassColors.text,
        fontWeight: FontWeight.w800,
      ),
      dataTextStyle: const TextStyle(color: LiquidGlassColors.text),
      dividerThickness: 0.7,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? LiquidGlassColors.primary
            : Colors.white.withValues(alpha: 0.06),
      ),
      side: const BorderSide(color: LiquidGlassColors.border, width: 1.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : LiquidGlassColors.textMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? LiquidGlassColors.primary.withValues(alpha: 0.62)
            : Colors.white.withValues(alpha: 0.10),
      ),
      trackOutlineColor: const WidgetStatePropertyAll(
        LiquidGlassColors.border,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: LiquidGlassColors.primary.withValues(alpha: 0.78),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: rounded,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LiquidGlassColors.primary.withValues(alpha: 0.80),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: rounded,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: LiquidGlassColors.text,
        backgroundColor: Colors.white.withValues(alpha: 0.055),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: rounded,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: LiquidGlassColors.text,
        backgroundColor: Colors.white.withValues(alpha: 0.055),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: LiquidGlassColors.border),
        ),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: LiquidGlassColors.primary,
      linearTrackColor: LiquidGlassColors.glassSoft,
      circularTrackColor: LiquidGlassColors.glassSoft,
    ),
  );
}

class LiquidGlassBackground extends StatelessWidget {
  final Widget child;

  const LiquidGlassBackground({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: LiquidGlassColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  LiquidGlassColors.background,
                  Color(0xFF0A1628),
                  LiquidGlassColors.backgroundDeep,
                ],
              ),
            ),
          ),
          const Positioned(
            top: -180,
            left: -140,
            child: _LiquidGlow(
              size: 520,
              color: LiquidGlassColors.primary,
            ),
          ),
          const Positioned(
            top: 180,
            right: -180,
            child: _LiquidGlow(
              size: 500,
              color: LiquidGlassColors.secondary,
            ),
          ),
          const Positioned(
            bottom: -220,
            left: 100,
            child: _LiquidGlow(
              size: 580,
              color: LiquidGlassColors.aqua,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _LiquidGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _LiquidGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.28),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class LiquidGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color tint;
  final double blurSigma;
  final bool shadow;
  final double? width;

  const LiquidGlassPanel({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.tint = LiquidGlassColors.primary,
    this.blurSigma = 20,
    this.shadow = true,
    this.width,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: tint.withValues(alpha: 0.08),
                  blurRadius: 24,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: blurSigma,
            sigmaY: blurSigma,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.145),
                  tint.withValues(alpha: 0.075),
                  Colors.white.withValues(alpha: 0.035),
                ],
                stops: const [0, 0.50, 1],
              ),
              border: Border.all(color: LiquidGlassColors.border),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
