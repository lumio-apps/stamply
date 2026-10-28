import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../country_facts.dart';
import '../exchange_rates.dart';
import '../l10n/l10n.dart';
import '../models.dart';
import '../official_links.dart';
import '../passport_validity.dart';
import '../share.dart';
import '../status_text.dart';
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
    final failed = context.l10n.couldNotShare;
    setState(() => _sharing = true);
    try {
      // Let the card repaint with a solid background before taking the picture.
      await WidgetsBinding.instance.endOfFrame;
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
      messenger.showSnackBar(SnackBar(content: Text(failed)));
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
    final l = context.l10n;
    final rule = data.rule(check.passport, check.destination);
    final saved = scope.state.isSaved(check);
    final from = scope.nameOf(check.passport);
    final to = scope.nameOf(check.destination);
    final expiry = scope.state.passportExpiry;
    final validity = expiry == null ? null : PassportValidity.check(expiry, DateTime.now());

    final state = scope.state;
    // With two passports: is the other one better for this trip?
    final otherCode = check.passport == state.passport
        ? state.passport2
        : (check.passport == state.passport2 ? state.passport : null);
    final otherRule = otherCode == null ? null : data.rule(otherCode, check.destination);
    final otherBetter = rule != null &&
        otherCode != null &&
        otherRule != null &&
        otherRule.status.index < rule.status.index;
    final stay = rule?.stayText(l);
    final shareText = rule == null
        ? ''
        : l.shareMessage(
            from,
            to,
            stay == null ? rule.status.headline(l) : '${rule.status.headline(l)} · $stay',
          );

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
              tooltip: l.shareAsImage,
              icon: _sharing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.ios_share),
              onPressed: _sharing ? null : () => _share(shareText),
            ),
          if (check.passport == scope.state.passport)
            IconButton(
              tooltip: scope.state.inTrip(check.destination) ? l.tripRemove : l.tripAdd,
              icon: Icon(scope.state.inTrip(check.destination)
                  ? Icons.luggage
                  : Icons.luggage_outlined),
              onPressed: () {
                final inTrip = scope.state.inTrip(check.destination);
                if (inTrip) {
                  scope.state.removeFromTrip(check.destination);
                } else {
                  scope.state.addToTrip(check.destination);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(inTrip ? l.tripRemoved : l.tripAdded)),
                );
              },
            ),
          IconButton(
            tooltip: saved ? l.removeFromSaved : l.saveThisCheck,
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
            _Hero(
              title: l.ownCountryTitle,
              subtitle: l.ownCountrySubtitle,
              stamp: null,
            )
          else if (rule == null)
            _Hero(
              title: l.noDataTitle,
              subtitle: l.noDataSubtitle(from, to),
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
                solid: _sharing,
              ),
            ),
            const SizedBox(height: 8),
            Text(rule.status.explanation(l), style: TextStyle(fontSize: 15, height: 1.5, color: extra.muted)),
            if (otherBetter) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: otherRule.status.background(Theme.of(context).brightness),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(otherRule.status.icon,
                        color: otherRule.status.foreground(Theme.of(context).brightness)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l.betterWithOther(
                          scope.nameOf(otherCode),
                          otherRule.status.headline(l),
                        ),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: otherRule.status.foreground(Theme.of(context).brightness),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SectionLabel(l.beforeYouFly),
            CardBox(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  _Tip(
                    icon: Icons.badge_outlined,
                    title: l.passportValidity,
                    text: validity?.advice(l) ?? l.validityHint,
                    status: validity?.summary(l),
                    statusTone: validity?.tone,
                    action: TextButton(
                      onPressed: () => pickPassportExpiry(context, scope.state),
                      child: Text(expiry == null ? l.addExpiryDate : l.changeExpiryDate),
                    ),
                  ),
                  Divider(height: 1, color: extra.divider),
                  _Tip(
                    icon: Icons.confirmation_number_outlined,
                    title: l.returnTicket,
                    text: l.returnTicketText,
                  ),
                  Divider(height: 1, color: extra.divider),
                  _Tip(
                    icon: Icons.account_balance_wallet_outlined,
                    title: l.proofOfFunds,
                    text: l.proofOfFundsText,
                  ),
                  if (rule.status == EntryStatus.eVisa || rule.status == EntryStatus.eta) ...[
                    Divider(height: 1, color: extra.divider),
                    _Tip(
                      icon: Icons.gpp_maybe_outlined,
                      title: l.officialWebsite,
                      text: l.officialWebsiteText(to),
                    ),
                  ],
                ],
              ),
            ),
          ],
          _FactsSection(code: check.destination, passport: check.passport, name: to),
          _OfficialLinkSection(code: check.destination, name: to),
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
    required this.solid,
  });

  /// True while the card is turned into a picture: needs a solid background.
  final bool solid;

  final TripCheck check;
  final String from;
  final String to;
  final VisaRule rule;
  final String dataVersion;

  @override
  Widget build(BuildContext context) {
    final extra = StamplyColors.of(context);
    final l = context.l10n;
    return Container(
      // Same color as the screen; solid so the shared picture has a clean margin.
      color: solid ? extra.base : Colors.transparent,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Hero(title: rule.status.headline(l), subtitle: rule.stayText(l), stamp: rule.status),
          const SizedBox(height: 16),
          Text(
            '${flagEmoji(check.passport)} $from  →  ${flagEmoji(check.destination)} $to',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.3),
          ),
          const SizedBox(height: 4),
          Text(l.passportHolders(from), style: TextStyle(fontSize: 14, color: extra.muted)),
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
              Text(l.dataFrom(dataVersion), style: TextStyle(fontSize: 12, color: extra.muted)),
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
    final texts = Column(
      children: [
        Text(
          context.l10n.entryStatusLabel.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, letterSpacing: 1.2, color: extra.muted),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: Brand.displayFont,
            fontSize: 28,
            height: 1.12,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: extra.muted),
          ),
        ],
      ],
    );
    if (stamp == null) {
      return CardBox(
        radius: 30,
        padding: const EdgeInsets.all(24),
        child: SizedBox(width: double.infinity, child: texts),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          const SizedBox(height: 12),
          _Stamp(status: stamp!),
          const SizedBox(height: 28),
          texts,
        ],
      ),
    );
  }
}

