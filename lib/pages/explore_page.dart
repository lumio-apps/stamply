import 'dart:math';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/l10n.dart';
import '../models.dart';
import '../regions.dart';
import '../status_text.dart';
import '../theme.dart';
import '../widgets.dart';
import 'compare_page.dart';
import 'country_picker_page.dart';
import 'ranking_page.dart';
import 'map_page.dart';
import 'result_page.dart';
import 'schengen_page.dart';
import 'trip_page.dart';

/// "Explore" tab: every destination for the user's passport, grouped by status.
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  EntryStatus? _filter;
  Region? _region;
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
        .where((e) => _region == null || regionOf(e.key) == _region)
        .where((e) =>
            q.isEmpty ||
            scope.nameOf(e.key).toLowerCase().contains(q) ||
            data.nameOf(e.key).toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => scope.nameOf(a.key).toLowerCase().compareTo(scope.nameOf(b.key).toLowerCase()));
    final score = data.score(passport);
    final second = state.passport2;

    // "Surprise me": a random place you can enter without applying first,
    // within the chosen region.
    final surprisePool = all.where((e) {
      final s = e.value.status;
      return (s == EntryStatus.visaFree ||
              s == EntryStatus.visaOnArrival ||
              s == EntryStatus.eta) &&
          (_region == null || regionOf(e.key) == _region);
    }).toList();
    void surprise() {
      final pick = surprisePool[Random().nextInt(surprisePool.length)];
      final check = TripCheck(passport, pick.key);
      state.addRecent(check);
      Navigator.push(context, MaterialPageRoute(builder: (_) => ResultPage(check: check)));
    }

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverList.list(
              children: [
                Rise(child: Text(l.exploreTitle, style: Theme.of(context).textTheme.headlineMedium)),
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
                Rise(
                  delay: const Duration(milliseconds: 90),
                  child: CardBox(
                    radius: 30,
                    child: InkWell(
                      onTap: choosePassport,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            _PowerRing(score: score, total: all.length),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(flagEmoji(passport), style: const TextStyle(fontSize: 20)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          scope.nameOf(passport),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: Brand.displayFont,
                                            fontSize: 21,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.edit_outlined, size: 18, color: extra.muted),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${l.rankOf(data.rank(passport), data.rankedCount)}\n'
                                    '${l.destinationsNoVisa(score)}',
                                    style: TextStyle(color: extra.muted, height: 1.4, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: NeuButton.icon(
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const RankingPage())),
                        icon: const Icon(Icons.leaderboard_outlined),
                        label: Text(l.rankingTitle, textAlign: TextAlign.center),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NeuButton.icon(
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: NeuButton.icon(
                        onPressed: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => const TripPage())),
                        icon: const Icon(Icons.luggage_outlined),
                        label: Text(l.tripPlanner, textAlign: TextAlign.center),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NeuButton.icon(
                        onPressed: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => const SchengenPage())),
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(l.schengenShort, textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                NeuButton.icon(
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const MapPage())),
                  icon: const Icon(Icons.public),
                  label: Text(l.mapTitle),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    labelText: l.searchDestination,
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: extra.field,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
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
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final r in Region.values)
                      ChoiceChip(
                        label: Text(r.label(l)),
                        selected: _region == r,
                        onSelected: (on) => setState(() => _region = on ? r : null),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                NeuButton.icon(
                  onPressed: surprisePool.isEmpty ? null : surprise,
                  icon: const Icon(Icons.casino_outlined),
                  label: Text(l.surpriseMe),
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
                  final tile = ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                  return i < 10 ? Rise(delay: Duration(milliseconds: 300 + 70 * i), child: tile) : tile;
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Round meter: how much of the world this passport reaches without a visa.
class _PowerRing extends StatelessWidget {
  const _PowerRing({required this.score, required this.total});

  final int score;
  final int total;

  @override
  Widget build(BuildContext context) {
    final extra = StamplyColors.of(context);
    final fraction = total == 0 ? 0.0 : (score / total).clamp(0.0, 1.0);
    final reduce = motionOff(context);
    return SizedBox(
      width: 96,
      height: 96,
      child: CustomPaint(
        painter: InsetPainter(colors: extra, radius: 48, depth: 0.8),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: fraction),
          duration: reduce ? Duration.zero : const Duration(milliseconds: 1500),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => CustomPaint(
            painter: _RingPainter(
              fraction: value,
              track: extra.shadowDark.withValues(alpha: 0.5),
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF5EE0A8)
                  : const Color(0xFF1F9D6B),
            ),
            child: Center(
              child: Text(
                '$score',
                style: const TextStyle(
                  fontFamily: Brand.displayFont,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.fraction, required this.track, required this.color});

  final double fraction;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arc = rect.deflate(9);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arc, 0, 6.2831853, false, base..color = track);
    if (fraction > 0) {
      canvas.drawArc(arc, -1.5707963, 6.2831853 * fraction, false, base..color = color);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.track != track || old.color != color;
}
