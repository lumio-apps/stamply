import 'package:flutter/material.dart';

/// Entry requirement for one passport travelling to one destination.
enum EntryStatus {
  visaFree('vf'),
  visaOnArrival('voa'),
  eta('eta'),
  eVisa('ev'),
  visaRequired('vr'),
  noAdmission('na');

  const EntryStatus(this.code);

  /// Short code used in visa_data.json.
  final String code;

  static EntryStatus? fromCode(String code) {
    for (final s in values) {
      if (s.code == code) return s;
    }
    return null;
  }

  IconData get icon => switch (this) {
        EntryStatus.visaFree => Icons.check_circle_outline,
        EntryStatus.visaOnArrival => Icons.flight_land,
        EntryStatus.eta => Icons.verified_user_outlined,
        EntryStatus.eVisa => Icons.language,
        EntryStatus.visaRequired => Icons.assignment_outlined,
        EntryStatus.noAdmission => Icons.block,
      };

  /// Text color for pills and the stamp.
  Color foreground(Brightness b) {
    final dark = b == Brightness.dark;
    return switch (this) {
      EntryStatus.visaFree => dark ? const Color(0xFF7FD3A6) : const Color(0xFF1E6B45),
      EntryStatus.visaOnArrival => dark ? const Color(0xFFF2C76B) : const Color(0xFF7A4F00),
      EntryStatus.eta => dark ? const Color(0xFF7DD3DC) : const Color(0xFF0F5F69),
      EntryStatus.eVisa => dark ? const Color(0xFF9CBCF0) : const Color(0xFF1F4E96),
      EntryStatus.visaRequired => dark ? const Color(0xFFF29A8F) : const Color(0xFFA1281C),
      EntryStatus.noAdmission => dark ? const Color(0xFFD0D0D0) : const Color(0xFF3A3A3A),
    };
  }

  /// Soft background for pills.
  Color background(Brightness b) {
    final dark = b == Brightness.dark;
    return switch (this) {
      EntryStatus.visaFree => dark ? const Color(0xFF173D2C) : const Color(0xFFDCEFE3),
      EntryStatus.visaOnArrival => dark ? const Color(0xFF3D2F12) : const Color(0xFFF7E9C8),
      EntryStatus.eta => dark ? const Color(0xFF12393E) : const Color(0xFFD4EEF0),
      EntryStatus.eVisa => dark ? const Color(0xFF1A2D4F) : const Color(0xFFDCE6F5),
      EntryStatus.visaRequired => dark ? const Color(0xFF4A1D18) : const Color(0xFFF6DAD6),
      EntryStatus.noAdmission => dark ? const Color(0xFF333333) : const Color(0xFFE2E2E2),
    };
  }

  /// Stamp color on the dark hero card (needs to be light).
  Color get onHero => foreground(Brightness.dark);
}

/// One rule: the status plus the allowed stay in days, when known.
class VisaRule {
  const VisaRule(this.status, [this.days]);

  final EntryStatus status;
  final int? days;
}

/// A passport → destination pair the user has looked up.
class TripCheck {
  const TripCheck(this.passport, this.destination);

  final String passport;
  final String destination;

  String get key => '$passport>$destination';

  static TripCheck? fromKey(String key) {
    final parts = key.split('>');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) return null;
    return TripCheck(parts[0], parts[1]);
  }

  @override
  bool operator ==(Object other) =>
      other is TripCheck && other.passport == passport && other.destination == destination;

  @override
  int get hashCode => Object.hash(passport, destination);
}
