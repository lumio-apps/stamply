import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/l10n.dart';
import 'models.dart';
import 'schengen.dart';
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
  static const _kPassport2 = 'passport2';
  static const _kLanguage = 'language';
  static const _kOnboarded = 'onboarded';
  static const _kTrip = 'trip';
  static const _kStays = 'schengen_stays';
  static const _kReminder = 'expiry_reminder';
  static const _kAutoData = 'auto_data_check';
  static const _kLastData = 'last_data_check';
  static const _maxRecent = 10;

  final SharedPreferences _prefs;

  String? passport;
  String? destination;

  /// Second passport, for people with dual citizenship (optional).
  String? passport2;
  List<TripCheck> recent = [];
  List<TripCheck> saved = [];
  ThemeMode themeMode = ThemeMode.system;

  /// Expiry date of the user's passport (optional).
  DateTime? passportExpiry;

  /// Countries of the multi-country trip being planned (ISO codes, in order).
  List<String> trip = [];

  /// Past and planned stays in the Schengen area, for the 90/180-day calculator.
  List<SchengenStay> stays = [];

  /// Whether to remind the user before the passport expires (Android).
  bool expiryReminder = false;

  /// Whether the app looks for new visa data when it opens (off by default).
  bool autoDataCheck = false;

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
    s.passport2 = prefs.getString(_kPassport2);
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
    s.trip = prefs.getStringList(_kTrip) ?? [];
    s.stays = (prefs.getStringList(_kStays) ?? [])
        .map(SchengenStay.fromKey)
        .whereType<SchengenStay>()
        .toList();
    s.expiryReminder = prefs.getBool(_kReminder) ?? false;
    s.autoDataCheck = prefs.getBool(_kAutoData) ?? false;
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
    if (!known(passport2)) setPassport2(null);
    bool valid(TripCheck t) =>
        data.countries.containsKey(t.passport) && data.countries.containsKey(t.destination);
    trip = trip.where(data.countries.containsKey).toList();
    recent = recent.where(valid).toList();
    saved = saved.where(valid).toList();
    seen = {
      for (final e in seen.entries)
        if (saved.any((t) => t.key == e.key)) e.key: e.value,
    };
  }

  void setPassport(String? code) {
    if (code != null && code == passport2) {
      passport2 = null;
      _prefs.remove(_kPassport2);
    }
    passport = code;
    code == null ? _prefs.remove(_kPassport) : _prefs.setString(_kPassport, code);
    notifyListeners();
  }

  void setPassport2(String? code) {
    if (code != null && code == passport) return;
    passport2 = code;
    code == null ? _prefs.remove(_kPassport2) : _prefs.setString(_kPassport2, code);
    notifyListeners();
  }

  /// Makes the second passport the main one (and the other way round).
  void swapPassports() {
    final a = passport;
    final b = passport2;
    if (a == null || b == null) return;
    passport = b;
    passport2 = a;
    _prefs.setString(_kPassport, b);
    _prefs.setString(_kPassport2, a);
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

  bool inTrip(String code) => trip.contains(code);

  void addToTrip(String code) {
    if (trip.contains(code)) return;
    trip = [...trip, code];
    _prefs.setStringList(_kTrip, trip);
    notifyListeners();
  }

  void removeFromTrip(String code) {
    trip = trip.where((c) => c != code).toList();
    _prefs.setStringList(_kTrip, trip);
    notifyListeners();
  }

  void clearTrip() {
    trip = [];
    _prefs.remove(_kTrip);
    notifyListeners();
  }

  void addStay(SchengenStay stay) {
    if (stays.contains(stay)) return;
    stays = [...stays, stay]..sort((a, b) => a.start.compareTo(b.start));
    _saveStays();
    notifyListeners();
  }

  void removeStay(SchengenStay stay) {
    stays = stays.where((s) => s != stay).toList();
    _saveStays();
    notifyListeners();
  }

  void _saveStays() => _prefs.setStringList(_kStays, stays.map((s) => s.key).toList());

  void setAutoDataCheck(bool on) {
    autoDataCheck = on;
    _prefs.setBool(_kAutoData, on);
    notifyListeners();
  }

  /// True when the automatic check is on and none ran in the last 20 hours.
  bool get autoDataCheckDue {
    if (!autoDataCheck) return false;
    final last = _prefs.getInt(_kLastData);
    if (last == null) return true;
    final age = DateTime.now().millisecondsSinceEpoch - last;
    return age < 0 || age > const Duration(hours: 20).inMilliseconds;
  }

  void markDataChecked() =>
      _prefs.setInt(_kLastData, DateTime.now().millisecondsSinceEpoch);

  void setExpiryReminder(bool on) {
    expiryReminder = on;
    _prefs.setBool(_kReminder, on);
    notifyListeners();
  }

  /// Everything the user saved, as one text (JSON) they can keep or move
  /// to another phone. Language and onboarding are not part of it.
  String exportBackup() => const JsonEncoder.withIndent('  ').convert({
        'app': 'stamply',
        'schema': 1,
        if (passport != null) 'passport': passport,
        if (passport2 != null) 'passport2': passport2,
        if (passportExpiry != null) 'passport_expiry': _kExpiryText(passportExpiry!),
        'saved': saved.map((t) => t.key).toList(),
        'recent': recent.map((t) => t.key).toList(),
        'seen': seen.entries.map((e) => '${e.key}|${e.value}').toList(),
        'trip': trip,
        'stays': stays.map((s) => s.key).toList(),
        'theme': themeMode.name,
      });

  static String _kExpiryText(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Replaces the saved data with a backup made by [exportBackup].
  /// Returns false (and changes nothing) if the text is not a valid backup.
  bool importBackup(String text) {
    final Object? json;
    try {
      json = jsonDecode(text.trim());
    } on FormatException {
      return false;
    }
    if (json is! Map<String, dynamic> || json['app'] != 'stamply' || json['schema'] != 1) {
      return false;
    }
    final code = RegExp(r'^[A-Z]{2}$');
    String? country(Object? v) => v is String && code.hasMatch(v) ? v : null;
    List<String> strings(Object? v) => v is List ? v.whereType<String>().toList() : <String>[];

    final newSaved = strings(json['saved']).map(TripCheck.fromKey).whereType<TripCheck>().toList();
    final newRecent = strings(json['recent'])
        .map(TripCheck.fromKey)
        .whereType<TripCheck>()
        .take(_maxRecent)
        .toList();
    final newStays = strings(json['stays']).map(SchengenStay.fromKey).whereType<SchengenStay>().toList();
    final newTrip = strings(json['trip']).where(code.hasMatch).toList();
    final newSeen = <String, String>{};
    for (final line in strings(json['seen'])) {
      final i = line.lastIndexOf('|');
      if (i > 0 && i < line.length - 1) newSeen[line.substring(0, i)] = line.substring(i + 1);
    }
    final expiryText = json['passport_expiry'];
    final newExpiry = expiryText is String ? DateTime.tryParse(expiryText) : null;

    passport = country(json['passport']);
    passport2 = country(json['passport2']);
    if (passport == null || passport2 == passport) passport2 = null;
    passportExpiry = passport == null ? null : newExpiry;
    saved = newSaved;
    recent = newRecent;
    seen = {
      for (final e in newSeen.entries)
        if (newSaved.any((t) => t.key == e.key)) e.key: e.value,
    };
    trip = newTrip;
    stays = newStays;
    themeMode = switch (json['theme']) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    if (passport != null) onboarded = true;

    void put(String key, String? v) => v == null ? _prefs.remove(key) : _prefs.setString(key, v);
    put(_kPassport, passport);
    put(_kPassport2, passport2);
    put(_kExpiry, passportExpiry == null ? null : _kExpiryText(passportExpiry!));
    _prefs.setStringList(_kSaved, saved.map((t) => t.key).toList());
    _prefs.setStringList(_kRecent, recent.map((t) => t.key).toList());
    _saveSeen();
    _prefs.setStringList(_kTrip, trip);
    _saveStays();
    _prefs.setString(_kTheme, themeMode.name);
    if (passport != null) _prefs.setBool(_kOnboarded, true);
    notifyListeners();
    return true;
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
