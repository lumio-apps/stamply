import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/l10n.dart';
import '../models.dart';
import '../schengen.dart';
import '../share.dart';
import '../status_text.dart';
import '../theme.dart';
import '../widgets.dart';
import 'country_picker_page.dart';
import 'result_page.dart';
import 'schengen_page.dart';

/// Several countries in one trip, each with the rule for the user's passport.
class TripPage extends StatelessWidget {
  const TripPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final state = scope.state;
    final data = scope.repo.data;
    final l = context.l10n;
    final extra = StamplyColors.of(context);
    final passport = state.passport;

    final stops = <({String code, VisaRule? rule})>[
      if (passport != null)
        for (final code in state.trip)
          if (code != passport) (code: code, rule: data.rule(passport, code)),
    ];
    final needsAction = stops.where((s) {
      final status = s.rule?.status;
      return status != null &&
          status != EntryStatus.visaFree &&
          status != EntryStatus.visaOnArrival;
    }).length;
    final closed = stops.where((s) => s.rule?.status == EntryStatus.noAdmission).length;
    final schengenStops = stops.where((s) => kSchengenCountries.contains(s.code)).length;

    Future<void> addCountry() async {
      final code = await pickCountry(context, title: l.tripAddCountry);
      if (code != null) state.addToTrip(code);
    }

    String shareText() {
      final b = StringBuffer(l.tripShareHeader(scope.nameOf(passport!)));
      for (final s in stops) {
        final rule = s.rule;
        b.write('\n${flagEmoji(s.code)} ${scope.nameOf(s.code)}: '
            '${rule == null ? '-' : rule.shortLabel(l)}');
      }
      return b.toString();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tripPlanner),
        actions: [
          if (stops.isNotEmpty)
            IconButton(
              tooltip: l.tripShare,
              icon: const Icon(Icons.ios_share),
              onPressed: () => ShareService.shareText(shareText()),
            ),
          if (state.trip.isNotEmpty)
            IconButton(
              tooltip: l.tripClear,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: state.clearTrip,
            ),
        ],
      ),
      body: passport == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l.tripNeedPassport,
                    textAlign: TextAlign.center, style: TextStyle(color: extra.muted)),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                CardBox(
                  child: ListTile(
                    leading: CountryBadge(code: passport),
                    title: Text(scope.nameOf(passport),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    subtitle: Text(l.myPassport, style: TextStyle(color: extra.muted)),
                  ),
                ),
                const SizedBox(height: 12),
                if (stops.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(Icons.luggage_outlined, size: 48, color: extra.muted),
                        const SizedBox(height: 12),
                        Text(l.tripEmpty,
                            textAlign: TextAlign.center, style: TextStyle(color: extra.muted)),
                      ],
                    ),
                  )
                else ...[
                  CardBox(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              needsAction == 0
                                  ? Icons.check_circle_outline
                                  : Icons.assignment_late_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                needsAction == 0 ? l.tripAllClear : l.tripNeedsAction(needsAction),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        if (closed > 0) ...[
                          const SizedBox(height: 8),
                          Text(l.tripNoAdmission(closed),
                              style: TextStyle(fontSize: 14, color: extra.muted)),
                        ],
                        if (schengenStops >= 2) ...[
                          const SizedBox(height: 8),
                          Text(l.tripSchengenNote,
                              style: TextStyle(fontSize: 14, height: 1.4, color: extra.muted)),
                          TextButton(
                            onPressed: () => Navigator.push(
                                context, MaterialPageRoute(builder: (_) => const SchengenPage())),
                            child: Text(l.tripOpenSchengen),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  CardBox(
                    child: Column(
                      children: [
                        for (final (i, s) in stops.indexed) ...[
                          if (i > 0) Divider(height: 1, color: extra.divider),
                          ListTile(
                            leading: CountryBadge(code: s.code, size: 40),
                            title: Text(scope.nameOf(s.code),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (s.rule != null) StatusPill(rule: s.rule!),
                                IconButton(
                                  tooltip: l.tripRemove,
                                  icon: const Icon(Icons.close),
                                  onPressed: () => state.removeFromTrip(s.code),
                                ),
                              ],
                            ),
                            onTap: () {
                              final check = TripCheck(passport, s.code);
                              state.addRecent(check);
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => ResultPage(check: check)));
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: addCountry,
                  icon: const Icon(Icons.add),
                  label: Text(l.tripAddCountry),
                ),
              ],
            ),
    );
  }
}
