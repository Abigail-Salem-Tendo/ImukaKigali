import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/domain/entities/payment.dart';

/// Unit tests for the Payment entity: what goes into Firestore and what
/// comes back out must match the ERD.
void main() {
  final paidAt = DateTime(2026, 11, 20, 14, 30);

  test('toMap uses the field names from the ERD and no id', () {
    final payment = Payment(
      id: 'r1',
      requestId: 'r1',
      amount: 12500,
      method: PaymentMethods.mtnMomo,
      status: PaymentStatus.paid,
      paidAt: paidAt,
    );

    expect(payment.toMap(), {
      Fields.requestId: 'r1',
      Fields.amount: 12500.0,
      Fields.method: 'mtn_momo',
      Fields.status: 'paid',
      Fields.paidAt: paidAt,
    });
  });

  test('fromMap turns a Firestore map back into the same payment', () {
    final payment = Payment.fromMap('r1', {
      Fields.requestId: 'r1',
      Fields.amount: 12500, // Firestore may give an int for a whole number
      Fields.method: 'cash',
      Fields.status: 'paid',
      Fields.paidAt: paidAt,
    });

    expect(payment.id, 'r1');
    expect(payment.amount, 12500.0);
    expect(payment.method, PaymentMethods.cash);
    expect(payment.paidAt, paidAt);
  });

  test('a payment with missing fields is pending and has no paidAt', () {
    final payment = Payment.fromMap('r2', {Fields.requestId: 'r2'});

    expect(payment.status, PaymentStatus.pending);
    expect(payment.paidAt, isNull);
    expect(payment.amount, 0);
  });

  test('every payment method has a readable label', () {
    for (final method in PaymentMethods.all) {
      expect(PaymentMethods.label(method), isNot(method));
    }
  });
}
