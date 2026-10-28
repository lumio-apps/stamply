import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Exchange rates for one day, all measured against 1 US dollar.
///
/// Rates are downloaded only when the user taps the button. The last download
/// is kept on the phone so it can be shown offline, with its date.
/// Source: fawazahmed0/exchange-api (CC0, no key, no account).
class ExchangeRates {
  const ExchangeRates(this.perUsd, this.date);

  /// Upper-case currency code → how many of it equal 1 USD.
  final Map<String, double> perUsd;

  /// Day the rates are for, as given by the source (yyyy-mm-dd).
  final String date;

  static const _kCache = 'fx_rates';
  static const urls = [
    'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.min.json',
    'https://latest.currency-api.pages.dev/v1/currencies/usd.min.json',
  ];

  /// Reads the source format `{"date": "...", "usd": {"amd": 387.1, ...}}`.
  /// Returns null if it holds no usable rate.
  static ExchangeRates? parse(String text) {
    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      final table = json['usd'] as Map<String, dynamic>?;
      if (table == null) return null;
      final rates = <String, double>{};
      for (final e in table.entries) {
        final v = e.value;
        if (v is num && v.isFinite && v > 0) rates[e.key.toUpperCase()] = v.toDouble();
      }
      if (rates.isEmpty) return null;
      return ExchangeRates(rates, (json['date'] as String?) ?? '');
    } catch (_) {
      return null;
    }
  }

  /// How many [to] equal 1 [from], or null when either is unknown.
  double? rate(String from, String to) {
    final a = from == 'USD' ? 1.0 : perUsd[from];
    final b = to == 'USD' ? 1.0 : perUsd[to];
    if (a == null || b == null) return null;
    return b / a;
  }

  /// The rates saved by the last download, or null if there are none.
  static Future<ExchangeRates?> cached() async {
    try {
      final text = (await SharedPreferences.getInstance()).getString(_kCache);
      return text == null ? null : parse(text);
    } catch (_) {
      return null;
    }
  }

  /// Downloads the latest rates and saves them. Null if the phone is offline
  /// or the source is down; the old saved rates stay.
  static Future<ExchangeRates?> fetch() async {
    for (final url in urls) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
        if (res.statusCode != 200) continue;
        final text = utf8.decode(res.bodyBytes);
        final rates = parse(text);
        if (rates == null) continue;
        await (await SharedPreferences.getInstance()).setString(_kCache, text);
        return rates;
      } catch (e) {
        debugPrint('Rate download failed: $e');
      }
    }
    return null;
  }
}
