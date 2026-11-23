// Owner: Member 4
import 'package:flutter/material.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/presentation/screens/job_logs/job_logs_bloc.dart';

class JobLogsPeriodTabs extends StatelessWidget {
  const JobLogsPeriodTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final JobLogsPeriod selected;
  final ValueChanged<JobLogsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SegmentedButton<JobLogsPeriod>(
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      style: SegmentedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSpacing.xxl),
        selectedBackgroundColor: scheme.primary,
        selectedForegroundColor: scheme.onPrimary,
      ),
      segments: const [
        ButtonSegment(value: JobLogsPeriod.allTrips, label: Text('All Trips')),
        ButtonSegment(value: JobLogsPeriod.thisWeek, label: Text('This Week')),
        ButtonSegment(
          value: JobLogsPeriod.thisMonth,
          label: Text('This Month'),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (periods) => onChanged(periods.first),
    );
  }
}
