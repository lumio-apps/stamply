import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/l10n.dart';
import 'models.dart';
import 'visa_repository.dart';

/// User choices saved on the device only: passport, last destination,
/// recent and saved checks, and the theme.
class AppState extends ChangeNotifier {
  AppState._(this._prefs);

  static const _kPassport = 'passport';
  static const _kDestination = 'destination';
  static const _kRecent = 'recent';
  static const _kSaved = 'saved';
  static const _kTheme = 'theme';
  static const _kExpiry = 'passport_expiry';
  static const _kSeen = 'seen_rules';
  static const _kLanguage = 'language';
  static const _kOnboarded = 'onboarded';
  static const _maxRecent = 10;

  final SharedPreferences _prefs;

  String? passport;
  String? destination;
  List<TripCheck> recent = [];
  List<TripCheck> saved = [];
  ThemeMode themeMode = ThemeMode.system;

  /// Expiry date of the user's passport (optional).
  DateTime? passportExpiry;

  /// Saved trip key → the rule the user last saw, to spot changes after data updates.
  Map<String, String> seen = {};

  /// Language chosen by the user, or null (= follow the device).
  String? get languageSetting => _prefs.getString(_kLanguage);

  /// Language the app is shown in: the user's choice, else the device
  /// language if the app has it, else English.
  String get languageCode {
    final chosen = languageSetting;
    if (chosen != null && kLanguages.any((l) => l.code == chosen)) return chosen;
    return deviceLanguageCode;
  }

  static String get deviceLanguageCode {
    final device = PlatformDispatcher.instance.locale.languageCode;
    return kLanguages.any((l) => l.code == device) ? device : 'en';
  }

  void setLanguage(String code) {
    _prefs.setString(_kLanguage, code);
    notifyListeners();
  }

  /// False until the welcome screen is finished. People who used an earlier
  /// version (they already picked a passport) skip it.
  bool onboarded = true;

  void completeOnboarding() {
    onboarded = true;
    _prefs.setBool(_kOnboarded, true);
    notifyListeners();
  }

  static Future<AppState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = AppState._(prefs);
    s.passport = prefs.getString(_kPassport);
    s.destination = prefs.getString(_kDestination);
    s.onboarded = prefs.getBool(_kOnboarded) ?? (s.passport != null);
    s.recent = _readChecks(prefs, _kRecent);
    s.saved = _readChecks(prefs, _kSaved);
    s.passportExpiry = DateTime.tryParse(prefs.getString(_kExpiry) ?? '');
    final seen = <String, String>{};
    for (final line in prefs.getStringList(_kSeen) ?? const <String>[]) {
      final i = line.lastIndexOf('|');
      if (i > 0 && i < line.length - 1) seen[line.substring(0, i)] = line.substring(i + 1);
    }
    s.seen = seen;
    s.themeMode = switch (prefs.getString(_kTheme)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return s;
  }

  static List<TripCheck> _readChecks(SharedPreferences prefs, String key) =>
      (prefs.getStringList(key) ?? []).map(TripCheck.fromKey).whereType<TripCheck>().toList();

  /// Drops codes that are not in the current data (e.g. after a data update).
  void cleanUp(VisaData data) {
    bool known(String? c) => c == null || data.countries.containsKey(c);
    if (!known(passport)) setPassport(null);
    if (!known(destination)) setDestination(null);
    bool valid(TripCheck t) =>
        data.countries.containsKey(t.passport) && data.countries.containsKey(t.destination);
    recent = recent.where(valid).toList();
    saved = saved.where(valid).toList();
    seen = {
      for (final e in seen.entries)
        if (saved.any((t) => t.key == e.key)) e.key: e.value,
    };
  }

  void setPassport(String? code) {
    passport = code;
    code == null ? _prefs.remove(_kPassport) : _prefs.setString(_kPassport, code);
    notifyListeners();
  }

  void setDestination(String? code) {
    destination = code;
    code == null ? _prefs.remove(_kDestination) : _prefs.setString(_kDestination, code);
    notifyListeners();
  }

  void swap() {
    final p = passport;
    setPassport(destination);
    setDestination(p);
  }

  void addRecent(TripCheck check) {
    recent = [check, ...recent.where((t) => t != check)].take(_maxRecent).toList();
    _prefs.setStringList(_kRecent, recent.map((t) => t.key).toList());
    notifyListeners();
  }

  void clearRecent() {
    recent = [];
    _prefs.remove(_kRecent);
    notifyListeners();
  }

  bool isSaved(TripCheck check) => saved.contains(check);

  /// Saves or un-saves a trip. [signature] is the rule shown right now.
  void toggleSaved(TripCheck check, {String? signature}) {
    if (isSaved(check)) {
      saved = saved.where((t) => t != check).toList();
      seen = {
        for (final e in seen.entries)
          if (e.key != check.key) e.key: e.value,
      };
    } else {
      saved = [check, ...saved];
      if (signature != null) seen = {...seen, check.key: signature};
    }
    _prefs.setStringList(_kSaved, saved.map((t) => t.key).toList());
    _saveSeen();
    notifyListeners();
  }

  /// Remembers the rule the user is looking at, so "Changed" only shows for new changes.
  void markSeen(TripCheck check, String? signature) {
    if (!isSaved(check) || signature == null || seen[check.key] == signature) return;
    seen = {...seen, check.key: signature};
    _saveSeen();
    notifyListeners();
  }

  bool hasChanged(TripCheck check, String? currentSignature) {
    final old = seen[check.key];
    return old != null && currentSignature != null && old != currentSignature;
  }

  void _saveSeen() {
    _prefs.setStringList(_kSeen, seen.entries.map((e) => '${e.key}|${e.value}').toList());
  }

  void setPassportExpiry(DateTime? date) {
    if (date == null) {
      passportExpiry = null;
      _prefs.remove(_kExpiry);
    } else {
      final d = DateTime(date.year, date.month, date.day);
      passportExpiry = d;
      final mm = d.month.toString().padLeft(2, '0');
      final dd = d.day.toString().padLeft(2, '0');
      _prefs.setString(_kExpiry, '${d.year.toString().padLeft(4, '0')}-$mm-$dd');
    }
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    _prefs.setString(_kTheme, mode.name);
    notifyListeners();
  }
}

/// Gives every screen access to the app state and the visa data, and
/// rebuilds the screens that use it whenever either one changes.
class AppScope extends InheritedNotifier<Listenable> {
  AppScope({super.key, required this.state, required this.repo, required super.child})
      : super(notifier: Listenable.merge([state, repo]));

  final AppState state;
  final VisaRepository repo;

  /// Country name in the app's language.
  String nameOf(String code) => repo.nameOf(code, state.languageCode);

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!;
  }
}
