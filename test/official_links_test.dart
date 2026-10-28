import 'package:flutter_test/flutter_test.dart';
import 'package:stamply/official_links.dart';

void main() {
  test('keeps only https links with a host', () {
    final links = OfficialLinks.parse('''
{"links": {
  "AM": "https://www.mfa.am/en/visa",
  "XX": "http://example.com",
  "YY": "javascript:alert(1)",
  "ZZ": "https://localhost",
  "WW": 5
}}''');
    expect(links.of('AM')?.host, 'www.mfa.am');
    expect(links.of('XX'), isNull);
    expect(links.of('YY'), isNull);
    expect(links.of('ZZ'), isNull);
    expect(links.of('WW'), isNull);
    expect(links.of('QQ'), isNull);
  });

  test('an empty list is fine', () {
    expect(OfficialLinks.parse('{"links": {}}').of('AM'), isNull);
    expect(OfficialLinks.parse('{}').of('AM'), isNull);
  });
}
