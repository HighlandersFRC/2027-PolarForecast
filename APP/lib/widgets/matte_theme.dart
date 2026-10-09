import 'dart:ui';

import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF070D18);
  static const backgroundDeep = Color(0xFF03060D);
  static const primary = Color(0xFF9BCBFF);
  static const secondary = Color(0xFFAAC7F1);
  static const aqua = Color(0xFF9DDDED);
  static const text = Color(0xFFF2F6FF);
  static const textMuted = Color(0xFFA9BBD3);
  static const surface = Color(0xFF101F35);
  static const surfaceRaised = Color(0xFF1A2D48);
  static const surfaceSoft = Color(0xFF15263F);
  static const border = Color(0xFF344F73);
  static const glassBlue = Color(0xFF609FFF);
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
    borderRadius: BorderRadius.circular(24),
    side: const BorderSide(color: AppColors.border),
  );

  return base.copyWith(
    colorScheme: scheme,
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
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
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.background, AppColors.backgroundDeep],
          ),
        ),
        child: child,
      );
}

/// Quiet, non-interactive snow accents for page introductions.
class PolarAccent extends StatelessWidget {
  final Widget child;

  const PolarAccent({required this.child, super.key});

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: ClipRect(
                  child: Stack(
                    children: [
                      Positioned(
                        right: -12,
                        top: -16,
                        child: Icon(Icons.ac_unit_rounded,
                            size: 132,
                            color: AppColors.primary.withValues(alpha: 0.055)),
                      ),
                      Positioned(
                        right: 128,
                        bottom: 12,
                        child: Icon(Icons.ac_unit_rounded,
                            size: 30,
                            color: AppColors.aqua.withValues(alpha: 0.10)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      );
}

/// Blue-black translucent chrome inspired by the ios27-design-system tokens.
/// Use blur for floating controls; list content can use blur: 0.
class BlackGlassSurface extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final double opacity;
  final Color? tint;
  final bool highlighted;

  const BlackGlassSurface({
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(34)),
    this.padding = EdgeInsets.zero,
    this.blur = 6,
    this.opacity = 0.735,
    this.tint,
    this.highlighted = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.highContrastOf(context);
    final fill = Color.alphaBlend(
      (tint ?? Colors.transparent).withValues(alpha: tint == null ? 0 : 0.035),
      AppColors.surface,
    );
    Widget surface = CustomPaint(
      foregroundPainter:
          _GlassRimPainter(borderRadius, highlighted || highContrast),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(
                      AppColors.glassBlue.withValues(alpha: 0.14), fill)
                  .withValues(alpha: highContrast ? 1 : opacity),
              fill.withValues(alpha: highContrast ? 1 : opacity),
              AppColors.background.withValues(
                  alpha: highContrast ? 1 : opacity + (1 - opacity) * 0.35),
            ],
          ),
        ),
        child: child,
      ),
    );
    if (blur > 0 && !highContrast) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: surface,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: Colors.black.withValues(alpha: 0.75)),
        boxShadow: [
          if (highlighted)
            BoxShadow(
              color: AppColors.glassBlue.withValues(alpha: 0.16),
              blurRadius: 18,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(borderRadius: borderRadius, child: surface),
    );
  }
}

class _GlassRimPainter extends CustomPainter {
  final BorderRadius radius;
  final bool highlighted;

  const _GlassRimPainter(this.radius, this.highlighted);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primary.withValues(alpha: highlighted ? 0.65 : 0.38),
          AppColors.glassBlue.withValues(alpha: 0.14),
          Colors.black.withValues(alpha: 0.4),
          AppColors.primary.withValues(alpha: highlighted ? 0.35 : 0.20),
        ],
        stops: const [0, 0.35, 0.7, 1],
      ).createShader(rect);
    canvas.drawRRect(radius.toRRect(rect), paint);
  }

  @override
  bool shouldRepaint(covariant _GlassRimPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.highlighted != highlighted;
}

/// A solid content surface; floating controls use BlackGlassSurface.
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(
                  tint.withValues(alpha: 0.025), AppColors.surfaceRaised),
              AppColors.surface,
            ],
          ),
          borderRadius: borderRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}
