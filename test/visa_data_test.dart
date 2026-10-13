import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stamply/models.dart';
import 'package:stamply/visa_repository.dart';

void main() {
  final data = VisaData.parse(File('assets/data/visa_data.json').readAsStringSync());

  test('bundled data loads', () {
    expect(data.countries.length, greaterThan(150));
    expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(data.version), isTrue);
  });

  test('every passport has rules for most destinations', () {
    for (final code in data.countries.keys) {
      expect(data.destinationsFor(code).length, greaterThan(150), reason: code);
    }
  });

  test('same country has no rule', () {
    expect(data.rule('IN', 'IN'), isNull);
  });

  test('numbers mean visa-free days', () {
    final rule = data.destinationsFor('DE').map((e) => e.value).firstWhere((r) => r.days != null);
    expect(rule.status, EntryStatus.visaFree);
  });

  test('rejects broken files', () {
    expect(() => VisaData.parse('{"schema": 2}'), throwsFormatException);
    expect(() => VisaData.parse('not json'), throwsFormatException);
  });
}
