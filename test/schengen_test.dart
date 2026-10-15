import 'package:flutter_test/flutter_test.dart';
import 'package:stamply/reminder_service.dart';
import 'package:stamply/schengen.dart';

void main() {
  group('Schengen 90/180', () {
    test('a stay counts both its first and last day', () {
      final s = SchengenStay(DateTime(2026, 3, 1), DateTime(2026, 3, 10));
      expect(s.days, 10);
      expect(SchengenCalculator([s]).usedOn(DateTime(2026, 3, 10)), 10);
    });

    test('stays older than 180 days drop out of the window', () {
      final calc = SchengenCalculator([SchengenStay(DateTime(2026, 1, 1), DateTime(2026, 3, 31))]);
      // 90 days used on 31 Mar.
      expect(calc.usedOn(DateTime(2026, 3, 31)), 90);
      expect(calc.remainingOn(DateTime(2026, 3, 31)), 0);
      // The window of 29 Jun reaches back to 1 Jan (180 days), 90 still used.
      expect(calc.usedOn(DateTime(2026, 6, 29)), 90);
      // One day later the first day has dropped out.
      expect(calc.usedOn(DateTime(2026, 6, 30)), 89);
    });

    test('nextFreeDay finds the day a place opens up', () {
      final calc = SchengenCalculator([SchengenStay(DateTime(2026, 1, 1), DateTime(2026, 3, 31))]);
      expect(calc.nextFreeDay(DateTime(2026, 4, 15)), DateTime(2026, 6, 30));
      expect(calc.nextFreeDay(DateTime(2026, 7, 1)), isNull);
    });

    test('maxStayFrom stops at the 90 day limit', () {
      expect(SchengenCalculator([]).maxStayFrom(DateTime(2026, 5, 1)), 90);
      final calc = SchengenCalculator([SchengenStay(DateTime(2026, 3, 1), DateTime(2026, 3, 30))]);
      // 30 days used, so 60 more are possible straight away.
      expect(calc.maxStayFrom(DateTime(2026, 4, 1)), 60);
    });

    test('maxStayFrom is zero when all 90 days are used', () {
      final calc = SchengenCalculator([SchengenStay(DateTime(2026, 1, 1), DateTime(2026, 3, 31))]);
      expect(calc.maxStayFrom(DateTime(2026, 4, 15)), 0);
    });

    test('stay keys round-trip and reorder swapped dates', () {
      final s = SchengenStay(DateTime(2026, 5, 9), DateTime(2026, 5, 2));
      expect(s.key, '2026-05-02|2026-05-09');
      expect(SchengenStay.fromKey(s.key), s);
      expect(SchengenStay.fromKey('nonsense'), isNull);
    });

    test('Schengen list has the expected size and members', () {
      expect(kSchengenCountries.length, 29);
      expect(kSchengenCountries, containsAll(['FR', 'DE', 'CH', 'NO']));
      expect(kSchengenCountries.contains('IE'), isFalse);
      expect(kSchengenCountries.contains('CY'), isFalse);
    });
  });

  group('Passport expiry reminders', () {
    test('plans 6, 3 and 1 month before, at 10:00', () {
      final plan = ReminderService.plan(DateTime(2027, 9, 15), DateTime(2026, 10, 15));
      expect(plan.map((s) => s.monthsBefore), [6, 3, 1]);
      expect(plan[0].at, DateTime(2027, 3, 15, 10));
      expect(plan[1].at, DateTime(2027, 6, 15, 10));
      expect(plan[2].at, DateTime(2027, 8, 15, 10));
    });

    test('skips reminders that are already in the past', () {
      final plan = ReminderService.plan(DateTime(2027, 1, 15), DateTime(2026, 10, 15));
      expect(plan.map((s) => s.monthsBefore), [3, 1]);
    });

    test('clamps the day for shorter months', () {
      final plan = ReminderService.plan(DateTime(2027, 5, 31), DateTime(2026, 1, 1));
      expect(plan[2].at, DateTime(2027, 4, 30, 10));
      expect(plan[0].at, DateTime(2026, 11, 30, 10));
    });

    test('nothing to plan for an expired passport', () {
      expect(ReminderService.plan(DateTime(2026, 1, 1), DateTime(2026, 10, 15)), isEmpty);
    });
  });
}
