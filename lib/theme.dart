import 'package:flutter/material.dart';

/// Stamply brand colors (logo B: passport + check badge).
class Brand {
  static const ink = Color(0xFF1B2A4A);
  static const paper = Color(0xFFF6F4EE);
  static const stamp = Color(0xFFC2441E);
  static const stampDark = Color(0xFFE2683F);
  static const night = Color(0xFF10192E);

  /// Base colors under the glass background glows.
  static const nightBase = Color(0xFF0B1228);
  static const paperBase = Color(0xFFF1EEE6);

  static const displayFont = 'SpaceGrotesk';
  static const bodyFont = 'IBMPlexSans';
}

/// Extra colors the Material scheme does not cover.
class StamplyColors extends ThemeExtension<StamplyColors> {
  const StamplyColors({
    required this.muted,
    required this.divider,
    required this.card,
    required this.hero,
    required this.onHero,
    required this.glassBorder,
  });

  final Color muted;
  final Color divider;
  final Color card;
  final Color hero;
  final Color onHero;

  /// Thin bright edge of the glass cards.
  final Color glassBorder;

  static const light = StamplyColors(
    muted: Color(0xFF4A5468),
    divider: Color(0x1F1B2A4A),
    card: Color(0x99FFFFFF),
    hero: Brand.ink,
    onHero: Brand.paper,
    glassBorder: Color(0xCCFFFFFF),
  );

  static const dark = StamplyColors(
    muted: Color(0xFFC3CBDD),
    divider: Color(0x24FFFFFF),
    card: Color(0x1AFFFFFF),
    hero: Color(0xFF22355C),
    onHero: Brand.paper,
    glassBorder: Color(0x38FFFFFF),
  );

  static StamplyColors of(BuildContext context) =>
      Theme.of(context).extension<StamplyColors>() ?? light;

  @override
  StamplyColors copyWith({
    Color? muted,
    Color? divider,
    Color? card,
    Color? hero,
    Color? onHero,
    Color? glassBorder,
  }) {
    return StamplyColors(
      muted: muted ?? this.muted,
      divider: divider ?? this.divider,
      card: card ?? this.card,
      hero: hero ?? this.hero,
      onHero: onHero ?? this.onHero,
      glassBorder: glassBorder ?? this.glassBorder,
    );
  }

  @override
  StamplyColors lerp(ThemeExtension<StamplyColors>? other, double t) {
    if (other is! StamplyColors) return this;
    return StamplyColors(
      muted: Color.lerp(muted, other.muted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      card: Color.lerp(card, other.card, t)!,
      hero: Color.lerp(hero, other.hero, t)!,
      onHero: Color.lerp(onHero, other.onHero, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
    );
  }
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final extra = dark ? StamplyColors.dark : StamplyColors.light;
  final ink = dark ? Brand.paper : Brand.ink;
  final background = dark ? Brand.night : Brand.paper;
  final accent = dark ? Brand.stampDark : Brand.stamp;

  final scheme = ColorScheme.fromSeed(
    seedColor: Brand.ink,
    brightness: brightness,
  ).copyWith(
    primary: accent,
    onPrimary: dark ? Brand.night : Colors.white,
    secondary: ink,
    surface: background,
    onSurface: ink,
    outlineVariant: extra.divider,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    // Transparent: the glass background is drawn once, behind every screen.
    scaffoldBackgroundColor: Colors.transparent,
    fontFamily: Brand.bodyFont,
    extensions: [extra],
  );

  final text = base.textTheme.apply(bodyColor: ink, displayColor: ink);

  return base.copyWith(
    textTheme: text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(
        fontFamily: Brand.displayFont,
        fontWeight: FontWeight.w700,
        height: 1.15,
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
      backgroundColor: Colors.transparent,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: Brand.displayFont,
        fontWeight: FontWeight.w700,
        fontSize: 22,
        color: ink,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: accent.withValues(alpha: 0.2),
      surfaceTintColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(
          fontFamily: Brand.bodyFont,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: ink,
        side: BorderSide(color: extra.glassBorder, width: 1.5),
        backgroundColor: extra.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(
          fontFamily: Brand.bodyFont,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
