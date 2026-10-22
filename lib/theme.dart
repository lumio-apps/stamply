import 'package:flutter/material.dart';

/// Stamply brand colors (logo B: passport + check badge).
class Brand {
  static const ink = Color(0xFF1B2A4A);
  static const paper = Color(0xFFF6F4EE);
  static const stamp = Color(0xFFC2441E);
  static const stampDark = Color(0xFFE2683F);

  /// Text color on the light surface.
  static const softInk = Color(0xFF1B2A4A);

  /// Text color on the dark surface.
  static const softPaper = Color(0xFFE8ECF4);

  static const displayFont = 'SpaceGrotesk';
  static const bodyFont = 'IBMPlexSans';
}

/// Extra colors the Material scheme does not cover.
///
/// The look is "Lite": flat surfaces with a thin border, no shadows, so every
/// screen is cheap to draw even on older phones.
class StamplyColors extends ThemeExtension<StamplyColors> {
  const StamplyColors({
    required this.base,
    required this.surface,
    required this.divider,
    required this.outline,
    required this.muted,
    required this.field,
    required this.hero,
    required this.onHero,
    this.reduceMotion = false,
  });

  /// Screen background.
  final Color base;

  /// Cards, rows and the bottom bar.
  final Color surface;

  /// Thin lines between rows and around cards.
  final Color divider;

  /// Stronger border for buttons and chips.
  final Color outline;

  final Color muted;

  /// Fill of text fields, avatars and pressed rows.
  final Color field;
  final Color hero;
  final Color onHero;

  /// "Reduce effects": no animations.
  final bool reduceMotion;

  static const light = StamplyColors(
    base: Color(0xFFF5F7FA),
    surface: Color(0xFFFFFFFF),
    divider: Color(0xFFDCE2EC),
    outline: Color(0xFFC5CDDA),
    muted: Color(0xFF566176),
    field: Color(0xFFEDF0F5),
    hero: Brand.ink,
    onHero: Brand.paper,
  );

  static const dark = StamplyColors(
    base: Color(0xFF14181F),
    surface: Color(0xFF1D222B),
    divider: Color(0xFF2E3541),
    outline: Color(0xFF3F4857),
    muted: Color(0xFFA9B3C6),
    field: Color(0xFF262C37),
    hero: Color(0xFF22355C),
    onHero: Brand.paper,
  );

  static StamplyColors of(BuildContext context) =>
      Theme.of(context).extension<StamplyColors>() ?? light;

  @override
  StamplyColors copyWith({
    Color? base,
    Color? surface,
    Color? divider,
    Color? outline,
    Color? muted,
    Color? field,
    Color? hero,
    Color? onHero,
    bool? reduceMotion,
  }) {
    return StamplyColors(
      base: base ?? this.base,
      surface: surface ?? this.surface,
      divider: divider ?? this.divider,
      outline: outline ?? this.outline,
      muted: muted ?? this.muted,
      field: field ?? this.field,
      hero: hero ?? this.hero,
      onHero: onHero ?? this.onHero,
      reduceMotion: reduceMotion ?? this.reduceMotion,
    );
  }

  @override
  StamplyColors lerp(ThemeExtension<StamplyColors>? other, double t) {
    if (other is! StamplyColors) return this;
    return StamplyColors(
      base: Color.lerp(base, other.base, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      field: Color.lerp(field, other.field, t)!,
      hero: Color.lerp(hero, other.hero, t)!,
      onHero: Color.lerp(onHero, other.onHero, t)!,
      reduceMotion: t < 0.5 ? reduceMotion : other.reduceMotion,
    );
  }
}

ThemeData buildTheme(Brightness brightness, {bool reduceMotion = false}) {
  final dark = brightness == Brightness.dark;
  final extra = (dark ? StamplyColors.dark : StamplyColors.light).copyWith(reduceMotion: reduceMotion);
  final ink = dark ? Brand.softPaper : Brand.softInk;
  final accent = dark ? Brand.stampDark : Brand.stamp;

  final scheme = ColorScheme.fromSeed(
    seedColor: Brand.ink,
    brightness: brightness,
  ).copyWith(
    primary: accent,
    onPrimary: dark ? const Color(0xFF1B1209) : Colors.white,
    secondary: ink,
    surface: extra.base,
    onSurface: ink,
    surfaceTint: Colors.transparent,
    outlineVariant: extra.divider,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: extra.base,
    canvasColor: extra.base,
    fontFamily: Brand.bodyFont,
    splashFactory: NoSplash.splashFactory,
    extensions: [extra],
  );

  final text = base.textTheme.apply(bodyColor: ink, displayColor: ink);

  return base.copyWith(
    textTheme: text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(
        fontFamily: Brand.displayFont,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.4,
      ),
      headlineSmall: text.headlineSmall?.copyWith(
        fontFamily: Brand.displayFont,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: text.titleLarge?.copyWith(
        fontFamily: Brand.displayFont,
        fontWeight: FontWeight.w700,
      ),
    ),
    appBarTheme: AppBarThemeData(
      backgroundColor: extra.base,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: Brand.displayFont,
        fontWeight: FontWeight.w700,
        fontSize: 22,
        color: ink,
      ),
    ),
    dividerTheme: DividerThemeData(color: extra.divider, space: 1, thickness: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: extra.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: extra.surface,
      surfaceTintColor: Colors.transparent,
    ),
    listTileTheme: ListTileThemeData(
      tileColor: Colors.transparent,
      iconColor: extra.muted,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: extra.surface,
      selectedColor: accent.withValues(alpha: dark ? 0.22 : 0.12),
      disabledColor: extra.surface,
      elevation: 0,
      pressElevation: 0,
      surfaceTintColor: Colors.transparent,
      side: BorderSide(color: extra.outline),
      showCheckmark: false,
      shape: const StadiumBorder(),
      labelStyle: TextStyle(fontFamily: Brand.bodyFont, fontWeight: FontWeight.w600, color: ink),
      secondaryLabelStyle: TextStyle(fontFamily: Brand.bodyFont, fontWeight: FontWeight.w600, color: accent),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        elevation: 0,
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: Brand.displayFont,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: ink,
        backgroundColor: extra.surface,
        elevation: 0,
        side: BorderSide(color: extra.outline),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: Brand.bodyFont,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? extra.field : Brand.softInk,
      contentTextStyle: TextStyle(color: dark ? Brand.softPaper : Colors.white, fontFamily: Brand.bodyFont),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
