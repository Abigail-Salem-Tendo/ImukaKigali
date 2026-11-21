// Owner: Member 4
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/widgets/widgets.dart';

class NoVehicleView extends StatelessWidget {
  const NoVehicleView({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.local_shipping_outlined,
      title: 'Add your vehicle first',
      message:
          'Add it on your profile. Open jobs for your vehicle type show up '
          'once it is registered.',
      actionLabel: 'Register vehicle',
      // Not /driver-register-1: the auth redirect sends signed-in users away
      // from the sign-up steps, and the profile screen is where a signed-in
      // driver adds a vehicle.
      onAction: () => context.go(AppRoutes.driverProfile),
    );
  }
}
