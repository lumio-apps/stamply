import 'dart:convert';

import 'package:flutter/services.dart';

/// Official government websites (immigration or e-visa), one per country.
///
/// The list lives in `assets/data/official_links.json` and holds only links
/// that a person checked by hand. A country without an entry shows nothing.
class OfficialLinks {
  OfficialLinks._(this._links);

  final Map<String, Uri> _links;

  static Future<OfficialLinks>? _future;

  static Future<OfficialLinks> load() => _future ??= _read();

  static Future<OfficialLinks> _read() async {
    try {
      return parse(await rootBundle.loadString('assets/data/official_links.json'));
    } catch (_) {
      return OfficialLinks._({});
    }
  }

  /// Keeps only well-formed `https` links with a host name; anything else is
  /// dropped, so a typo in the file can never open a strange address.
  static OfficialLinks parse(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final links = <String, Uri>{};
    for (final e in (json['links'] as Map<String, dynamic>? ?? const {}).entries) {
      final uri = Uri.tryParse(e.value is String ? e.value as String : '');
      if (uri != null && uri.scheme == 'https' && uri.host.contains('.')) {
        links[e.key] = uri;
      }
    }
    return OfficialLinks._(links);
  }

  Uri? of(String code) => _links[code];
}
