import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';

/// The offline world map: one outline (a list of closed paths) per country.
/// Drawn from `assets/data/world_map.json`, made by `tool/build_map.py`.
class WorldMap {
  WorldMap._(this.width, this.height, this.countries);

  /// Size of the map's own coordinate space.
  final double width;
  final double height;
  final Map<String, List<Path>> countries;

  bool get isEmpty => countries.isEmpty;

  static Future<WorldMap> load() async =>
      parse(await rootBundle.loadString('assets/data/world_map.json'));

  static WorldMap parse(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final width = (json['w'] as num).toDouble();
    final height = (json['h'] as num).toDouble();
    final countries = <String, List<Path>>{};
    final raw = (json['c'] as Map<String, dynamic>?) ?? const {};
    for (final entry in raw.entries) {
      final paths = <Path>[];
      for (final ring in entry.value as List<dynamic>) {
        final xy = (ring as List<dynamic>).cast<num>();
        if (xy.length < 6) continue;
        final path = Path()..moveTo(xy[0].toDouble(), xy[1].toDouble());
        for (var i = 2; i + 1 < xy.length; i += 2) {
          path.lineTo(xy[i].toDouble(), xy[i + 1].toDouble());
        }
        path.close();
        paths.add(path);
      }
      if (paths.isNotEmpty) countries[entry.key] = paths;
    }
    return WorldMap._(width, height, countries);
  }

  /// The country under [point] (in map coordinates), or null.
  String? countryAt(Offset point) {
    for (final entry in countries.entries) {
      for (final path in entry.value) {
        if (path.contains(point)) return entry.key;
      }
    }
    return null;
  }
}
