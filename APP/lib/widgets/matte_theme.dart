import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF141A22);
  static const backgroundDeep = Color(0xFF141A22);
  static const primary = Color(0xFF8AB4E0);
  static const secondary = Color(0xFFAEA4CC);
  static const aqua = Color(0xFF86BDB5);
  static const text = Color(0xFFE7EDF4);
  static const textMuted = Color(0xFFA6B2C1);
  static const surface = Color(0xFF1D2632);
  static const surfaceRaised = Color(0xFF263240);
  static const surfaceSoft = Color(0xFF222D3A);
  static const border = Color(0xFF364353);
}

ThemeData buildMatteTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  const scheme = ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: AppColors.background,
    onSecondary: AppColors.background,
    onTertiary: AppColors.background,
    secondary: AppColors.secondary,
    tertiary: AppColors.aqua,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: Color(0xFFFF7A88),
  );

  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: const BorderSide(color: AppColors.border),
  );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.surfaceRaised,
    dividerColor: Colors.white.withValues(alpha: 0.10),
    cardTheme: CardThemeData(
      color: AppColors.surface,
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
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surfaceRaised,
      indicatorColor: AppColors.primary.withValues(alpha: 0.22),
      shadowColor: Colors.black.withValues(alpha: 0.30),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? AppColors.text
              : AppColors.textMuted,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w600,
        ),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      dividerColor: Colors.transparent,
      indicatorColor: AppColors.primary,
      labelColor: AppColors.text,
      unselectedLabelColor: AppColors.textMuted,
      overlayColor: WidgetStatePropertyAll(
        Colors.white.withValues(alpha: 0.07),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceRaised,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.background,
      labelStyle: const TextStyle(color: AppColors.textMuted),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      prefixIconColor: AppColors.textMuted,
      suffixIconColor: AppColors.textMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: AppColors.primary.withValues(alpha: 0.30),
      selectionHandleColor: AppColors.primary,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: rounded,
      titleTextStyle: const TextStyle(
        color: AppColors.text,
        fontSize: 21,
        fontWeight: FontWeight.w700,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.surfaceRaised,
      modalBackgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: Colors.black.withValues(alpha: 0.50),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: AppColors.border),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceRaised,
      contentTextStyle: const TextStyle(color: AppColors.text),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: rounded,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: rounded,
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(
          AppColors.surfaceRaised,
        ),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(rounded),
        side: const WidgetStatePropertyAll(
          BorderSide(color: AppColors.border),
        ),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      textColor: AppColors.text,
      iconColor: AppColors.textMuted,
      selectedColor: AppColors.primary,
      selectedTileColor: AppColors.surfaceSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    ),
    dataTableTheme: DataTableThemeData(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      headingRowColor: WidgetStatePropertyAll(
        AppColors.surfaceRaised,
      ),
      dataRowColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primary.withValues(alpha: 0.16)
            : Colors.transparent,
      ),
      headingTextStyle: const TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w700,
      ),
      dataTextStyle: const TextStyle(color: AppColors.text),
      dividerThickness: 0.7,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primary
            : Colors.white.withValues(alpha: 0.06),
      ),
      side: const BorderSide(color: AppColors.border, width: 1.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : AppColors.textMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primary.withValues(alpha: 0.62)
            : Colors.white.withValues(alpha: 0.10),
      ),
      trackOutlineColor: const WidgetStatePropertyAll(
        AppColors.border,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: rounded,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: rounded,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        backgroundColor: AppColors.surfaceSoft,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: rounded,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.text,
        backgroundColor: AppColors.surfaceSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.surfaceSoft,
      circularTrackColor: AppColors.surfaceSoft,
    ),
  );
}

class MatteBackground extends StatelessWidget {
  final Widget child;

  const MatteBackground({required this.child, super.key});

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AppColors.background,
        child: child,
      );
}

/// An opaque surface with a subtle accent and no blur or glow.
class MattePanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color tint;
  final double? width;

  const MattePanel({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.tint = AppColors.primary,
    this.width,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        clipBehavior: Clip.antiAlias,
        padding: padding,
        decoration: BoxDecoration(
          color: Color.alphaBlend(
              tint.withValues(alpha: 0.025), AppColors.surface),
          borderRadius: borderRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}
