import 'package:flutter/material.dart';

/// Metro Scales brand colour. Every other colour in the app is derived from
/// it by Material 3's tonal palette, unless the user picks wallpaper colours.
const brandSeed = Color(0xFF0F766E);

const _font = 'PlusJakartaSans';

class AppTheme {
  /// Teal for primary and secondary roles, with a calm indigo as the
  /// tertiary accent so highlights stay cool-toned next to the brand colour.
  static ColorScheme scheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: brandSeed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    final accent = ColorScheme.fromSeed(seedColor: const Color(0xFF4F5BD5), brightness: brightness);
    return base.copyWith(
      tertiary: accent.primary,
      onTertiary: accent.onPrimary,
      tertiaryContainer: accent.primaryContainer,
      onTertiaryContainer: accent.onPrimaryContainer,
    );
  }

  static ThemeData light([ColorScheme? scheme]) => build(scheme ?? AppTheme.scheme(Brightness.light));
  static ThemeData dark([ColorScheme? scheme]) => build(scheme ?? AppTheme.scheme(Brightness.dark));

  static ThemeData build(ColorScheme cs) {
    final base = ThemeData(useMaterial3: true, colorScheme: cs, fontFamily: _font);
    // Merge in the type scale sizes so component themes below get full styles
    final t = base.typography.englishLike.merge(base.textTheme);
    final text = t.copyWith(
      displaySmall: t.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1),
      headlineLarge: t.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8),
      headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6),
      headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
      titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      labelMedium: t.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      bodySmall: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
    );
    final field = OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none);
    const pill = StadiumBorder();

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: cs.surface,
      extensions: [StatusColors.of(cs.brightness)],
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: cs.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: cs.onSurfaceVariant,
        titleTextStyle: text.titleSmall?.copyWith(color: cs.onSurface, fontSize: 15),
        subtitleTextStyle: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: field,
        enabledBorder: field,
        focusedBorder: field.copyWith(borderSide: BorderSide(color: cs.primary, width: 2)),
        errorBorder: field.copyWith(borderSide: BorderSide(color: cs.error, width: 1.5)),
        focusedErrorBorder: field.copyWith(borderSide: BorderSide(color: cs.error, width: 2)),
        floatingLabelStyle: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 56),
          shape: pill,
          textStyle: text.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: pill,
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(textStyle: text.labelLarge)),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        extendedTextStyle: text.labelLarge?.copyWith(fontSize: 15),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelMedium?.copyWith(
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: text.labelLarge?.copyWith(fontSize: 13.5),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          minimumSize: const Size(0, 48),
          textStyle: text.labelLarge,
        ),
      ),
      dialogTheme: DialogThemeData(titleTextStyle: text.headlineSmall?.copyWith(color: cs.onSurface)),
      bottomSheetTheme: const BottomSheetThemeData(showDragHandle: true),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(color: cs.outlineVariant.withValues(alpha: 0.6), space: 1, thickness: 1),
      // Opt in to the current Material 3 progress indicator and slider look
      // ignore: deprecated_member_use
      progressIndicatorTheme: const ProgressIndicatorThemeData(year2023: false),
      // ignore: deprecated_member_use
      sliderTheme: const SliderThemeData(year2023: false),
    );
  }
}

/// Green, amber and blue for online, waiting and info states. Material 3 has
/// no built-in "success" role, so these sit alongside the colour scheme and
/// have their own dark-mode values.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
  });

  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;

  static StatusColors of(Brightness b) => b == Brightness.light
      ? const StatusColors(
          success: Color(0xFF1B873F),
          successContainer: Color(0xFFD3F5DC),
          onSuccessContainer: Color(0xFF0B3D1C),
          warning: Color(0xFFB25E00),
          warningContainer: Color(0xFFFFE3C2),
          onWarningContainer: Color(0xFF4A2700),
        )
      : const StatusColors(
          success: Color(0xFF7DDB98),
          successContainer: Color(0xFF125A2C),
          onSuccessContainer: Color(0xFFC6F3D2),
          warning: Color(0xFFFFB86E),
          warningContainer: Color(0xFF6B3A00),
          onWarningContainer: Color(0xFFFFE3C2),
        );

  @override
  StatusColors copyWith() => this;

  @override
  StatusColors lerp(StatusColors? other, double t) => t < 0.5 || other == null ? this : other;
}

extension ThemeContext on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
  TextTheme get tt => Theme.of(this).textTheme;
  StatusColors get status => Theme.of(this).extension<StatusColors>()!;
}
