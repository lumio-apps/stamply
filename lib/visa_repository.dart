import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'models.dart';

/// Outcome of tapping "Update data".
enum DataRefreshResult { updated, upToDate, failed }

/// Visa data in memory, parsed from visa_data.json.
class VisaData {
  VisaData._(this.version, this.source, this.countries, this._rules);

  /// Dataset date, e.g. "2026-02-17". Newer data has a larger string.
  final String version;
  final String source;

  /// ISO-2 code → country name, sorted by name.
  final Map<String, String> countries;
  final Map<String, Map<String, Object>> _rules;

  /// Parses and validates the file. Throws [FormatException] on bad data.
  factory VisaData.parse(String text) {
    final json = jsonDecode(text);
    if (json is! Map<String, dynamic> || json['schema'] != 1) {
      throw const FormatException('Unsupported data format');
    }
    final version = json['version'];
    final countriesJson = json['countries'];
    final rulesJson = json['rules'];
    if (version is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(version) ||
        countriesJson is! Map<String, dynamic> ||
        rulesJson is! Map<String, dynamic> ||
        countriesJson.length < 150) {
      throw const FormatException('Incomplete data');
    }

    final countries = <String, String>{
      for (final e in countriesJson.entries)
        if (e.value is String) e.key: e.value as String,
    };
    final rules = <String, Map<String, Object>>{};
    for (final p in rulesJson.entries) {
      final row = p.value;
      if (row is! Map<String, dynamic>) continue;
      rules[p.key] = {
        for (final d in row.entries)
          if (d.value is int || d.value is String) d.key: d.value as Object,
      };
    }
    return VisaData._(version, json['source'] as String? ?? '', countries, rules);
  }

  String nameOf(String code) => countries[code] ?? code;

  Map<String, int>? _scores;

  /// Passport power: how many destinations a passport reaches without a visa
  /// in advance (visa-free, visa on arrival or ETA).
  Map<String, int> get scores => _scores ??= {
        for (final p in _rules.keys)
          p: _rules[p]!.values.where((v) {
            if (v is int) return true;
            final s = EntryStatus.fromCode(v as String);
            return s == EntryStatus.visaFree ||
                s == EntryStatus.visaOnArrival ||
                s == EntryStatus.eta;
          }).length,
      };

  int score(String passport) => scores[passport] ?? 0;

  /// Position among all passports; equal scores share a rank.
  int rank(String passport) {
    final s = score(passport);
    return 1 + scores.values.where((x) => x > s).length;
  }

  int get rankedCount => scores.length;

  /// All passports, strongest first, with their rank.
  List<({String code, int score, int rank})> ranking() {
    final list = scores.entries.toList()
      ..sort((a, b) {
        final c = b.value.compareTo(a.value);
        return c != 0 ? c : nameOf(a.key).compareTo(nameOf(b.key));
      });
    return [for (final e in list) (code: e.key, score: e.value, rank: rank(e.key))];
  }

  /// Requirement for [passport] holders entering [destination].
  /// Returns null when the pair is unknown or both are the same country.
  VisaRule? rule(String passport, String destination) {
    final value = _rules[passport]?[destination];
    if (value is int) return VisaRule(EntryStatus.visaFree, value);
    if (value is String) {
      final status = EntryStatus.fromCode(value);
      if (status != null) return VisaRule(status);
    }
    return null;
  }

  /// Short text that changes whenever the rule for this pair changes.
  String? signature(String passport, String destination) {
    final value = _rules[passport]?[destination];
    return value == null ? null : '$value';
  }

  /// All destinations for one passport, sorted by country name.
  List<MapEntry<String, VisaRule>> destinationsFor(String passport) {
    final list = <MapEntry<String, VisaRule>>[];
    for (final code in countries.keys) {
      final r = rule(passport, code);
      if (r != null) list.add(MapEntry(code, r));
    }
    return list;
  }
}

/// Loads the bundled data (always works offline) and, if the user has
/// downloaded newer data with "Update data", uses that instead.
class VisaRepository extends ChangeNotifier {
  VisaRepository._(this._data, this._bundledVersion, this._names);

  static const _asset = 'assets/data/visa_data.json';
  static const _namesAsset = 'assets/data/country_names.json';
  static const _fileName = 'visa_data.json';

  /// The same file this app ships with, from the main branch on GitHub.
  /// It is a plain static file: no server, no account, no data sent.
  static const remoteUrl =
      'https://raw.githubusercontent.com/lumio-apps/stamply/main/assets/data/visa_data.json';

  VisaData _data;
  final String _bundledVersion;

  /// Country code → language code → name (from Unicode CLDR).
  final Map<String, Map<String, String>> _names;

  VisaData get data => _data;
  bool get usingDownloadedData => _data.version.compareTo(_bundledVersion) > 0;

  static Future<VisaRepository> load() async {
    final bundled = VisaData.parse(await rootBundle.loadString(_asset));
    var data = bundled;
    try {
      final file = await _localFile();
      if (await file.exists()) {
        final downloaded = VisaData.parse(await file.readAsString());
        if (downloaded.version.compareTo(bundled.version) > 0) data = downloaded;
      }
    } catch (e) {
      // A broken download must never stop the app: fall back to bundled data.
      debugPrint('Ignoring downloaded data: $e');
    }
    return VisaRepository._(data, bundled.version, await _loadNames());
  }

  static Future<Map<String, Map<String, String>>> _loadNames() async {
    try {
      final json = jsonDecode(await rootBundle.loadString(_namesAsset));
      return {
        for (final e in (json as Map<String, dynamic>).entries)
          e.key: {
            for (final n in (e.value as Map<String, dynamic>).entries) n.key: n.value as String,
          },
      };
    } catch (e) {
      // Names are a nicety: without them the app shows English names.
      debugPrint('Country names not loaded: $e');
      return {};
    }
  }

  /// Name of a country in [lang]; English (from the visa data) when unknown.
  String nameOf(String code, String lang) => _names[code]?[lang] ?? _data.nameOf(code);

  /// Downloads the latest data file. Only called when the user taps the button.
  Future<DataRefreshResult> refresh() async {
    try {
      final res = await http.get(Uri.parse(remoteUrl)).timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) return DataRefreshResult.failed;
      final text = utf8.decode(res.bodyBytes);
      final fresh = VisaData.parse(text);
      if (fresh.version.compareTo(_data.version) <= 0) return DataRefreshResult.upToDate;

      final file = await _localFile();
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(text, flush: true);
      await tmp.rename(file.path);

      _data = fresh;
      notifyListeners();
      return DataRefreshResult.updated;
    } catch (e) {
      debugPrint('Data refresh failed: $e');
      return DataRefreshResult.failed;
    }
  }

  static Future<File> _localFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }
}
