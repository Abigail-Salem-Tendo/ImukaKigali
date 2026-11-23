// Owner: Member 5
// Entity for 'payments': id, requestId, amount, method, status, paidAt. Has fromMap(id, map) + toMap().
import 'package:equatable/equatable.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/utils/date_parser.dart';

class Payment extends Equatable {
  const Payment({
    required this.id,
    required this.requestId,
    required this.amount,
    required this.method,
    required this.status,
    this.paidAt,
  });

  final String id;
  final String requestId;
  final double amount;
  final String method;
  final String status; // PaymentStatus.pending or PaymentStatus.paid

  /// Null until the payment is marked paid.
  final DateTime? paidAt;

  factory Payment.fromMap(String id, Map<String, dynamic> map) {
    return Payment(
      id: id,
      requestId: map[Fields.requestId] as String? ?? '',
      amount: (map[Fields.amount] as num?)?.toDouble() ?? 0,
      method: map[Fields.method] as String? ?? '',
      status: map[Fields.status] as String? ?? PaymentStatus.pending,
      paidAt: parseDate(map[Fields.paidAt]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      Fields.requestId: requestId,
      Fields.amount: amount,
      Fields.method: method,
      Fields.status: status,
      Fields.paidAt: paidAt,
    };
  }

  @override
  List<Object?> get props => [id, requestId, amount, method, status, paidAt];
}

/// The ways a client can pay. The payment is simulated, so choosing one
/// only saves its name in `payments.method`.
class PaymentMethods {
  PaymentMethods._();

  static const String mtnMomo = 'mtn_momo';
  static const String airtelMoney = 'airtel_money';
  static const String cash = 'cash';

  static const List<String> all = [mtnMomo, airtelMoney, cash];

  /// The name shown to the user, for example "MTN MoMo".
  static String label(String method) => switch (method) {
    mtnMomo => 'MTN MoMo',
    airtelMoney => 'Airtel Money',
    cash => 'Cash',
    _ => method,
  };
}
