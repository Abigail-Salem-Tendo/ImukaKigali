// Owner: Member 1
// Entity for 'users': uid, role, fullName, phone, email, district, createdAt. Has fromMap(id, map) + toMap().
import 'package:equatable/equatable.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/utils/date_parser.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.role,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.district,
    required this.createdAt,
  });

  /// Document ID = Firebase Auth uid.
  final String uid;
  final String role; // UserRoles.client or UserRoles.driver
  final String fullName;
  final String phone;
  final String email;
  final String district;
  final DateTime createdAt;

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      uid: id,
      role: map[Fields.role] as String? ?? UserRoles.client,
      fullName: map[Fields.fullName] as String? ?? '',
      phone: map[Fields.phone] as String? ?? '',
      email: map[Fields.email] as String? ?? '',
      district: map[Fields.district] as String? ?? '',
      createdAt: parseDate(map[Fields.createdAt]) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      Fields.role: role,
      Fields.fullName: fullName,
      Fields.phone: phone,
      Fields.email: email,
      Fields.district: district,
      Fields.createdAt: createdAt,
    };
  }

  @override
  List<Object?> get props => [
    uid,
    role,
    fullName,
    phone,
    email,
    district,
    createdAt,
  ];
}
