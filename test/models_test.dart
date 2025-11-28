import 'package:flutter_test/flutter_test.dart';
import 'package:won_club_mobile/models/debt_model.dart';
import 'package:won_club_mobile/models/transaction_model.dart';

void main() {
  group('Models Test', () {
    test('Debt model should be created from json', () {
      final json = {
        'id': '1',
        'amount': 100.0,
        'description': 'Test Debt',
        'status': 'pending',
        'created_at': '2023-10-27T10:00:00Z',
      };

      final debt = Debt.fromJson(json);

      expect(debt.id, '1');
      expect(debt.amount, 100.0);
      expect(debt.description, 'Test Debt');
      expect(debt.status, 'pending');
    });

    test('Transaction model should be created from json', () {
      final json = {
        'id': '2',
        'amount': 50.0,
        'description': 'Test Transaction',
        'date': '2023-10-27T10:00:00Z',
        'type': 'expense',
      };

      final transaction = Transaction.fromJson(json);

      expect(transaction.id, '2');
      expect(transaction.amount, 50.0);
      expect(transaction.description, 'Test Transaction');
      expect(transaction.type, 'expense');
    });
  });
}
