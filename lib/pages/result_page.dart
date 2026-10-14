import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../passport_validity.dart';
import '../share.dart';
import '../theme.dart';
import '../widgets.dart';

/// Shows the entry requirement for one passport → destination pair.
class ResultPage extends StatefulWidget {
  const ResultPage({super.key, required this.check});

  final TripCheck check;

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final _shareKey = GlobalKey();
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    // Looking at a saved trip means the user has seen its current rule.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scope = AppScope.of(context);
      final c = widget.check;
      scope.state.markSeen(c, scope.repo.data.signature(c.passport, c.destination));
    });
  }

  Future<void> _share(String text) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sharing = true);
    try {
      final boundary = _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('Card is not ready');
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('Could not draw the image');
      final dir = await getTemporaryDirectory();
      final c = widget.check;
      final file = File('${dir.path}/stamply-${c.passport}-${c.destination}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      await ShareService.shareImage(file.path, text);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not share this result.')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final check = widget.check;
    final scope = AppScope.of(context);
    final data = scope.repo.data;
    final extra = StamplyColors.of(context);
    final rule = data.rule(check.passport, check.destination);
    final saved = scope.state.isSaved(check);
    final from = data.nameOf(check.passport);
    final to = data.nameOf(check.destination);
    final expiry = scope.state.passportExpiry;
    final validity = expiry == null ? null : PassportValidity.check(expiry, DateTime.now());

    final shareText = rule == null
        ? ''
        : '$from passport → $to: ${rule.status.headline}'
            '${rule.stayText != null ? ' (${rule.stayText!.toLowerCase()})' : ''}.\n'
            'Checked with Stamply, an open source visa checker: https://github.com/lumio-apps/stamply';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          '${check.passport} → ${check.destination}',
          style: const TextStyle(fontFamily: Brand.bodyFont, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (rule != null)
            IconButton(
              tooltip: 'Share as image',
              icon: _sharing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.ios_share),
              onPressed: _sharing ? null : () => _share(shareText),
            ),
          IconButton(
            tooltip: saved ? 'Remove from saved' : 'Save this check',
            icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () => scope.state.toggleSaved(
              check,
              signature: data.signature(check.passport, check.destination),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (check.passport == check.destination)
            const _Hero(
              title: 'Your own country',
              subtitle: 'Citizens can enter their own country with a valid passport.',
              stamp: null,
            )
          else if (rule == null)
            _Hero(
              title: 'No data yet',
              subtitle: 'We do not have a rule for $from passports travelling to $to.',
              stamp: null,
            )
          else ...[
            // This card is also what "Share as image" turns into a picture.
            RepaintBoundary(
              key: _shareKey,
              child: _ShareCard(
                check: check,
                from: from,
                to: to,
                rule: rule,
                dataVersion: data.version,
              ),
            ),
            const SizedBox(height: 8),
            Text(rule.status.explanation, style: TextStyle(fontSize: 15, height: 1.5, color: extra.muted)),
            const SectionLabel('Before you fly'),
            CardBox(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  _Tip(
                    icon: Icons.badge_outlined,
                    title: 'Passport validity',
                    text: validity?.advice ??
                        'Many countries ask for 6 months of validity and blank pages. '
                            'Add your expiry date to see how yours compares.',
                    status: validity?.summary,
                    statusTone: validity?.tone,
                    action: TextButton(
                      onPressed: () => pickPassportExpiry(context, scope.state),
                      child: Text(expiry == null ? 'Add expiry date' : 'Change expiry date'),
                    ),
                  ),
                  Divider(height: 1, color: extra.divider),
                  const _Tip(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Return or onward ticket',
                    text: 'Border officers may ask to see it, along with your hotel booking.',
                  ),
                  Divider(height: 1, color: extra.divider),
                  const _Tip(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Proof of funds',
                    text: 'Some countries ask how you will pay for your stay. Keep a card or bank statement ready.',
                  ),
                  if (rule.status == EntryStatus.eVisa || rule.status == EntryStatus.eta) ...[
                    Divider(height: 1, color: extra.divider),
                    _Tip(
                      icon: Icons.gpp_maybe_outlined,
                      title: 'Use the official website',
                      text: 'Apply only on the government website of $to. Many look-alike sites charge extra fees.',
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _Disclaimer(version: data.version),
        ],
      ),
    );
  }
}

/// The part of the result that is shared as a picture.
class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.check,
    required this.from,
    required this.to,
    required this.rule,
    required this.dataVersion,
  });

  final TripCheck check;
  final String from;
  final String to;
  final VisaRule rule;
  final String dataVersion;

  @override
  Widget build(BuildContext context) {
    final extra = StamplyColors.of(context);
    return Container(
      // Same color as the page, so on screen it looks like plain content and
      // the shared picture gets a clean margin around it.
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Hero(title: rule.status.headline, subtitle: rule.stayText, stamp: rule.status),
          const SizedBox(height: 16),
          Text(
            '${flagEmoji(check.passport)} $from  →  ${flagEmoji(check.destination)} $to',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.3),
          ),
          const SizedBox(height: 4),
          Text('$from passport holders', style: TextStyle(fontSize: 14, color: extra.muted)),
          const SizedBox(height: 16),
          Row(
            children: [
              const StamplyLogo(size: 22),
              const SizedBox(width: 8),
              const Text(
                'Stamply',
                style: TextStyle(fontFamily: Brand.displayFont, fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const Spacer(),
              Text('Data from $dataVersion', style: TextStyle(fontSize: 12, color: extra.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.title, required this.subtitle, required this.stamp});

  final String title;
  final String? subtitle;
  final EntryStatus? stamp;

  @override
  Widget build(BuildContext context) {
    final extra = StamplyColors.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: extra.hero, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          if (stamp != null) ...[
            _Stamp(status: stamp!),
            const SizedBox(width: 20),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ENTRY STATUS',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.0,
                    color: extra.onHero.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: Brand.displayFont,
                    fontSize: 26,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: extra.onHero,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(subtitle!, style: TextStyle(fontSize: 15, color: extra.onHero.withValues(alpha: 0.9))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Round passport stamp, slightly rotated, in the status color.
class _Stamp extends StatelessWidget {
  const _Stamp({required this.status});

  final EntryStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.onHero;
    return Semantics(
      label: '${status.label} stamp',
      child: Transform.rotate(
        angle: -10 * math.pi / 180,
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 4),
          ),
          padding: const EdgeInsets.all(6),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(status.icon, color: color, size: 30),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    child: Text(
                      status.stampText,
                      style: TextStyle(
                        fontFamily: Brand.displayFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 1.0,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({
    required this.icon,
    required this.title,
    required this.text,
    this.status,
    this.statusTone,
    this.action,
  });

  final IconData icon;
  final String title;
  final String text;

  /// Optional colored line under the title, e.g. "8 months left".
  final String? status;
  final EntryStatus? statusTone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                if (status != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusTone?.background(brightness),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: statusTone?.foreground(brightness),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(text, style: TextStyle(fontSize: 14, height: 1.4, color: StamplyColors.of(context).muted)),
                if (action != null) Align(alignment: Alignment.centerLeft, child: action!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    final extra = StamplyColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: extra.divider, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: extra.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'General guidance only. Visa rules change often — always confirm with the '
              'embassy or official government website before you travel. Data from $version.',
              style: TextStyle(fontSize: 13, height: 1.5, color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
