// Owner: Member 5
// Entity for 'ratings': id, requestId, clientId, driverId, stars, comment, createdAt. Has fromMap(id, map) + toMap().
import 'package:equatable/equatable.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/utils/date_parser.dart';

class Rating extends Equatable {
  const Rating({
    required this.id,
    required this.requestId,
    required this.clientId,
    required this.driverId,
    required this.stars,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String requestId;
  final String clientId;
  final String driverId;
  final int stars;
  final String comment;
  final DateTime createdAt;

  factory Rating.fromMap(String id, Map<String, dynamic> map) {
    return Rating(
      id: id,
      requestId: map[Fields.requestId] as String? ?? '',
      clientId: map[Fields.clientId] as String? ?? '',
      driverId: map[Fields.driverId] as String? ?? '',
      stars: (map[Fields.stars] as num?)?.toInt() ?? 0,
      comment: map[Fields.comment] as String? ?? '',
      createdAt: parseDate(map[Fields.createdAt]) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      Fields.requestId: requestId,
      Fields.clientId: clientId,
      Fields.driverId: driverId,
      Fields.stars: stars,
      Fields.comment: comment,
      Fields.createdAt: createdAt,
    };
  }

  @override
  List<Object?> get props => [
    id,
    requestId,
    clientId,
    driverId,
    stars,
    comment,
    createdAt,
  ];
}
