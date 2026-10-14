import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/l10n.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'country_picker_page.dart';

/// Puts two passports side by side and lists where their rules differ.
class ComparePage extends StatefulWidget {
  const ComparePage({super.key, this.first, this.second});

  final String? first;
  final String? second;

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  String? _a;
  String? _b;

  @override
  void initState() {
    super.initState();
    _a = widget.first;
    _b = widget.second;
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final data = scope.repo.data;
    final l = context.l10n;
    final extra = StamplyColors.of(context);
    final a = _a;
    final b = _b;

    Future<void> pick(String title, String? current, void Function(String) set) async {
      final code = await pickCountry(context, title: title, selected: current);
      if (code != null) setState(() => set(code));
    }

    final children = <Widget>[
      Text(l.compareHint, style: TextStyle(fontSize: 15, height: 1.5, color: extra.muted)),
      const SizedBox(height: 16),
      CardBox(
        child: Column(
          children: [
            _PassportTile(
              label: l.compareFirst,
              code: a,
              onTap: () => pick(l.compareFirst, a, (c) => _a = c),
            ),
            Divider(height: 1, color: extra.divider),
            _PassportTile(
              label: l.compareSecond,
              code: b,
              onTap: () => pick(l.compareSecond, b, (c) => _b = c),
            ),
          ],
        ),
      ),
    ];

    if (a != null && b != null && a != b) {
      final diffs = <(String, VisaRule, VisaRule)>[];
      var easierA = 0;
      var easierB = 0;
      for (final code in data.countries.keys) {
        final ra = data.rule(a, code);
        final rb = data.rule(b, code);
        if (ra == null || rb == null) continue;
        if (ra.status == rb.status && ra.days == rb.days) continue;
        diffs.add((code, ra, rb));
        if (ra.status.index < rb.status.index) easierA++;
        if (rb.status.index < ra.status.index) easierB++;
      }
      diffs.sort((x, y) =>
          scope.nameOf(x.$1).toLowerCase().compareTo(scope.nameOf(y.$1).toLowerCase()));

      children.addAll([
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _Summary(code: a, easier: easierA)),
            const SizedBox(width: 12),
            Expanded(child: _Summary(code: b, easier: easierB)),
          ],
        ),
        SectionLabel(l.compareDiffer(diffs.length)),
        if (diffs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(l.compareSame,
                textAlign: TextAlign.center, style: TextStyle(color: extra.muted)),
          )
        else
          CardBox(
            child: Column(
              children: [
                for (final (i, d) in diffs.indexed) ...[
                  if (i > 0) Divider(height: 1, color: extra.divider),
                  ListTile(
                    leading: CountryBadge(code: d.$1, size: 40),
                    title: Text(scope.nameOf(d.$1), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _FlagPill(code: a, rule: d.$2),
                          _FlagPill(code: b, rule: d.$3),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ]);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.comparePassports)),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: children),
    );
  }
}

class _PassportTile extends StatelessWidget {
  const _PassportTile({required this.label, required this.code, required this.onTap});

  final String label;
  final String? code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final extra = StamplyColors.of(context);
    final scope = AppScope.of(context);
    final c = code;
    return ListTile(
      onTap: onTap,
      leading: c == null
          ? Container(
              width: 44,
              height: 44,
              decoration:
                  BoxDecoration(color: extra.divider, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.add, color: extra.muted),
            )
          : CountryBadge(code: c),
      title: Text(
        c == null ? context.l10n.chooseCountry : scope.nameOf(c),
        style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w600, color: c == null ? extra.muted : null),
      ),
      subtitle: Text(label, style: TextStyle(color: extra.muted)),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

/// Rank, score and "easier" count for one of the two passports.
class _Summary extends StatelessWidget {
  const _Summary({required this.code, required this.easier});

  final String code;
  final int easier;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final data = scope.repo.data;
    final l = context.l10n;
    final extra = StamplyColors.of(context);
    final name = scope.nameOf(code);
    return CardBox(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CountryBadge(code: code, size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('${data.score(code)}',
              style: const TextStyle(
                  fontFamily: Brand.displayFont, fontSize: 30, fontWeight: FontWeight.w700)),
          Text(l.rankOf(data.rank(code), data.rankedCount),
              style: TextStyle(fontSize: 13, color: extra.muted)),
          const SizedBox(height: 8),
          Text(l.compareEasier(name, easier), style: const TextStyle(fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}

class _FlagPill extends StatelessWidget {
  const _FlagPill({required this.code, required this.rule});

  final String code;
  final VisaRule rule;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(flagEmoji(code), style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        StatusPill(rule: rule),
      ],
    );
  }
}
