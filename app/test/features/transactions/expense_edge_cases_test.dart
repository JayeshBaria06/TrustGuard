import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/utils/money.dart';

void main() {
  group('Expense Edge Cases', () {
    test('1 cent split among 3 people', () {
      final result = MoneyUtils.splitEqual(1, 3);
      expect(result, [1, 0, 0]);
      expect(result.reduce((a, b) => a + b), 1);
    });

    test('Large amount (max int32 cents) split', () {
      const int maxInt32 = 2147483647;
      final result = MoneyUtils.splitEqual(maxInt32, 2);
      expect(result, [1073741824, 1073741823]);
      expect(result.reduce((a, b) => a + b), maxInt32);
    });

    test('Large total split among many people', () {
      const int total = 1000000000; // 10 million
      const int count = 100;
      final result = MoneyUtils.splitEqual(total, count);
      expect(result.length, 100);
      expect(result.every((v) => v == 10000000), true);
      expect(result.reduce((a, b) => a + b), total);
    });
  });
}
