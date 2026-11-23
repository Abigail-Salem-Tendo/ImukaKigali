import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/presentation/screens/job_logs/job_log_format.dart';

void main() {
  group('formatRwf', () {
    test('adds commas every three digits', () {
      expect(formatRwf(24000), '24,000 RWF');
      expect(formatRwf(1840000), '1,840,000 RWF');
    });

    test('leaves small amounts without commas', () {
      expect(formatRwf(500), '500 RWF');
      expect(formatRwf(0), '0 RWF');
    });

    test('rounds to the nearest franc', () {
      expect(formatRwf(999.6), '1,000 RWF');
    });
  });

  group('dispatchNumber', () {
    test('uses the first four characters of the id in upper case', () {
      expect(dispatchNumber('k3pa9xQ'), '#IMK-K3PA');
    });

    test('works with an id shorter than four characters', () {
      expect(dispatchNumber('ab'), '#IMK-AB');
    });
  });

  group('jobTimeLabel', () {
    final now = DateTime(2026, 11, 18, 14);

    test('shows the time for today and yesterday', () {
      expect(
        jobTimeLabel(DateTime(2026, 11, 18, 11, 30), now),
        'Today, 11:30 AM',
      );
      expect(
        jobTimeLabel(DateTime(2026, 11, 17, 15, 15), now),
        'Yesterday, 3:15 PM',
      );
    });

    test('shows midnight and noon as 12', () {
      expect(
        jobTimeLabel(DateTime(2026, 11, 18, 0, 5), now),
        'Today, 12:05 AM',
      );
      expect(jobTimeLabel(DateTime(2026, 11, 18, 12), now), 'Today, 12:00 PM');
    });

    test('counts calendar days, not 24 hour blocks', () {
      expect(
        jobTimeLabel(DateTime(2026, 11, 17, 23, 59), now),
        startsWith('Yesterday'),
      );
    });

    test('shows days ago, last week, then the date', () {
      expect(jobTimeLabel(DateTime(2026, 11, 15), now), '3 days ago');
      expect(jobTimeLabel(DateTime(2026, 11, 9), now), 'Last week');
      expect(jobTimeLabel(DateTime(2026, 10, 19), now), '19 Oct 2026');
    });
  });
}
