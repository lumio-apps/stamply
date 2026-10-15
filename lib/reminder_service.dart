import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'app_state.dart';
import 'l10n/l10n.dart';

/// One planned notification.
typedef ReminderSlot = ({int id, int monthsBefore, DateTime at});

/// Passport expiry reminders. Android only: MainActivity.kt sets alarms with
/// the system alarm manager (no extra plugin, no network). Other platforms
/// do nothing.
class ReminderService {
  static const _channel = MethodChannel('lumio/reminders');

  /// Months before the expiry date at which a reminder is shown.
  static const List<int> monthsBefore = [6, 3, 1];

  /// Hour of the day (local time) for the notification.
  static const int hour = 10;

  static bool get supported => Platform.isAndroid;

  /// The reminders that are still in the future on [now].
  static List<ReminderSlot> plan(DateTime expiry, DateTime now) {
    final slots = <ReminderSlot>[];
    for (final (i, m) in monthsBefore.indexed) {
      final firstOfMonth = DateTime(expiry.year, expiry.month - m, 1);
      final lastDay = DateTime(firstOfMonth.year, firstOfMonth.month + 1, 0).day;
      final day = expiry.day > lastDay ? lastDay : expiry.day;
      final at = DateTime(firstOfMonth.year, firstOfMonth.month, day, hour);
      if (at.isAfter(now)) slots.add((id: 100 + i, monthsBefore: m, at: at));
    }
    return slots;
  }

  /// Asks for the notification permission (Android 13+). True when allowed.
  static Future<bool> requestPermission() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('requestPermission') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Replaces all scheduled reminders with the ones for the current settings.
  static Future<void> sync(AppState state) async {
    if (!supported) return;
    final expiry = state.passportExpiry;
    try {
      if (!state.expiryReminder || expiry == null) {
        await _channel.invokeMethod<void>('cancelAll');
        return;
      }
      final language = state.languageCode;
      final l = lookupAppLocalizations(Locale(language));
      final date = DateFormat.yMMMd(language).format(expiry);
      final items = [
        for (final s in plan(expiry, DateTime.now()))
          {
            'id': s.id,
            'at': s.at.millisecondsSinceEpoch,
            'title': l.reminderTitle,
            'body': l.reminderBody(s.monthsBefore, date),
          },
      ];
      await _channel.invokeMethod<void>('schedule', {'items': items});
    } on PlatformException {
      // Reminders are a convenience; never break the app because of them.
    } on MissingPluginException {
      // Not running on Android.
    }
  }

  /// Keeps the reminders in step with the settings. Call once at start-up.
  static void attach(AppState state) {
    String signature() =>
        '${state.expiryReminder}|${state.passportExpiry}|${state.languageCode}';
    var last = '';
    void onChange() {
      final now = signature();
      if (now == last) return;
      last = now;
      sync(state);
    }

    onChange();
    state.addListener(onChange);
  }
}
