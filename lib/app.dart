// Owner: Member 3
// Provides all repositories + the 2 global blocs (AuthBloc, SettingsBloc) and sets up the router.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imuka_kigali/core/router/app_router.dart';
import 'package:imuka_kigali/core/theme/app_theme.dart';
import 'package:imuka_kigali/data/repositories/auth_repository_impl.dart';
import 'package:imuka_kigali/data/repositories/driver_job_repository_impl.dart';
import 'package:imuka_kigali/data/repositories/settings_repository_impl.dart';
import 'package:imuka_kigali/data/repositories/vehicle_repository_impl.dart';
import 'package:imuka_kigali/domain/repositories/auth_repository.dart';
import 'package:imuka_kigali/domain/repositories/driver_job_repository.dart';
import 'package:imuka_kigali/domain/repositories/settings_repository.dart';
import 'package:imuka_kigali/domain/repositories/vehicle_repository.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';
import 'package:imuka_kigali/data/repositories/payment_repository_impl.dart';
import 'package:imuka_kigali/data/repositories/rating_repository_impl.dart';
import 'package:imuka_kigali/data/repositories/request_repository_impl.dart';
import 'package:imuka_kigali/domain/repositories/payment_repository.dart';
import 'package:imuka_kigali/domain/repositories/rating_repository.dart';
import 'package:imuka_kigali/domain/repositories/request_repository.dart';
import 'package:imuka_kigali/presentation/screens/settings/settings_bloc.dart';

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
        RepositoryProvider<PaymentRepository>(
          create: (_) => PaymentRepositoryImpl(),
        ),
        RepositoryProvider<RatingRepository>(
          create: (_) => RatingRepositoryImpl(),
        ),
        RepositoryProvider<RequestRepository>(
          create: (_) => RequestRepositoryImpl(),
        ),
        RepositoryProvider<SettingsRepository>(
          create: (_) => SettingsRepositoryImpl(),
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
          BlocProvider(
            create: (c) =>
                SettingsBloc(c.read<SettingsRepository>())
                  ..add(const SettingsLoaded()),
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
    // Redraws the app in the theme the user picked in Settings.
    final themeMode = context.select(
      (SettingsBloc bloc) => bloc.state.themeMode,
    );

    // The router only checks its redirect when the user navigates. Logging in
    // or out doesn't navigate, so we ask it to check again ourselves.
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status || previous.user != current.user,
      listener: (context, state) => appRouter.refresh(),
      child: MaterialApp.router(
        title: 'Imuka Kigali',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        routerConfig: appRouter,
      ),
    );
  }
}
