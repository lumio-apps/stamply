import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/l10n.dart';
import '../models.dart';
import '../status_text.dart';
import '../theme.dart';
import '../widgets.dart';
import '../world_map.dart';
import 'result_page.dart';

/// Offline world map, colored by what the user's passport needs for each country.
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final Future<WorldMap> _map = WorldMap.load();
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final state = scope.state;
    final data = scope.repo.data;
    final l = context.l10n;
    final extra = StamplyColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final passport = state.passport;

    return Scaffold(
      appBar: AppBar(title: Text(l.mapTitle)),
      body: passport == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l.tripNeedPassport,
                    textAlign: TextAlign.center, style: TextStyle(color: extra.muted)),
              ),
            )
          : FutureBuilder<WorldMap>(
              future: _map,
              builder: (context, snapshot) {
                final map = snapshot.data;
                if (map == null || map.isEmpty) {
                  return Center(
                    child: snapshot.connectionState == ConnectionState.done
                        ? Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(l.mapUnavailable,
                                textAlign: TextAlign.center, style: TextStyle(color: extra.muted)),
                          )
                        : const CircularProgressIndicator(),
                  );
                }

                final fills = <String, Color>{};
                for (final code in map.countries.keys) {
                  if (code == passport) {
                    fills[code] = scheme.primary;
                  } else {
                    final rule = data.rule(passport, code);
                    if (rule != null) {
                      fills[code] =
                          rule.status.foreground(brightness).withValues(alpha: 0.8);
                    }
                  }
                }
                final selected = _selected;
                final selectedRule =
                    selected == null || selected == passport ? null : data.rule(passport, selected);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text(l.mapHint, style: TextStyle(fontSize: 14, color: extra.muted)),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final width = box.maxWidth;
                          final height = width * map.height / map.width;
                          return InteractiveViewer(
                            minScale: 1,
                            maxScale: 12,
                            child: Center(
                              child: SizedBox(
                                width: width,
                                height: height,
                                child: GestureDetector(
                                  onTapUp: (d) {
                                    final k = width / map.width;
                                    final code = map.countryAt(d.localPosition / k);
                                    setState(() => _selected = code);
                                  },
                                  child: CustomPaint(
                                    painter: _MapPainter(
                                      map: map,
                                      fills: fills,
                                      noData: extra.divider,
                                      outline: extra.base,
                                      selected: selected,
                                      highlight: scheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          for (final s in EntryStatus.values)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: s.foreground(brightness).withValues(alpha: 0.8),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(s.label(l), style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: selected == null
                          ? Text(l.mapSmallNote, style: TextStyle(fontSize: 12, color: extra.muted))
                          : CardBox(
                              child: ListTile(
                                leading: CountryBadge(code: selected, size: 40),
                                title: Text(scope.nameOf(selected),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                trailing: selectedRule == null
                                    ? null
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          StatusPill(rule: selectedRule),
                                          const Icon(Icons.chevron_right),
                                        ],
                                      ),
                                onTap: selectedRule == null
                                    ? null
                                    : () {
                                        final check = TripCheck(passport, selected);
                                        state.addRecent(check);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => ResultPage(check: check)),
                                        );
                                      },
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.map,
    required this.fills,
    required this.noData,
    required this.outline,
    required this.selected,
    required this.highlight,
  });

  final WorldMap map;
  final Map<String, Color> fills;
  final Color noData;
  final Color outline;
  final String? selected;
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / map.width);
    final fill = Paint()..style = PaintingStyle.fill;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round
      ..color = outline;
    for (final entry in map.countries.entries) {
      fill.color = fills[entry.key] ?? noData;
      for (final path in entry.value) {
        canvas.drawPath(path, fill);
        canvas.drawPath(path, line);
      }
    }
    final pick = selected;
    if (pick != null && map.countries.containsKey(pick)) {
      final mark = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..color = highlight;
      for (final path in map.countries[pick]!) {
        canvas.drawPath(path, mark);
      }
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.fills != fills || old.selected != selected || old.outline != outline;
}
