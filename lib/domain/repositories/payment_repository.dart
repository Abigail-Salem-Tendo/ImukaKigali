// Owner: Member 5
// What the app can do with the 'payments' collection.
// No Firebase here: blocs depend on this, not on the Firebase code.
import 'package:imuka_kigali/domain/entities/payment.dart';

abstract class PaymentRepository {
  /// Saves the payment of one request and returns its id.
  /// A request has only one payment (the id is the request id), so saving it
  /// a second time throws an Exception instead of charging twice.
  Future<String> createPayment(Payment payment);

  /// The payment of one request, read once. Returns null if there is none yet.
  Future<Payment?> getPaymentForRequest(String requestId);

  /// Saves the changed [payment] over the one already in Firestore.
  /// Throws an Exception with a readable message if it does not exist.
  Future<void> updatePayment(Payment payment);
}
