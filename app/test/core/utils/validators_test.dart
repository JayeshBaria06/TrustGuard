import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/models/group.dart';
import 'package:trustguard/src/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('validateExpense', () {
      test('valid expense returns success', () {
        final result = Validators.validateExpense(
          totalAmountMinor: 1000,
          participantAmountsMinor: [500, 500],
        );
        expect(result.isValid, isTrue);
      });

      test('negative total amount returns failure', () {
        final result = Validators.validateExpense(
          totalAmountMinor: -100,
          participantAmountsMinor: [],
        );
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('greater than zero'));
      });

      test('empty participants returns failure', () {
        final result = Validators.validateExpense(
          totalAmountMinor: 1000,
          participantAmountsMinor: [],
        );
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('At least one participant'));
      });

      test('mismatched sum returns failure', () {
        final result = Validators.validateExpense(
          totalAmountMinor: 1000,
          participantAmountsMinor: [500, 400],
        );
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('must equal the total amount'));
      });
    });

    group('validateTransfer', () {
      test('valid transfer returns success', () {
        final result = Validators.validateTransfer(
          fromMemberId: 'm1',
          toMemberId: 'm2',
          amountMinor: 500,
        );
        expect(result.isValid, isTrue);
      });

      test('transfer to self returns failure', () {
        final result = Validators.validateTransfer(
          fromMemberId: 'm1',
          toMemberId: 'm1',
          amountMinor: 500,
        );
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('same person'));
      });

      test('zero amount returns failure', () {
        final result = Validators.validateTransfer(
          fromMemberId: 'm1',
          toMemberId: 'm2',
          amountMinor: 0,
        );
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('greater than zero'));
      });
    });

    group('validateGroup', () {
      test('valid group returns success', () {
        final group = Group(
          id: 'g1',
          name: 'Vacation',
          currencyCode: 'USD',
          createdAt: DateTime.now(),
        );
        final result = Validators.validateGroup(group);
        expect(result.isValid, isTrue);
      });

      test('empty name returns failure', () {
        final group = Group(
          id: 'g1',
          name: '  ',
          currencyCode: 'USD',
          createdAt: DateTime.now(),
        );
        final result = Validators.validateGroup(group);
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('cannot be empty'));
      });

      test('invalid currency code returns failure', () {
        final group = Group(
          id: 'g1',
          name: 'Vacation',
          currencyCode: 'US',
          createdAt: DateTime.now(),
        );
        final result = Validators.validateGroup(group);
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('Invalid currency code'));
      });
    });
  });
}
