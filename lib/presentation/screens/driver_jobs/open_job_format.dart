// Owner: Member 4
String postedAgoLabel(DateTime createdAt, DateTime now) {
  final age = now.difference(createdAt);
  if (age.inMinutes < 1) return 'Posted just now';
  if (age.inHours < 1) return 'Posted ${age.inMinutes} min ago';
  if (age.inDays < 1) return 'Posted ${age.inHours} h ago';
  if (age.inDays == 1) return 'Posted 1 day ago';
  return 'Posted ${age.inDays} days ago';
}
