import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/domain/entities/payment.dart';
import 'package:imuka_kigali/presentation/screens/delivery_handshake_payment/delivery_bloc.dart';

import '../helpers/fake_payment_repository.dart';
import '../helpers/fake_request_repository.dart';

const _clientId = 'client1';
const _driverId = 'driver1';

void main() {
  late FakeRequestRepository requests;
  late FakePaymentRepository payments;
  late DeliveryBloc bloc;

  DeliveryBloc build(String viewerId) =>
      DeliveryBloc(requests, payments, 'r1', viewerId);

  /// Starts the bloc and waits for the first request to arrive.
  Future<void> start() async {
    bloc.add(const DeliveryStarted());
    await bloc.stream.firstWhere((s) => s.status == DeliveryStatus.ready);
  }

  setUp(() {
    requests = FakeRequestRepository(dealRequest());
    payments = FakePaymentRepository();
  });
  tearDown(() => bloc.close());

  group('starting', () {
    test('starts in the loading status', () {
      bloc = build(_clientId);
      expect(bloc.state.status, DeliveryStatus.loading);
    });

    test('a client is recognised as the client', () async {
      bloc = build(_clientId);
      await start();

      expect(bloc.state.isClient, isTrue);
      expect(bloc.state.request!.id, 'r1');
    });

    test('a driver is recognised as the driver', () async {
      bloc = build(_driverId);
      await start();

      expect(bloc.state.isClient, isFalse);
    });

    test('a missing request shows a failure', () async {
      bloc = build(_clientId);
      bloc.add(const DeliveryStarted());
      await bloc.stream.firstWhere((s) => s.status == DeliveryStatus.ready);
      requests.emit(null);

      final failed = await bloc.stream.firstWhere(
        (s) => s.status == DeliveryStatus.failure,
      );
      expect(failed.error, 'Request not found');
    });

    test('an existing payment is loaded when the screen reopens', () async {
      payments.saved = const Payment(
        id: 'r1',
        requestId: 'r1',
        amount: 12500,
        method: PaymentMethods.cash,
        status: PaymentStatus.paid,
      );
      bloc = build(_clientId);
      await start();

      expect(bloc.state.payment!.method, PaymentMethods.cash);
    });
  });

  group('handshake', () {
    test('the client confirming sets only clientConfirmed', () async {
      bloc = build(_clientId);
      await start();

      bloc.add(const DeliveryConfirmed());
      await bloc.stream.firstWhere((s) => s.myConfirmed);

      expect(requests.updates, [
        {Fields.clientConfirmed: true},
      ]);
      expect(bloc.state.otherConfirmed, isFalse);
    });

    test('the driver confirming sets only driverConfirmed', () async {
      bloc = build(_driverId);
      await start();

      bloc.add(const DeliveryConfirmed());
      await bloc.stream.firstWhere((s) => s.myConfirmed);

      expect(requests.updates, [
        {Fields.driverConfirmed: true},
      ]);
    });

    test('a confirmation from the other side shows up live', () async {
      bloc = build(_clientId);
      await start();
      expect(bloc.state.otherConfirmed, isFalse);

      requests.emit(dealRequest(driverConfirmed: true));
      await bloc.stream.firstWhere((s) => s.otherConfirmed);
    });

    test('confirming twice only saves once', () async {
      bloc = build(_clientId);
      await start();

      bloc.add(const DeliveryConfirmed());
      await bloc.stream.firstWhere((s) => s.myConfirmed);
      bloc.add(const DeliveryConfirmed());
      await Future<void>.delayed(Duration.zero);

      expect(requests.updates, hasLength(1));
    });

    test('a failed save shows a readable error', () async {
      bloc = build(_clientId);
      await start();
      requests.failUpdateWith = 'You are not allowed to do that';

      bloc.add(const DeliveryConfirmed());
      final failed = await bloc.stream.firstWhere((s) => s.error != null);

      expect(failed.error, 'You are not allowed to do that');
      expect(failed.myConfirmed, isFalse);
    });

    test('a cancelled request cannot be confirmed', () async {
      requests = FakeRequestRepository(
        dealRequest(status: RequestStatus.cancelled),
      );
      bloc = build(_clientId);
      await start();

      bloc.add(const DeliveryConfirmed());
      final failed = await bloc.stream.firstWhere((s) => s.error != null);

      expect(failed.error, 'This delivery is no longer active');
      expect(requests.updates, isEmpty);
    });
  });

  group('payment', () {
    Future<void> bothConfirmedAndMethodPicked() async {
      requests = FakeRequestRepository(
        dealRequest(clientConfirmed: true, driverConfirmed: true),
      );
      bloc = build(_clientId);
      await start();
      bloc.add(const PaymentMethodSelected(PaymentMethods.mtnMomo));
      await bloc.stream.firstWhere((s) => s.selectedMethod != null);
    }

    test('cannot pay until both sides have confirmed', () async {
      requests = FakeRequestRepository(dealRequest(clientConfirmed: true));
      bloc = build(_clientId);
      await start();
      bloc.add(const PaymentMethodSelected(PaymentMethods.cash));
      await bloc.stream.firstWhere((s) => s.selectedMethod != null);

      expect(bloc.state.canPay, isFalse);
      bloc.add(const PaymentSubmitted());
      await Future<void>.delayed(Duration.zero);
      expect(payments.createCalls, 0);
    });

    test('cannot pay without choosing a method', () async {
      requests = FakeRequestRepository(
        dealRequest(clientConfirmed: true, driverConfirmed: true),
      );
      bloc = build(_clientId);
      await start();

      expect(bloc.state.bothConfirmed, isTrue);
      expect(bloc.state.canPay, isFalse);
    });

    test('a driver can never pay', () async {
      requests = FakeRequestRepository(
        dealRequest(clientConfirmed: true, driverConfirmed: true),
      );
      bloc = build(_driverId);
      await start();
      bloc.add(const PaymentMethodSelected(PaymentMethods.cash));
      await bloc.stream.firstWhere((s) => s.selectedMethod != null);

      expect(bloc.state.canPay, isFalse);
    });

    test('paying saves a paid payment for the fixed price', () async {
      await bothConfirmedAndMethodPicked();
      expect(bloc.state.canPay, isTrue);

      bloc.add(const PaymentSubmitted());
      await bloc.stream.firstWhere((s) => s.isCompleted && !s.paying);

      final saved = payments.saved!;
      expect(saved.requestId, 'r1');
      expect(saved.amount, 12500);
      expect(saved.method, PaymentMethods.mtnMomo);
      expect(saved.status, PaymentStatus.paid);
    });

    test('paying completes the request', () async {
      await bothConfirmedAndMethodPicked();

      bloc.add(const PaymentSubmitted());
      await bloc.stream.firstWhere((s) => s.isCompleted && !s.paying);

      expect(requests.updates.last, {Fields.status: RequestStatus.completed});
      expect(bloc.state.payment, isNotNull);
      expect(bloc.state.canPay, isFalse);
    });

    test('tapping pay twice only charges once', () async {
      await bothConfirmedAndMethodPicked();

      bloc
        ..add(const PaymentSubmitted())
        ..add(const PaymentSubmitted());
      await bloc.stream.firstWhere((s) => s.isCompleted && !s.paying);
      await Future<void>.delayed(Duration.zero);

      expect(payments.createCalls, 1);
    });

    test('a failed payment shows an error and does not complete', () async {
      await bothConfirmedAndMethodPicked();
      payments.failCreateWith = 'Could not save the payment';

      bloc.add(const PaymentSubmitted());
      final failed = await bloc.stream.firstWhere((s) => s.error != null);

      expect(failed.error, 'Could not save the payment');
      expect(failed.paying, isFalse);
      expect(failed.isCompleted, isFalse);
      expect(requests.updates, isEmpty);
    });

    test(
      'a retry after the request failed to complete reuses the payment',
      () async {
        await bothConfirmedAndMethodPicked();
        requests.failUpdateWith = 'No internet connection';

        bloc.add(const PaymentSubmitted());
        await bloc.stream.firstWhere((s) => s.error != null);
        expect(payments.createCalls, 1);

        requests.failUpdateWith = null;
        bloc.add(const PaymentSubmitted());
        await bloc.stream.firstWhere((s) => s.isCompleted && !s.paying);

        expect(payments.createCalls, 1);
        expect(requests.updates.last, {Fields.status: RequestStatus.completed});
      },
    );
  });
}
