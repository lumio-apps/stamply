import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';

/// Rounded square with the two-letter country code.
class CountryBadge extends StatelessWidget {
  const CountryBadge({super.key, required this.code, this.filled = true, this.size = 44});

  final String code;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final extra = StamplyColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = filled ? (dark ? Brand.paper : Brand.ink) : extra.divider;
    final fg = filled ? (dark ? Brand.ink : Brand.paper) : scheme.onSurface;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * 0.27)),
      child: Text(
        code,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: size * 0.32),
      ),
    );
  }
}

/// Small colored label for a status, e.g. "Visa-free · 60 d".
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.rule});

  final VisaRule rule;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: rule.status.background(b),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        rule.shortLabel,
        style: TextStyle(
          color: rule.status.foreground(b),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Small uppercase heading above a group.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: StamplyColors.of(context).muted,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// White (or dark) rounded card used for grouped rows.
class CardBox extends StatelessWidget {
  const CardBox({super.key, required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StamplyColors.of(context).card,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

/// The app logo (passport + check badge), drawn in code so it stays sharp.
class StamplyLogo extends StatelessWidget {
  const StamplyLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      size: Size.square(size),
      painter: _LogoPainter(
        book: dark ? Brand.paper : Brand.ink,
        lines: dark ? Brand.ink : Brand.paper,
        badge: dark ? Brand.stampDark : Brand.stamp,
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.book, required this.lines, required this.badge});

  final Color book;
  final Color lines;
  final Color badge;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn in a 120×120 box, same shapes as the app icon.
    final s = size.width / 120;
    canvas.scale(s);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(26, 14, 60, 84), const Radius.circular(10)),
      Paint()..color = book,
    );
    canvas.drawCircle(
      const Offset(56, 48),
      16,
      Paint()
        ..color = lines
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    canvas.drawCircle(const Offset(86, 90), 22, Paint()..color = badge);
    final check = Path()
      ..moveTo(76, 90)
      ..lineTo(83, 97)
      ..lineTo(96, 83);
    canvas.drawPath(
      check,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) =>
      oldDelegate.book != book || oldDelegate.lines != lines || oldDelegate.badge != badge;
}
