// Owner: Member 4
// Shared widget: the driver bottom navigation from the Figma (Home, Jobs,
// Job Logs, Profile).
//
//   Scaffold(
//     bottomNavigationBar: const DriverBottomNav(current: DriverTab.jobs),
//   )
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_routes.dart';

// The order here is the order of the tabs on screen.
enum DriverTab { home, jobs, jobLogs, profile }

class DriverBottomNav extends StatelessWidget {
  const DriverBottomNav({super.key, required this.current});

  final DriverTab current;

  static const _routes = {
    DriverTab.home: AppRoutes.driverHome,
    DriverTab.jobs: AppRoutes.driverJobs,
    DriverTab.jobLogs: AppRoutes.jobLogs,
    DriverTab.profile: AppRoutes.driverProfile,
  };

  void _openTab(BuildContext context, int index) {
    final tab = DriverTab.values[index];
    if (tab == current) {
      return;
    }
    // The profile screen has no bottom navigation yet, so it is pushed:
    // with go there would be no way back from it.
    if (tab == DriverTab.profile) {
      context.push(_routes[tab]!);
      return;
    }
    // go, not push: the tabs replace each other, so Back never walks
    // through every tab the driver has visited.
    context.go(_routes[tab]!);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    return Semantics(
      container: true,
      label: 'Driver navigation',
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: colors.surface,
          // The Figma marks the current tab by colour only, with no pill.
          indicatorColor: colors.surface,
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? colors.primary
                  : colors.onSurfaceVariant,
            ),
          ),
          // The theme's primary blue is under 4.5:1 on white, so the
          // selected label uses the main text colour and bold instead.
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? labelStyle?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  )
                : labelStyle?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
        child: NavigationBar(
          selectedIndex: current.index,
          onDestinationSelected: (index) => _openTab(context, index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined),
              selectedIcon: Icon(Icons.local_shipping),
              label: 'Jobs',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Job Logs',
            ),
            NavigationDestination(
              icon: Icon(Icons.badge_outlined),
              selectedIcon: Icon(Icons.badge),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
