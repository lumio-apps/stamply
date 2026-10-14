import 'models.dart';

/// Whole calendar months from [from] to [to] (day of month counts).
int monthsUntil(DateTime from, DateTime to) {
  var months = (to.year - from.year) * 12 + (to.month - from.month);
  if (to.day < from.day) months -= 1;
  return months;
}

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "14 Oct 2026"
String formatDate(DateTime d) => '${d.day} ${_monthNames[d.month - 1]} ${d.year}';

enum ValidityLevel { expired, critical, short, good }

/// How long the user's passport is still valid, judged against the common
/// "6 months of validity" rule. Individual countries can differ.
class PassportValidity {
  const PassportValidity._(this.level, this.months, this.days);

  final ValidityLevel level;

  /// Whole months left (0 when expired).
  final int months;

  /// Days left; negative when expired.
  final int days;

  factory PassportValidity.check(DateTime expiry, DateTime now) {
    // UTC dates, so daylight saving never shifts the day count.
    final today = DateTime.utc(now.year, now.month, now.day);
    final end = DateTime.utc(expiry.year, expiry.month, expiry.day);
    final days = end.difference(today).inDays;
    if (days < 0) return PassportValidity._(ValidityLevel.expired, 0, days);
    final months = monthsUntil(today, end);
    final level = months >= 6
        ? ValidityLevel.good
        : months >= 3
            ? ValidityLevel.short
            : ValidityLevel.critical;
    return PassportValidity._(level, months, days);
  }

  String get summary {
    if (level == ValidityLevel.expired) {
      final ago = -days;
      return ago == 1 ? 'Expired yesterday' : 'Expired $ago days ago';
    }
    if (months >= 1) return months == 1 ? '1 month left' : '$months months left';
    if (days == 0) return 'Expires today';
    return days == 1 ? '1 day left' : '$days days left';
  }

  String get advice => switch (level) {
        ValidityLevel.expired => 'Your passport has expired. Renew it before you travel.',
        ValidityLevel.critical =>
          'Less than 3 months left. Many countries will refuse entry. Consider renewing first.',
        ValidityLevel.short =>
          'Less than 6 months left. Many countries require at least 6 months of validity.',
        ValidityLevel.good =>
          'Meets the common 6-month rule. Still confirm the rule for your destination.',
      };

  /// Reuses the status colors: green, amber or red.
  EntryStatus get tone => switch (level) {
        ValidityLevel.good => EntryStatus.visaFree,
        ValidityLevel.short => EntryStatus.visaOnArrival,
        ValidityLevel.critical || ValidityLevel.expired => EntryStatus.visaRequired,
      };
}
