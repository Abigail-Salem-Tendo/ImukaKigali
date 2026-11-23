import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/presentation/screens/driver_jobs/open_job_format.dart';

void main() {
  group('postedAgoLabel', () {
    final now = DateTime(2026, 11, 18, 14);

    String postedBefore(Duration age) => postedAgoLabel(now.subtract(age), now);

    test('says just now for the first minute', () {
      expect(postedBefore(const Duration(seconds: 30)), 'Posted just now');
    });

    test('counts minutes, then hours, then days', () {
      expect(postedBefore(const Duration(minutes: 5)), 'Posted 5 min ago');
      expect(postedBefore(const Duration(hours: 2)), 'Posted 2 h ago');
      expect(postedBefore(const Duration(hours: 30)), 'Posted 1 day ago');
      expect(postedBefore(const Duration(days: 3)), 'Posted 3 days ago');
    });
  });
}
