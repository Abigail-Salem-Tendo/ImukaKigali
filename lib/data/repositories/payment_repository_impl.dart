// Owner: Member 5
// PaymentRepositoryImpl implements PaymentRepository using the 'payments' collection.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/domain/entities/payment.dart';
import 'package:imuka_kigali/domain/repositories/payment_repository.dart';

/// The Firestore code for payments. Only this layer imports Firebase.
class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _payments =>
      _db.collection(Collections.payments);

  // The document id is the request id, and the check runs in a transaction,
  // so one request can never get two payments, even if pay is tapped twice.
  @override
  Future<String> createPayment(Payment payment) async {
    final ref = _payments.doc(payment.requestId);
    try {
      await _db.runTransaction((transaction) async {
        final existing = await transaction.get(ref);
        if (existing.exists) {
          throw Exception('This request has already been paid');
        }
        transaction.set(ref, _toData(payment));
      });
      return ref.id;
    } on FirebaseException catch (e) {
      throw Exception(e.message ?? 'Could not save the payment');
    }
  }

  @override
  Future<Payment?> getPaymentForRequest(String requestId) async {
    try {
      final doc = await _payments.doc(requestId).get();
      final data = doc.data();
      return data == null ? null : Payment.fromMap(doc.id, data);
    } on FirebaseException catch (e) {
      throw Exception(e.message ?? 'Could not load the payment');
    }
  }

  @override
  Future<void> updatePayment(Payment payment) async {
    final ref = _payments.doc(payment.id);
    try {
      // The request a payment belongs to never changes.
      final data = _toData(payment)..remove(Fields.requestId);
      await ref.update(data);
    } on FirebaseException catch (e) {
      throw Exception(
        e.code == 'not-found'
            ? 'This payment does not exist'
            : e.message ?? 'Could not update the payment',
      );
    }
  }

  /// The map to save. A paid payment gets the server time as `paidAt`, so a
  /// wrong clock on the phone cannot change it.
  Map<String, dynamic> _toData(Payment payment) {
    final data = payment.toMap();
    if (payment.status == PaymentStatus.paid && payment.paidAt == null) {
      data[Fields.paidAt] = FieldValue.serverTimestamp();
    }
    return data;
  }
}
