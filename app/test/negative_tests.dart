import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/utils/validators.dart';

void main() {
  group('Negative Tests', () {
    test('Expense with sum mismatch should fail validation', () {
      final result = Validators.validateExpense(
        totalAmountMinor: 1000,
        participantAmountsMinor: [500, 400], // Sum = 900
      );
      expect(result.isValid, false);
      expect(result.errorMessage, contains('must equal the total amount'));
    });

    test('Transfer to self should fail validation', () {
      final result = Validators.validateTransfer(
        fromMemberId: 'm1',
        toMemberId: 'm1',
        amountMinor: 500,
      );
      expect(result.isValid, false);
      expect(result.errorMessage, contains('same person'));
    });

    test('Transfer with zero amount should fail', () {
      final result = Validators.validateTransfer(
        fromMemberId: 'm1',
        toMemberId: 'm2',
        amountMinor: 0,
      );
      expect(result.isValid, false);
      expect(result.errorMessage, contains('greater than zero'));
    });

    test('Expense with zero participants should fail', () {
      final result = Validators.validateExpense(
        totalAmountMinor: 1000,
        participantAmountsMinor: [],
      );
      expect(result.isValid, false);
      expect(result.errorMessage, contains('At least one participant'));
    });
  });
}
