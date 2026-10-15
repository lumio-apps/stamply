/// Schengen 90/180-day rule, worked out on the device with no network.
///
/// In any 180-day period a visitor may stay 90 days in the Schengen area.
/// The entry day and the exit day both count as full days.
library;

/// ISO codes of the countries in the Schengen area.
const Set<String> kSchengenCountries = {
  'AT', 'BE', 'BG', 'HR', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE', 'GR', 'HU',
  'IS', 'IT', 'LV', 'LI', 'LT', 'LU', 'MT', 'NL', 'NO', 'PL', 'PT', 'RO',
  'SK', 'SI', 'ES', 'SE', 'CH', //
};

const int kSchengenLimit = 90;
const int kSchengenWindow = 180;

/// One stay in the Schengen area, first and last day included.
class SchengenStay {
  SchengenStay(DateTime start, DateTime end)
      : start = _dateOnly(start.isAfter(end) ? end : start),
        end = _dateOnly(start.isAfter(end) ? start : end);

  final DateTime start;
  final DateTime end;

  /// Number of days, both ends included.
  int get days => dayNumber(end) - dayNumber(start) + 1;

  /// Saved form, e.g. `2026-03-01|2026-03-20`.
  String get key => '${formatDay(start)}|${formatDay(end)}';

  static SchengenStay? fromKey(String key) {
    final parts = key.split('|');
    if (parts.length != 2) return null;
    final a = DateTime.tryParse(parts[0]);
    final b = DateTime.tryParse(parts[1]);
    if (a == null || b == null) return null;
    return SchengenStay(a, b);
  }

  @override
  bool operator ==(Object other) => other is SchengenStay && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Whole days since 1970-01-01 for the calendar date (time of day and
/// daylight saving do not matter).
int dayNumber(DateTime d) => DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

DateTime dayFromNumber(int n) {
  final u = DateTime.fromMillisecondsSinceEpoch(n * 86400000, isUtc: true);
  return DateTime(u.year, u.month, u.day);
}

String formatDay(DateTime d) {
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-$mm-$dd';
}

class SchengenCalculator {
  SchengenCalculator(Iterable<SchengenStay> stays) : _days = _toDays(stays);

  final Set<int> _days;

  static Set<int> _toDays(Iterable<SchengenStay> stays) {
    final days = <int>{};
    for (final s in stays) {
      final from = dayNumber(s.start);
      final to = dayNumber(s.end);
      for (var d = from; d <= to; d++) {
        days.add(d);
      }
    }
    return days;
  }

  int _usedOn(int day, Set<int> days) {
    var used = 0;
    for (var d = day - kSchengenWindow + 1; d <= day; d++) {
      if (days.contains(d)) used++;
    }
    return used;
  }

  /// Days spent in the 180 days that end on [date] (that day included).
  int usedOn(DateTime date) => _usedOn(dayNumber(date), _days);

  /// Days left on [date]; negative when the limit is passed.
  int remainingOn(DateTime date) => kSchengenLimit - usedOn(date);

  /// First day after [date] with at least one day available, when no more
  /// stays are added. Null when [date] itself still has days left.
  DateTime? nextFreeDay(DateTime date) {
    final start = dayNumber(date);
    if (_usedOn(start, _days) < kSchengenLimit) return null;
    for (var d = start + 1; d <= start + kSchengenWindow; d++) {
      if (_usedOn(d, _days) < kSchengenLimit) return dayFromNumber(d);
    }
    return null;
  }

  /// Longest stay (in days, at most 90) that can begin on [entry] without
  /// going over the limit on any day.
  int maxStayFrom(DateTime entry) {
    final first = dayNumber(entry);
    final days = {..._days};
    var stay = 0;
    for (var d = first; stay < kSchengenLimit; d++) {
      days.add(d);
      if (_usedOn(d, days) > kSchengenLimit) break;
      stay++;
    }
    return stay;
  }
}
