import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/data/repositories/payment_repository_impl.dart';
import 'package:imuka_kigali/domain/entities/payment.dart';

import '../helpers/fake_firestore.dart';

/// Unit tests for PaymentRepositoryImpl, using an in-memory Firestore.
/// Run them with: flutter test test/data/payment_repository_impl_test.dart
void main() {
  late FakeFirestore db;
  late PaymentRepositoryImpl repo;

  const paid = Payment(
    id: '',
    requestId: 'r1',
    amount: 12500,
    method: PaymentMethods.mtnMomo,
    status: PaymentStatus.paid,
  );

  setUp(() {
    db = FakeFirestore();
    repo = PaymentRepositoryImpl(db: db);
  });

  group('createPayment', () {
    test(
      'saves the payment in "payments" with the request id as its id',
      () async {
        final id = await repo.createPayment(paid);

        expect(id, 'r1');
        final saved = db.read(Collections.payments, 'r1')!;
        expect(saved[Fields.requestId], 'r1');
        expect(saved[Fields.amount], 12500.0);
        expect(saved[Fields.method], 'mtn_momo');
        expect(saved[Fields.status], 'paid');
      },
    );

    test('a paid payment gets the server time as paidAt', () async {
      await repo.createPayment(paid);

      final saved = db.read(Collections.payments, 'r1')!;
      expect(saved[Fields.paidAt], isA<FieldValue>());
    });

    test('a pending payment has no paidAt', () async {
      await repo.createPayment(
        const Payment(
          id: '',
          requestId: 'r2',
          amount: 8000,
          method: PaymentMethods.cash,
          status: PaymentStatus.pending,
        ),
      );

      expect(db.read(Collections.payments, 'r2')![Fields.paidAt], isNull);
    });

    test('paying the same request twice is refused', () async {
      await repo.createPayment(paid);

      await expectLater(
        repo.createPayment(paid),
        throwsA(
          predicate(
            (e) => e.toString().contains('This request has already been paid'),
          ),
        ),
      );
      expect(db.store[Collections.payments], hasLength(1));
    });

    test('a Firestore error becomes a readable Exception', () async {
      db.failWith = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'You are not allowed to pay this request',
      );

      await expectLater(
        repo.createPayment(paid),
        throwsA(
          predicate(
            (e) =>
                e.toString() ==
                'Exception: You are not allowed to pay this request',
          ),
        ),
      );
    });
  });

  group('getPaymentForRequest', () {
    test('returns null when the request has no payment yet', () async {
      expect(await repo.getPaymentForRequest('r1'), isNull);
    });

    test('returns the payment saved for that request', () async {
      await repo.createPayment(paid);

      final payment = await repo.getPaymentForRequest('r1');

      expect(payment!.id, 'r1');
      expect(payment.requestId, 'r1');
      expect(payment.amount, 12500);
      expect(payment.method, PaymentMethods.mtnMomo);
      expect(payment.status, PaymentStatus.paid);
    });

    test('a Firestore error becomes a readable Exception', () async {
      db.failWith = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'No internet connection',
      );

      await expectLater(
        repo.getPaymentForRequest('r1'),
        throwsA(
          predicate((e) => e.toString() == 'Exception: No internet connection'),
        ),
      );
    });
  });

  group('updatePayment', () {
    test('changes the method but never the request it belongs to', () async {
      await repo.createPayment(paid);

      await repo.updatePayment(
        const Payment(
          id: 'r1',
          requestId: 'someone-elses-request',
          amount: 12500,
          method: PaymentMethods.cash,
          status: PaymentStatus.paid,
        ),
      );

      final saved = db.read(Collections.payments, 'r1')!;
      expect(saved[Fields.method], 'cash');
      expect(saved[Fields.requestId], 'r1');
    });

    test('updating a payment that does not exist says so', () async {
      await expectLater(
        repo.updatePayment(paid.copyWithId('missing')),
        throwsA(
          predicate(
            (e) => e.toString() == 'Exception: This payment does not exist',
          ),
        ),
      );
    });
  });
}

extension on Payment {
  Payment copyWithId(String newId) => Payment(
    id: newId,
    requestId: requestId,
    amount: amount,
    method: method,
    status: status,
    paidAt: paidAt,
  );
}
