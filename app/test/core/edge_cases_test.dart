import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/models/group.dart';
import 'package:trustguard/src/core/utils/validators.dart';

void main() {
  group('Core Data Boundaries', () {
    test('Empty group name validation', () {
      final group = Group(
        id: 'g1',
        name: '',
        currencyCode: 'USD',
        createdAt: DateTime.now(),
      );
      final result = Validators.validateGroup(group);
      expect(result.isValid, false);
      expect(result.errorMessage, contains('cannot be empty'));
    });

    test('Member name with special characters', () {
      // This should be valid
      final result = Validators.validateGroup(
        Group(
          id: 'g1',
          name: 'Vacation! @2026 #FUN',
          currencyCode: 'USD',
          createdAt: DateTime.now(),
        ),
      );
      expect(result.isValid, true);
    });

    test('Valid currency codes', () {
      final validCodes = ['USD', 'EUR', 'GBP', 'JPY', 'INR'];
      for (var code in validCodes) {
        final result = Validators.validateGroup(
          Group(
            id: 'g1',
            name: 'Test',
            currencyCode: code,
            createdAt: DateTime.now(),
          ),
        );
        expect(result.isValid, true, reason: 'Code $code should be valid');
      }
    });

    test('Invalid currency codes', () {
      final invalidCodes = ['', 'U', 'US', 'USDD', '123'];
      for (var code in invalidCodes) {
        final result = Validators.validateGroup(
          Group(
            id: 'g1',
            name: 'Test',
            currencyCode: code,
            createdAt: DateTime.now(),
          ),
        );
        expect(result.isValid, false, reason: 'Code $code should be invalid');
      }
    });
  });
}
