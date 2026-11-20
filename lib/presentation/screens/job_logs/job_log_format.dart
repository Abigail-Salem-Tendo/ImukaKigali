// Owner: Member 4
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatRwf(double amount) {
  final digits = amount.round().toString();
  final withCommas = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final digitsLeft = digits.length - i;
    if (i > 0 && digitsLeft % 3 == 0) withCommas.write(',');
    withCommas.write(digits[i]);
  }
  return '$withCommas RWF';
}

String dispatchNumber(String requestId) {
  final shortId = requestId.length < 4 ? requestId : requestId.substring(0, 4);
  return '#IMK-${shortId.toUpperCase()}';
}

String jobTimeLabel(DateTime createdAt, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(createdAt.year, createdAt.month, createdAt.day);
  // Rwanda has no daylight saving, so two midnights are always whole days apart.
  final daysAgo = today.difference(day).inDays;
  if (daysAgo <= 0) return 'Today, ${_clockTime(createdAt)}';
  if (daysAgo == 1) return 'Yesterday, ${_clockTime(createdAt)}';
  if (daysAgo < 7) return '$daysAgo days ago';
  if (daysAgo < 14) return 'Last week';
  return '${day.day} ${_months[day.month - 1]} ${day.year}';
}

String _clockTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final amPm = time.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $amPm';
}
