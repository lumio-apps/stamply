import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stamply/l10n/l10n.dart';
import 'package:stamply/passport_validity.dart';
import 'package:stamply/widgets.dart';

void main() {
  final now = DateTime(2026, 10, 14);

  test('months count whole calendar months', () {
    expect(monthsUntil(DateTime(2026, 1, 31), DateTime(2026, 2, 28)), 0);
    expect(monthsUntil(DateTime(2026, 10, 14), DateTime(2027, 4, 14)), 6);
  });

  test('6 months or more is good', () {
    final v = PassportValidity.check(DateTime(2027, 4, 15), now);
    expect(v.level, ValidityLevel.good);
    expect(v.months, 6);
  });

  test('3 to 6 months is short', () {
    expect(PassportValidity.check(DateTime(2027, 3, 1), now).level, ValidityLevel.short);
  });

  test('under 3 months is critical', () {
    expect(PassportValidity.check(DateTime(2026, 12, 20), now).level, ValidityLevel.critical);
  });

  test('past date is expired', () {
    final v = PassportValidity.check(DateTime(2026, 10, 1), now);
    expect(v.level, ValidityLevel.expired);
    expect(v.summary(lookupAppLocalizations(const Locale('en'))), 'Expired 13 days ago');
  });

  test('flag emoji from country code', () {
    expect(flagEmoji('IN'), '\u{1F1EE}\u{1F1F3}');
    expect(flagEmoji('in'), '\u{1F1EE}\u{1F1F3}');
    expect(flagEmoji('1'), '');
  });
}
