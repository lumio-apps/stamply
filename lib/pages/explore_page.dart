import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/l10n.dart';
import '../models.dart';
import '../status_text.dart';
import '../theme.dart';
import '../widgets.dart';
import 'compare_page.dart';
import 'country_picker_page.dart';
import 'ranking_page.dart';
import 'result_page.dart';

/// "Explore" tab: every destination for the user's passport, grouped by status.
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  EntryStatus? _filter;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final state = scope.state;
    final data = scope.repo.data;
    final l = context.l10n;
    final extra = StamplyColors.of(context);
    final passport = state.passport;
    final b = Theme.of(context).brightness;

    Future<void> choosePassport() async {
      final code = await pickCountry(context, title: l.myPassport, selected: passport);
      if (code != null) state.setPassport(code);
    }

    if (passport == null) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.travel_explore, size: 56, color: extra.muted),
                const SizedBox(height: 16),
                Text(l.whereCanIGo, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  l.exploreEmptyBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: extra.muted),
                ),
                const SizedBox(height: 24),
                FilledButton(onPressed: choosePassport, child: Text(l.choosePassport)),
              ],
            ),
          ),
        ),
      );
    }

    final all = data.destinationsFor(passport);
    final counts = <EntryStatus, int>{};
    for (final e in all) {
      counts[e.value.status] = (counts[e.value.status] ?? 0) + 1;
    }
    final q = _query.trim().toLowerCase();
    final shown = all
        .where((e) => _filter == null || e.value.status == _filter)
        .where((e) =>
            q.isEmpty ||
            scope.nameOf(e.key).toLowerCase().contains(q) ||
            data.nameOf(e.key).toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => scope.nameOf(a.key).toLowerCase().compareTo(scope.nameOf(b.key).toLowerCase()));
    final score = data.score(passport);
    final second = state.passport2;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverList.list(
              children: [
                Text(l.exploreTitle, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                if (second != null) ...[
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final code in [passport, second])
                        ChoiceChip(
                          avatar: Text(flagEmoji(code)),
                          label: Text(scope.nameOf(code)),
                          selected: code == passport,
                          onSelected: (_) {
                            if (code != passport) state.swapPassports();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                SectionLabel(l.passportPower),
                CardBox(
                  child: ListTile(
                    onTap: choosePassport,
                    leading: CountryBadge(code: passport),
                    title: Text(scope.nameOf(passport),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${l.rankOf(data.rank(passport), data.rankedCount)}\n'
                      '${l.destinationsNoVisa(score)}',
                      style: TextStyle(color: extra.muted, height: 1.4),
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.edit_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const RankingPage())),
                        icon: const Icon(Icons.leaderboard_outlined),
                        label: Text(l.rankingTitle, textAlign: TextAlign.center),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ComparePage(first: passport, second: second))),
                        icon: const Icon(Icons.compare_arrows),
                        label: Text(l.comparePassports, textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    labelText: l.searchDestination,
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: extra.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l.allCount(all.length)),
                      selected: _filter == null,
                      onSelected: (_) => setState(() => _filter = null),
                    ),
                    for (final s in EntryStatus.values)
                      if ((counts[s] ?? 0) > 0)
                        ChoiceChip(
                          avatar: Icon(s.icon, size: 18, color: s.foreground(b)),
                          label: Text(l.chipCount(s.label(l), counts[s]!)),
                          selected: _filter == s,
                          onSelected: (on) => setState(() => _filter = on ? s : null),
                        ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          if (shown.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l.noDestinationsMatch,
                    textAlign: TextAlign.center, style: TextStyle(color: extra.muted)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
              sliver: SliverList.builder(
                itemCount: shown.length,
                itemBuilder: (context, i) {
                  final e = shown[i];
                  final check = TripCheck(passport, e.key);
                  return ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    leading: CountryBadge(code: e.key, size: 40),
                    title: Text(scope.nameOf(e.key), maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: StatusPill(rule: e.value),
                    onTap: () {
                      state.addRecent(check);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ResultPage(check: check)),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
