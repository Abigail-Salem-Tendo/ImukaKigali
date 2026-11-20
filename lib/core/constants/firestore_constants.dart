/// Every Firestore string lives here. Never type a collection, field or status name anywhere else. These match the ERD exactly.
/// The document ID is the primary key, so it is not a field.
class Collections {
  Collections._();

  static const String users = 'users';
  static const String vehicles = 'vehicles';
  static const String requests = 'requests';
  static const String payments = 'payments';
  static const String ratings = 'ratings';
}

class Fields {
  Fields._();

  // users
  static const String role = 'role';
  static const String fullName = 'fullName';
  static const String phone = 'phone';
  static const String email = 'email';
  static const String district = 'district';
  static const String createdAt = 'createdAt';

  // vehicles
  static const String driverId = 'driverId';
  static const String vehicleType = 'vehicleType';
  static const String plateNumber = 'plateNumber';
  static const String capacityKg = 'capacityKg';

  // requests
  static const String clientId = 'clientId';
  static const String pickupLocation = 'pickupLocation';
  static const String dropoffLocation = 'dropoffLocation';
  static const String itemDescription = 'itemDescription';
  static const String estimatedMinutes = 'estimatedMinutes';
  static const String proposedAmount = 'proposedAmount';
  static const String status = 'status';
  static const String clientConfirmed = 'clientConfirmed';
  static const String driverConfirmed = 'driverConfirmed';

  // payments
  static const String requestId = 'requestId';
  static const String amount = 'amount';
  static const String method = 'method';
  static const String paidAt = 'paidAt';

  // ratings
  static const String stars = 'stars';
  static const String comment = 'comment';
}

class UserRoles {
  UserRoles._();

  static const String client = 'client';
  static const String driver = 'driver';
}

class RequestStatus {
  RequestStatus._();

  static const String open = 'open'; // looking for a driver
  static const String accepted = 'accepted';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
}

class PaymentStatus {
  PaymentStatus._();

  static const String pending = 'pending';
  static const String paid = 'paid';
}
