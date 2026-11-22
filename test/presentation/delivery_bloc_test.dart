import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/domain/entities/payment.dart';
import 'package:imuka_kigali/domain/repositories/payment_repository.dart';
import 'package:imuka_kigali/domain/repositories/request_repository.dart';
import 'package:imuka_kigali/presentation/screens/delivery_handshake_payment/delivery_bloc.dart';

const _clientId = 'client1';
const _driverId = 'driver1';

MoveRequest _request({
  String status = RequestStatus.accepted,
  bool clientConfirmed = false,
  bool driverConfirmed = false,
}) => MoveRequest(
  id: 'r1',
  clientId: _clientId,
  driverId: _driverId,
  pickupLocation: 'Kimironko',
  dropoffLocation: 'Nyamirambo',
  itemDescription: 'Sofa',
  vehicleType: 'pickup',
  estimatedMinutes: 40,
  proposedAmount: 12500,
  status: status,
  clientConfirmed: clientConfirmed,
  driverConfirmed: driverConfirmed,
  createdAt: DateTime(2026),
);

/// In-memory RequestRepository. Updating a request pushes the new version to
/// the live stream, like Firestore does.
class FakeRequestRepository implements RequestRepository {
  FakeRequestRepository(this.current);

  MoveRequest current;
  String? failUpdateWith;
  final _listeners = <StreamController<MoveRequest?>>[];
  final updates = <Map<String, dynamic>>[];

  void emit(MoveRequest? request) {
    for (final listener in _listeners) {
      listener.add(request);
    }
  }

  // Like Firestore's snapshots(): the current request first, then every change.
  @override
  Stream<MoveRequest?> watchRequest(String requestId) {
    late final StreamController<MoveRequest?> controller;
    controller = StreamController<MoveRequest?>(
      onListen: () {
        _listeners.add(controller);
        controller.add(current);
      },
      onCancel: () => _listeners.remove(controller),
    );
    return controller.stream;
  }

  @override
  Future<void> updateRequest(
    String requestId,
    Map<String, dynamic> fields,
  ) async {
    if (failUpdateWith != null) throw Exception(failUpdateWith);
    updates.add(fields);
    current = MoveRequest(
      id: current.id,
      clientId: current.clientId,
      driverId: current.driverId,
      pickupLocation: current.pickupLocation,
      dropoffLocation: current.dropoffLocation,
      itemDescription: current.itemDescription,
      vehicleType: current.vehicleType,
      estimatedMinutes: current.estimatedMinutes,
      proposedAmount: current.proposedAmount,
      status: fields[Fields.status] as String? ?? current.status,
      clientConfirmed:
          fields[Fields.clientConfirmed] as bool? ?? current.clientConfirmed,
      driverConfirmed:
          fields[Fields.driverConfirmed] as bool? ?? current.driverConfirmed,
      createdAt: current.createdAt,
    );
    emit(current);
  }

  @override
  Future<String> createRequest(MoveRequest request) =>
      throw UnimplementedError();

  @override
  Stream<List<MoveRequest>> watchMyRequests(String clientId) =>
      throw UnimplementedError();

  @override
  Future<MoveRequest?> getRequest(String requestId) =>
      throw UnimplementedError();

  @override
  Future<void> cancelRequest(String requestId) => throw UnimplementedError();
}

/// In-memory PaymentRepository so the bloc can be tested without Firebase.
class FakePaymentRepository implements PaymentRepository {
  Payment? saved;
  String? failCreateWith;
  int createCalls = 0;

  @override
  Future<String> createPayment(Payment payment) async {
    createCalls++;
    if (failCreateWith != null) throw Exception(failCreateWith);
    saved = payment;
    return payment.requestId;
  }

  @override
  Future<Payment?> getPaymentForRequest(String requestId) async => saved;

  @override
  Future<void> updatePayment(Payment payment) async => saved = payment;
}

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
    requests = FakeRequestRepository(_request());
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

      requests.emit(_request(driverConfirmed: true));
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
        _request(status: RequestStatus.cancelled),
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
        _request(clientConfirmed: true, driverConfirmed: true),
      );
      bloc = build(_clientId);
      await start();
      bloc.add(const PaymentMethodSelected(PaymentMethods.mtnMomo));
      await bloc.stream.firstWhere((s) => s.selectedMethod != null);
    }

    test('cannot pay until both sides have confirmed', () async {
      requests = FakeRequestRepository(_request(clientConfirmed: true));
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
        _request(clientConfirmed: true, driverConfirmed: true),
      );
      bloc = build(_clientId);
      await start();

      expect(bloc.state.bothConfirmed, isTrue);
      expect(bloc.state.canPay, isFalse);
    });

    test('a driver can never pay', () async {
      requests = FakeRequestRepository(
        _request(clientConfirmed: true, driverConfirmed: true),
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
