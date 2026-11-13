/// Turns a Firestore date value into a [DateTime] without importing Firebase.
/// Firestore returns a Timestamp (which has toDate()); a DateTime passes through.
/// Writing a DateTime to Firestore stores it as a Timestamp, as in the ERD.
DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  try {
    return (value as dynamic).toDate() as DateTime;
  } catch (_) {
    return null;
  }
}
