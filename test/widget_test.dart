import 'package:flutter_test/flutter_test.dart';
import 'package:stamply/models.dart';

void main() {
  test('status codes map to entry statuses', () {
    expect(EntryStatus.fromCode('vf'), EntryStatus.visaFree);
    expect(EntryStatus.fromCode('na'), EntryStatus.noAdmission);
    expect(EntryStatus.fromCode('zz'), isNull);
  });

  test('trip check key round trip', () {
    const check = TripCheck('IN', 'TH');
    expect(TripCheck.fromKey(check.key), check);
    expect(TripCheck.fromKey('bad'), isNull);
  });
}