import 'package:imuka_kigali/domain/entities/payment.dart';
import 'package:imuka_kigali/domain/repositories/payment_repository.dart';

/// In-memory PaymentRepository so blocs and screens can be tested without
/// Firebase.
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
