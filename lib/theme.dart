import 'package:flutter/material.dart';

/// Stamply brand colors (logo B: passport + check badge).
class Brand {
  static const ink = Color(0xFF1B2A4A);
  static const paper = Color(0xFFF6F4EE);
  static const stamp = Color(0xFFC2441E);
  static const stampDark = Color(0xFFE2683F);

  /// Text color on the soft light surface.
  static const softInk = Color(0xFF26324A);

  /// Text color on the soft dark surface.
  static const softPaper = Color(0xFFE8ECF4);

  static const displayFont = 'SpaceGrotesk';
  static const bodyFont = 'IBMPlexSans';
}

/// Extra colors the Material scheme does not cover.
///
/// The look is "soft UI" (neumorphism): every surface has the same color as
/// the background and is shaped only by a light and a dark shadow.
class StamplyColors extends ThemeExtension<StamplyColors> {
  const StamplyColors({
    required this.base,
    required this.shadowLight,
    required this.shadowDark,
    required this.muted,
    required this.divider,
    required this.field,
    required this.hero,
    required this.onHero,
  });

  /// Background and surface color (they are the same on purpose).
  final Color base;

  /// Shadow toward the light source (top left).
  final Color shadowLight;

  /// Shadow away from the light source (bottom right).
  final Color shadowDark;

  final Color muted;
  final Color divider;

  /// Fill of text fields (a little darker than [base]).
  final Color field;
  final Color hero;
  final Color onHero;

  static const light = StamplyColors(
    base: Color(0xFFE4E9F1),
    shadowLight: Color(0xFFFFFFFF),
    shadowDark: Color(0xFFBAC3D1),
    muted: Color(0xFF59647D),
    divider: Color(0x2226324A),
    field: Color(0xFFD9DFEA),
    hero: Brand.ink,
    onHero: Brand.paper,
  );

  static const dark = StamplyColors(
    base: Color(0xFF262B36),
    shadowLight: Color(0xFF323948),
    shadowDark: Color(0xFF191D25),
    muted: Color(0xFFB4BDD0),
    divider: Color(0x2AFFFFFF),
    field: Color(0xFF20242E),
    hero: Color(0xFF22355C),
    onHero: Brand.paper,
  );

  static StamplyColors of(BuildContext context) =>
      Theme.of(context).extension<StamplyColors>() ?? light;

  @override
  StamplyColors copyWith({
    Color? base,
    Color? shadowLight,
    Color? shadowDark,
    Color? muted,
    Color? divider,
    Color? field,
    Color? hero,
    Color? onHero,
  }) {
    return StamplyColors(
      base: base ?? this.base,
      shadowLight: shadowLight ?? this.shadowLight,
      shadowDark: shadowDark ?? this.shadowDark,
      muted: muted ?? this.muted,
      divider: divider ?? this.divider,
      field: field ?? this.field,
      hero: hero ?? this.hero,
      onHero: onHero ?? this.onHero,
    );
  }

  @override
  StamplyColors lerp(ThemeExtension<StamplyColors>? other, double t) {
    if (other is! StamplyColors) return this;
    return StamplyColors(
      base: Color.lerp(base, other.base, t)!,
      shadowLight: Color.lerp(shadowLight, other.shadowLight, t)!,
      shadowDark: Color.lerp(shadowDark, other.shadowDark, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      field: Color.lerp(field, other.field, t)!,
      hero: Color.lerp(hero, other.hero, t)!,
      onHero: Color.lerp(onHero, other.onHero, t)!,
    );
  }
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final extra = dark ? StamplyColors.dark : StamplyColors.light;
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
      backgroundColor: extra.base,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: extra.base,
      surfaceTintColor: Colors.transparent,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: extra.base,
      selectedColor: extra.field,
      disabledColor: extra.base,
      elevation: 4,
      pressElevation: 1,
      shadowColor: extra.shadowDark,
      surfaceTintColor: Colors.transparent,
      side: BorderSide.none,
      showCheckmark: false,
      shape: const StadiumBorder(),
      labelStyle: TextStyle(fontFamily: Brand.bodyFont, fontWeight: FontWeight.w600, color: ink),
      secondaryLabelStyle: TextStyle(fontFamily: Brand.bodyFont, fontWeight: FontWeight.w600, color: accent),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        elevation: 8,
        shadowColor: accent.withValues(alpha: 0.55),
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
        backgroundColor: extra.base,
        elevation: 4,
        shadowColor: extra.shadowDark,
        side: BorderSide.none,
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
      backgroundColor: dark ? extra.shadowLight : Brand.softInk,
      contentTextStyle: const TextStyle(color: Colors.white, fontFamily: Brand.bodyFont),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