/// Round passport stamp: a flat ring in the status color, tilted a little.
/// It fades in once (unless the phone asks for reduced motion).
class _Stamp extends StatefulWidget {
  const _Stamp({required this.status});

  final EntryStatus status;

  @override
  State<_Stamp> createState() => _StampState();
}

class _StampState extends State<_Stamp> with SingleTickerProviderStateMixin {
  late final AnimationController _in;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (motionOff(context)) {
      _in.value = 1;
    } else {
      _in.forward();
    }
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final color = status.foreground(Theme.of(context).brightness);
    final pop = CurvedAnimation(parent: _in, curve: Curves.easeOutBack);
    return Semantics(
      label: context.l10n.stampSemantics(status.label(context.l10n)),
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _in,
          builder: (context, child) => Opacity(
            opacity: _in.value.clamp(0.0, 1.0),
            child: Transform.scale(scale: 1.25 - 0.25 * pop.value, child: child),
          ),
          child: Transform.rotate(
            angle: -6 * math.pi / 180,
            child: Container(
              width: 184,
              height: 184,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(status.icon, color: color, size: 40),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FittedBox(
                      child: Text(
                        status.stampText(context.l10n),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: Brand.displayFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          height: 1.05,
                          letterSpacing: 1.2,
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
      ),
    );
  }
}

/// "About (country)": capital, currency, calling code and languages, plus an
/// exchange rate the user can refresh. Shown only when the facts are available.
class _FactsSection extends StatelessWidget {
  const _FactsSection({required this.code, required this.passport, required this.name});

  final String code;
  final String passport;
  final String name;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final extra = StamplyColors.of(context);
    return FutureBuilder<CountryFacts>(
      future: CountryFacts.load(),
      builder: (context, snapshot) {
        final facts = snapshot.data;
        final fact = facts?.of(code);
        if (fact == null || fact.isEmpty) return const SizedBox.shrink();
        final home = facts?.of(passport)?.currencyCodes;
        final rows = <(String, String)>[
          if (fact.capital != null) (l.factCapital, fact.capital!),
          if (fact.currencies.isNotEmpty) (l.factCurrency, fact.currencies.join(', ')),
          if (fact.callingCode != null) (l.factCallingCode, fact.callingCode!),
          if (fact.languages.isNotEmpty) (l.factLanguages, fact.languages.join(', ')),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(l.factsTitle(name)),
            CardBox(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  for (final (i, row) in rows.indexed) ...[
                    if (i > 0) Divider(height: 1, color: extra.divider),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(row.$1, style: TextStyle(fontSize: 14, color: extra.muted)),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              row.$2,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (fact.currencyCodes.isNotEmpty) ...[
                    Divider(height: 1, color: extra.divider),
                    _RatesBlock(
                      destination: fact.currencyCodes,
                      home: (home != null && home.isNotEmpty) ? home.first : null,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Exchange rate lines. Nothing is downloaded until the user taps the button;
/// the last download is kept so it also shows offline, with its date.
class _RatesBlock extends StatefulWidget {
  const _RatesBlock({required this.destination, required this.home});

  final List<String> destination;
  final String? home;

  @override
  State<_RatesBlock> createState() => _RatesBlockState();
}

class _RatesBlockState extends State<_RatesBlock> {
  ExchangeRates? _rates;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    ExchangeRates.cached().then((r) {
      if (mounted && r != null) setState(() => _rates = r);
    });
  }

  Future<void> _refresh() async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.l10n.rateFailed;
    setState(() => _loading = true);
    final fresh = await ExchangeRates.fetch();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (fresh != null) _rates = fresh;
    });
    if (fresh == null) messenger.showSnackBar(SnackBar(content: Text(failed)));
  }

  static String _number(double v, String locale) {
    final digits = v >= 100 ? 1 : (v >= 1 ? 2 : (v >= 0.01 ? 4 : 6));
    try {
      return NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: digits).format(v);
    } catch (_) {
      return v.toStringAsFixed(digits);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final extra = StamplyColors.of(context);
    final locale = Localizations.localeOf(context).toString();
    final rates = _rates;

    final lines = <String>[];
    if (rates != null) {
      final bases = <String>{'USD', if (widget.home != null) widget.home!};
      for (final to in widget.destination) {
        for (final from in bases) {
          if (from == to) continue;
          final r = rates.rate(from, to);
          if (r != null) lines.add('1 $from = ${_number(r, locale)} $to');
        }
      }
    }

    final button = TextButton.icon(
      onPressed: _loading ? null : _refresh,
      icon: _loading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.refresh, size: 18),
      label: Text(rates == null ? l.rateShow : l.rateRefresh),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rates != null) ...[
            Text(l.factRate, style: TextStyle(fontSize: 14, color: extra.muted)),
            const SizedBox(height: 6),
            if (lines.isEmpty)
              Text(l.rateUnavailable, style: TextStyle(fontSize: 14, color: extra.muted))
            else
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(line,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
            if (rates.date.isNotEmpty)
              Text(l.rateDate(rates.date), style: TextStyle(fontSize: 12, color: extra.muted)),
          ],
          Align(alignment: AlignmentDirectional.centerStart, child: button),
        ],
      ),
    );
  }
}

/// Link to the official government website of the destination, when the app
/// has a hand-checked one. Asks before leaving the app.
class _OfficialLinkSection extends StatelessWidget {
  const _OfficialLinkSection({required this.code, required this.name});

  final String code;
  final String name;

  Future<void> _open(BuildContext context, Uri uri) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.linkOpenTitle),
        content: Text(l.linkOpenBody(uri.host)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.linkOpenGo)),
        ],
      ),
    );
    if (go != true) return;
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!opened) messenger.showSnackBar(SnackBar(content: Text(l.linkFailed)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return FutureBuilder<OfficialLinks>(
      future: OfficialLinks.load(),
      builder: (context, snapshot) {
        final uri = snapshot.data?.of(code);
        if (uri == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(l.officialLinkTitle),
            CardBox(
              child: ListTile(
                leading: const Icon(Icons.open_in_new),
                title: Text(l.officialLinkFor(name),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(uri.host),
                onTap: () => _open(context, uri),
              ),
            ),
          ],
        );
      },
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
                if (action != null) Align(alignment: AlignmentDirectional.centerStart, child: action!),
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
              context.l10n.disclaimerResult(version),
              style: TextStyle(fontSize: 13, height: 1.5, color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
