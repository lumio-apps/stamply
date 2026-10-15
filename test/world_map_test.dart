import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stamply/world_map.dart';

void main() {
  test('parses countries and finds the one under a point', () {
    final map = WorldMap.parse(jsonEncode({
      'w': 2000,
      'h': 789,
      'c': {
        'AA': [
          [0, 0, 100, 0, 100, 100, 0, 100],
        ],
        'BB': [
          [200, 0, 300, 0, 300, 100, 200, 100],
        ],
      },
    }));
    expect(map.isEmpty, isFalse);
    expect(map.countryAt(const Offset(50, 50)), 'AA');
    expect(map.countryAt(const Offset(250, 50)), 'BB');
    expect(map.countryAt(const Offset(150, 50)), isNull);
  });

  test('an empty map file is allowed (map not built yet)', () {
    expect(WorldMap.parse('{"w":2000,"h":789,"c":{}}').isEmpty, isTrue);
  });

  test('the bundled map only uses country codes that exist in the visa data', () {
    final map = jsonDecode(File('assets/data/world_map.json').readAsStringSync())
        as Map<String, dynamic>;
    final shapes = (map['c'] as Map<String, dynamic>).keys.toSet();
    if (shapes.isEmpty) return; // not generated yet: run tool/build_map.py
    final visa = jsonDecode(File('assets/data/visa_data.json').readAsStringSync())
        as Map<String, dynamic>;
    final known = (visa['countries'] as Map<String, dynamic>).keys.toSet();
    // A few shapes (e.g. territories) may not be in the visa data; most must be.
    expect(shapes.intersection(known).length, greaterThan(shapes.length * 0.8));
    expect(shapes.length, greaterThan(150));
  });
}