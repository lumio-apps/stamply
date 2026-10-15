import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter/services.dart';

import 'app_state.dart';
import 'l10n/l10n.dart';
import 'visa_repository.dart';
import 'widgets.dart' show flagEmoji;

/// Android only: the home-screen widget and the long-press app shortcuts.
/// Both are plain code in MainActivity.kt (no extra plugin). Other platforms
/// do nothing.
class PlatformIntegration {
  static const _channel = MethodChannel('lumio/integration');

  static bool get supported => Platform.isAndroid;

  /// Shortcut ids, also sent back by the system when one is tapped.
  static const shortcutCheck = 'check';
  static const shortcutExplore = 'explore';
  static const shortcutMap = 'map';
  static const shortcutSchengen = 'schengen';

  /// The shortcut the app was opened with, once (null if none).
  static Future<String?> consumeShortcut() async {
    if (!supported) return null;
    try {
      return await _channel.invokeMethod<String>('consumeShortcut');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Keeps the widget and the shortcuts in step with the app. Call once.
  static void attach(AppState state, VisaRepository repo) {
    if (!supported) return;
    var last = '';
    void onChange() {
      final now = '${state.passport}|${state.languageCode}|${repo.data.version}';
      if (now == last) return;
      last = now;
      _push(state, repo);
    }

    onChange();
    state.addListener(onChange);
    repo.addListener(onChange);
  }

  static Future<void> _push(AppState state, VisaRepository repo) async {
    final lang = state.languageCode;
    final l = lookupAppLocalizations(Locale(lang));
    final data = repo.data;
    final passport = state.passport;
    try {
      await _channel.invokeMethod<void>('updateWidget', {
        'title': passport == null
            ? l.choosePassport
            : '${flagEmoji(passport)} ${repo.nameOf(passport, lang)}',
        'line1': passport == null ? '' : l.destinationsNoVisa(data.score(passport)),
        'line2': passport == null ? '' : l.rankOf(data.rank(passport), data.rankedCount),
      });
      await _channel.invokeMethod<void>('setShortcuts', {
        'items': [
          {'action': shortcutCheck, 'label': l.navCheck},
          {'action': shortcutExplore, 'label': l.navExplore},
          {'action': shortcutMap, 'label': l.mapTitle},
          {'action': shortcutSchengen, 'label': l.schengenShort},
        ],
      });
    } on PlatformException {
      // A widget or shortcut that does not update must never break the app.
    } on MissingPluginException {
      // Not running on Android.
    }
  }
}
