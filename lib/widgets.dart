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

/// Round badge with the country flag (or the code if no flag exists).
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
        color: extra.field,
        shape: BoxShape.circle,
      ),
      child: flag.isEmpty
          ? Text(
              code,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: Brand.displayFont,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.3,
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

/// Small label for a status: a colored dot and text, e.g. "Visa-free · 60 d".
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.rule});

  final VisaRule rule;

  @override
  Widget build(BuildContext context) {
    final color = rule.status.foreground(Theme.of(context).brightness);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            rule.shortLabel(context.l10n),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
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

/// Helpers for the flat Lite look.
class Neu {
  /// Color of a card or button surface.
  static Color raised(StamplyColors c) => c.surface;

  /// The Lite look has no shadows; kept so older call sites still compile.
  static List<BoxShadow> shadows(StamplyColors c, {double depth = 1}) => const [];
}

/// True when animations should not run: the phone asks for reduced motion or
/// the user turned on "Reduce effects".
bool motionOff(BuildContext context) =>
    MediaQuery.of(context).disableAnimations || StamplyColors.of(context).reduceMotion;

/// Flat card with a thin border. With [inset] it uses the field color, which
/// is used for rows inside a screen.
class CardBox extends StatelessWidget {
  const CardBox({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.inset = false,
    this.radius = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool inset;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final extra = StamplyColors.of(context);
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: inset ? extra.field : extra.surface,
        borderRadius: shape,
        border: Border.all(color: extra.divider),
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: Material(
          type: MaterialType.transparency,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A flat pill or round button with a thin border. It darkens when pressed.
class NeuButton extends StatefulWidget {
  const NeuButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height = 52,
    this.width,
    this.radius,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.tooltip,
  });

  /// Icon plus label, centered.
  NeuButton.icon({
    Key? key,
    required VoidCallback? onPressed,
    required Widget icon,
    required Widget label,
    double height = 52,
  }) : this(
          key: key,
          onPressed: onPressed,
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [icon, const SizedBox(width: 8), Flexible(child: label)],
          ),
        );

  final VoidCallback? onPressed;
  final Widget child;
  final double height;
  final double? width;
  final double? radius;
  final EdgeInsetsGeometry padding;
  final String? tooltip;

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final extra = StamplyColors.of(context);
    final enabled = widget.onPressed != null;
    final r = BorderRadius.circular(widget.radius ?? widget.height / 2);
    final button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onPressed,
      child: Container(
        width: widget.width,
        height: widget.height,
        padding: widget.padding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _down ? extra.field : extra.surface,
          borderRadius: r,
          border: Border.all(color: extra.outline),
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          textAlign: TextAlign.center,
          child: Opacity(opacity: enabled ? 1 : 0.5, child: widget.child),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      child: widget.tooltip == null ? button : Tooltip(message: widget.tooltip!, child: button),
    );
  }
}

/// Fades its child in once when the screen appears. Short and cheap; does
/// nothing when the phone asks for reduced motion or "Reduce effects" is on.
class Rise extends StatefulWidget {
  const Rise({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<Rise> createState() => _RiseState();
}

class _RiseState extends State<Rise> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  static const _length = Duration(milliseconds: 260);

  @override
  void initState() {
    super.initState();
    final delay = widget.delay > const Duration(milliseconds: 240)
        ? const Duration(milliseconds: 240)
        : widget.delay;
    final total = delay + _length;
    _c = AnimationController(vsync: this, duration: total);
    _t = CurvedAnimation(
      parent: _c,
      curve: Interval(delay.inMilliseconds / total.inMilliseconds, 1, curve: Curves.easeOut),
    );
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (motionOff(context)) return widget.child;
    return FadeTransition(opacity: _t, child: widget.child);
  }
}

/// The plain background of every screen.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: StamplyColors.of(context).base, child: child);
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
