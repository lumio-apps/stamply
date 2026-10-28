import 'dart:convert';

import 'package:flutter/services.dart';

/// Reference facts about one country, shown on the result screen.
class CountryFact {
  const CountryFact({
    this.capital,
    this.currencies = const [],
    this.currencyCodes = const [],
    this.callingCode,
    this.languages = const [],
  });

  final String? capital;

  /// For example "Indian Rupee (₹)".
  final List<String> currencies;

  /// For example ["INR"], in the same order as [currencies].
  final List<String> currencyCodes;

  /// For example "+91".
  final String? callingCode;
  final List<String> languages;

  bool get isEmpty =>
      capital == null && currencies.isEmpty && callingCode == null && languages.isEmpty;
}

/// Capital, currency, calling code and languages for every country, read from
/// `assets/data/country_facts.json` (made by `tool/build_facts.py`). Works
/// offline. Names are in English.
class CountryFacts {
  CountryFacts._(this._countries, this._currencies, this._languages);

  final Map<String, Map<String, dynamic>> _countries;
  final Map<String, List<dynamic>> _currencies;
  final Map<String, String> _languages;

  static Future<CountryFacts>? _future;

  /// Loads the file once; later calls reuse the result. Never throws: if the
  /// file cannot be read, every country simply has no facts.
  static Future<CountryFacts> load() => _future ??= _read();

  static Future<CountryFacts> _read() async {
    try {
      return parse(await rootBundle.loadString('assets/data/country_facts.json'));
    } catch (_) {
      return CountryFacts._({}, {}, {});
    }
  }

  static CountryFacts parse(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return CountryFacts._(
      {
        for (final e in (json['countries'] as Map<String, dynamic>).entries)
          e.key: (e.value as Map<String, dynamic>),
      },
      {
        for (final e in (json['currencies'] as Map<String, dynamic>).entries)
          e.key: (e.value as List<dynamic>),
      },
      {
        for (final e in (json['languages'] as Map<String, dynamic>).entries)
          e.key: e.value as String,
      },
    );
  }

  CountryFact? of(String code) {
    final row = _countries[code];
    if (row == null) return null;
    final tel = row['tel'] as String?;
    return CountryFact(
      capital: row['cap'] as String?,
      currencies: [
        for (final c in (row['cur'] as List<dynamic>? ?? const []))
          if (_currencies[c] != null)
            _currencyText(_currencies[c]![0] as String, _currencies[c]![1] as String),
      ],
      currencyCodes: [
        for (final c in (row['cur'] as List<dynamic>? ?? const []))
          if (_currencies[c] != null) c as String,
      ],
      callingCode: tel == null ? null : _callingCode(tel),
      languages: [
        for (final l in (row['lang'] as List<dynamic>? ?? const []))
          if (_languages[l] != null) _languages[l]!,
      ],
    );
  }

  static String _currencyText(String name, String symbol) =>
      symbol.isEmpty ? name : '$name ($symbol)';

  /// "91" → "+91"; Caribbean "1876" → "+1 876".
  static String _callingCode(String tel) =>
      tel.length == 4 && tel.startsWith('1') ? '+1 ${tel.substring(1)}' : '+$tel';
}
