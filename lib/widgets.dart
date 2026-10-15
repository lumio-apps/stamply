import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'app_state.dart';
import 'l10n/l10n.dart';
import 'models.dart';
import 'status_text.dart';
import 'theme.dart';

/// Flag emoji for a two-letter country code, or "" if the code is not A–Z.
String flagEmoji(String code) {
  final c = code.toUpperCase();
  if (c.length != 2) return '';
  final a = c.codeUnitAt(0);
  final b = c.codeUnitAt(1);
  if (a < 0x41 || a > 0x5A || b < 0x41 || b > 0x5A) return '';
  return String.fromCharCodes([0x1F1E6 + a - 0x41, 0x1F1E6 + b - 0x41]);
}

/// Rounded square with the country flag (or the code if no flag exists).
class CountryBadge extends StatelessWidget {
  const CountryBadge({super.key, required this.code, this.size = 44});

  final String code;
  final double size;

  @override
  Widget build(BuildContext context) {
    final extra = StamplyColors.of(context);
    final flag = flagEmoji(code);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: extra.divider,
        borderRadius: BorderRadius.circular(size * 0.27),
      ),
      child: flag.isEmpty
          ? Text(
              code,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: size * 0.32,
              ),
            )
          : Text(flag, style: TextStyle(fontSize: size * 0.52, height: 1.0)),
    );
  }
}

/// Small "Changed" label for a saved trip whose rule changed after a data update.
class ChangedBadge extends StatelessWidget {
  const ChangedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.l10n.changedBadge,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
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
        rule.shortLabel(context.l10n),
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

/// Frosted-glass rounded card used for grouped rows.
class CardBox extends StatelessWidget {
  const CardBox({super.key, required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final extra = StamplyColors.of(context);
    final radius = BorderRadius.circular(22);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: extra.card,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: extra.glassBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// The soft colored glow behind every screen. The glass cards blur it.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final strength = dark ? 0.85 : 0.7;
    return Stack(
      alignment: Alignment.topLeft,
      fit: StackFit.expand,
      children: [
        ColoredBox(color: dark ? Brand.nightBase : Brand.paperBase),
        _Glow(
          alignment: const Alignment(-1.0, -1.05),
          color: dark ? const Color(0xFF3563D6) : const Color(0xFF9DB9FF),
          alpha: strength,
        ),
        _Glow(
          alignment: const Alignment(1.1, 0.1),
          color: dark ? const Color(0xFF12A58E) : const Color(0xFF8FE0CC),
          alpha: strength,
        ),
        _Glow(
          alignment: const Alignment(-0.6, 1.15),
          color: dark ? const Color(0xFFC2441E) : const Color(0xFFFFB79A),
          alpha: strength,
        ),
        child,
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.alignment, required this.color, required this.alpha});

  final Alignment alignment;
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: alignment,
            radius: 0.95,
            colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
          ),
        ),
      ),
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

/// Asks for the passport expiry date and saves it on this device.
Future<void> pickPassportExpiry(BuildContext context, AppState state) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final first = DateTime(today.year - 5);
  var initial = state.passportExpiry ?? DateTime(today.year + 1, today.month, today.day);
  if (initial.isBefore(first)) initial = first;
  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first,
    lastDate: DateTime(today.year + 20),
    helpText: context.l10n.passportExpiryDate,
  );
  if (picked != null) state.setPassportExpiry(picked);
}
