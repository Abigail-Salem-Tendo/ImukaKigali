// Owner: Member 3
// Provides all repositories + the 2 global blocs (AuthBloc, SettingsBloc) and sets up the router.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imuka_kigali/core/router/app_router.dart';
import 'package:imuka_kigali/core/theme/app_theme.dart';
import 'package:imuka_kigali/data/repositories/auth_repository_impl.dart';
import 'package:imuka_kigali/data/repositories/driver_job_repository_impl.dart';
import 'package:imuka_kigali/data/repositories/vehicle_repository_impl.dart';
import 'package:imuka_kigali/domain/repositories/auth_repository.dart';
import 'package:imuka_kigali/domain/repositories/driver_job_repository.dart';
import 'package:imuka_kigali/domain/repositories/vehicle_repository.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';

/// Root widget. When a repository or the global blocs exist, wrap [AppView]
/// here with MultiRepositoryProvider (one line per repository) and
/// MultiBlocProvider (only AuthBloc and SettingsBloc).
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (_) => AuthRepositoryImpl()),
        RepositoryProvider<DriverJobRepository>(
          create: (_) => DriverJobRepositoryImpl(),
        ),
        RepositoryProvider<VehicleRepository>(
          create: (_) => VehicleRepositoryImpl(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (c) =>
            AuthBloc(c.read<AuthRepository>())
              ..add(const AuthCheckRequested()),
          ),
        ],
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Imuka Kigali',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system, // SettingsBloc will provide this later
      routerConfig: appRouter,
    );
  }
}
