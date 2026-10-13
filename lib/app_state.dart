import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _maxRecent = 10;

  final SharedPreferences _prefs;

  String? passport;
  String? destination;
  List<TripCheck> recent = [];
  List<TripCheck> saved = [];
  ThemeMode themeMode = ThemeMode.system;

  static Future<AppState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = AppState._(prefs);
    s.passport = prefs.getString(_kPassport);
    s.destination = prefs.getString(_kDestination);
    s.recent = _readChecks(prefs, _kRecent);
    s.saved = _readChecks(prefs, _kSaved);
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

  void toggleSaved(TripCheck check) {
    saved = isSaved(check) ? saved.where((t) => t != check).toList() : [check, ...saved];
    _prefs.setStringList(_kSaved, saved.map((t) => t.key).toList());
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

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!;
  }
}
