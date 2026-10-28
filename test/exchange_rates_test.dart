import 'package:flutter_test/flutter_test.dart';
import 'package:stamply/exchange_rates.dart';

void main() {
  const sample = '{"date":"2026-10-27","usd":{"amd":387.5,"inr":84.0,"eur":0.92,"bad":-1,"text":"x"}}';

  test('reads the source format and drops unusable values', () {
    final r = ExchangeRates.parse(sample)!;
    expect(r.date, '2026-10-27');
    expect(r.perUsd.keys.toSet(), {'AMD', 'INR', 'EUR'});
  });

  test('converts through the dollar', () {
    final r = ExchangeRates.parse(sample)!;
    expect(r.rate('USD', 'AMD'), 387.5);
    expect(r.rate('INR', 'AMD')!, closeTo(387.5 / 84.0, 1e-9));
    expect(r.rate('AMD', 'USD')!, closeTo(1 / 387.5, 1e-9));
    expect(r.rate('USD', 'XXX'), isNull);
  });

  test('rejects broken or empty input', () {
    expect(ExchangeRates.parse('not json'), isNull);
    expect(ExchangeRates.parse('{"date":"x"}'), isNull);
    expect(ExchangeRates.parse('{"usd":{}}'), isNull);
  });
}
