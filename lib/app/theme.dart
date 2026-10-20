import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The bundled Khmer font, used on the web. Phones and desktops have a
/// system Khmer font; a browser would download one after the first layout,
/// leaving text measured too narrow and clipped.
const List<String>? khmerFontFallback = kIsWeb ? ['NotoSansKhmer'] : null;

/// Brand palette: deep forest green on warm beige, and on dark navy at night.
class Brand {
  static const forest = Color(0xFF1E4D3B);
  static const forestDeep = Color(0xFF143628);
  static const sage = Color(0xFFDCE6DA);
  static const beige = Color(0xFFF4EEE3);
  static const sand = Color(0xFFE9DFCD);
  static const ivory = Color(0xFFFBF8F2);
  static const ink = Color(0xFF1F2A24);
  static const inkMuted = Color(0xFF5E6A62);
  static const line = Color(0xFFE2D8C6);

  // Dark mode: navy surfaces with beige text.
  static const nightBg = Color(0xFF0F1A2E);
  static const nightSurface = Color(0xFF16233B);
  static const nightRaised = Color(0xFF1E2E4A);
  static const nightLine = Color(0xFF2C3E5E);
  static const mint = Color(0xFF9CCBB0);
  static const parchment = Color(0xFFEDE5D6);
}

ThemeData buildAppTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;

  final scheme = dark
      ? const ColorScheme(
          brightness: Brightness.dark,
          primary: Brand.mint,
          onPrimary: Color(0xFF0B2A20),
          primaryContainer: Color(0xFF1F4645),
          onPrimaryContainer: Brand.parchment,
          secondary: Color(0xFFD8C8A8),
          onSecondary: Color(0xFF2E2717),
          secondaryContainer: Color(0xFF2E3B55),
          onSecondaryContainer: Brand.parchment,
          tertiary: Color(0xFFD9B77A),
          onTertiary: Color(0xFF2E2310),
          error: Color(0xFFF2A08F),
          onError: Color(0xFF4A1408),
          surface: Brand.nightBg,
          onSurface: Brand.parchment,
          onSurfaceVariant: Color(0xFFB0BBCD),
          surfaceContainerLowest: Color(0xFF0A1322),
          surfaceContainerLow: Brand.nightSurface,
          surfaceContainer: Brand.nightSurface,
          surfaceContainerHigh: Brand.nightRaised,
          surfaceContainerHighest: Color(0xFF263856),
          outline: Color(0xFF56698A),
          outlineVariant: Brand.nightLine,
        )
      : const ColorScheme(
          brightness: Brightness.light,
          primary: Brand.forest,
          onPrimary: Brand.ivory,
          primaryContainer: Brand.sage,
          onPrimaryContainer: Brand.forestDeep,
          secondary: Color(0xFF8A7350),
          onSecondary: Brand.ivory,
          secondaryContainer: Brand.sand,
          onSecondaryContainer: Color(0xFF3B2F1C),
          tertiary: Color(0xFFA9823F),
          onTertiary: Brand.ivory,
          error: Color(0xFFA63D2A),
          onError: Brand.ivory,
          surface: Brand.beige,
          onSurface: Brand.ink,
          onSurfaceVariant: Brand.inkMuted,
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Brand.ivory,
          surfaceContainer: Brand.ivory,
          surfaceContainerHigh: Color(0xFFF0E8DA),
          surfaceContainerHighest: Brand.sand,
          outline: Color(0xFFB9AC95),
          outlineVariant: Brand.line,
        );

  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,
    splashFactory: InkSparkle.splashFactory,
    fontFamilyFallback: khmerFontFallback,
  );

  // Khmer stacked consonants need extra line height to avoid clipping.
  final text = base.textTheme
      .apply(
        heightFactor: 1.15,
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      )
      .copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        titleSmall: base.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
          letterSpacing: 0.2,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      );

  const radius = 16.0;
  final cardColor = dark ? Brand.nightSurface : Brand.ivory;
  final roundedField = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: scheme.outlineVariant),
  );

  return base.copyWith(
    textTheme: text,
    // A distinct top bar: ivory like the navigation bar, a hairline
    // underneath, and a centred title.
    appBarTheme: AppBarTheme(
      backgroundColor: cardColor,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 56,
      shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      titleTextStyle: text.titleLarge?.copyWith(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: dark ? Brand.parchment : Brand.forestDeep,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cardColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 66,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: const StadiumBorder(),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return text.labelMedium?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? (dark ? Brand.parchment : Brand.forestDeep)
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 50),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 50),
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(textStyle: text.labelLarge),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: scheme.primary,
        selectedForegroundColor: scheme.onPrimary,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    // Selected chips are solid brand green, without a checkmark.
    chipTheme: ChipThemeData(
      backgroundColor: cardColor,
      selectedColor: scheme.primary,
      showCheckmark: false,
      side: WidgetStateBorderSide.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? BorderSide(color: scheme.primary)
            : BorderSide(color: scheme.outlineVariant),
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      labelStyle: text.labelLarge?.copyWith(color: scheme.onSurface),
      secondaryLabelStyle: text.labelLarge?.copyWith(color: scheme.onPrimary),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 18),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? Brand.nightRaised : Colors.white,
      border: roundedField,
      enabledBorder: roundedField,
      focusedBorder: roundedField.copyWith(
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.onSurfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: cardColor,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? Brand.parchment : Brand.forestDeep,
      contentTextStyle: TextStyle(color: dark ? Brand.forestDeep : Brand.ivory),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
  );
}
