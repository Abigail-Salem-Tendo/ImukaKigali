import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/domain/repositories/settings_repository.dart';
import 'package:imuka_kigali/presentation/screens/settings/settings_bloc.dart';

/// A pretend repository that keeps the settings in memory.
/// Set [failOnSave] to true to make every save throw an error.
class FakeSettingsRepository implements SettingsRepository {
  AppSettings saved = const AppSettings();
  bool failOnSave = false;

  /// Returns the settings this fake currently holds.
  @override
  Future<AppSettings> loadSettings() async => saved;

  /// Stores the theme mode, or throws when [failOnSave] is true.
  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    if (failOnSave) {
      throw Exception('storage error');
    }
    saved = AppSettings(
      themeMode: mode,
      notificationsEnabled: saved.notificationsEnabled,
      defaultDistrict: saved.defaultDistrict,
    );
  }

  /// Stores the notifications switch, or throws when [failOnSave] is true.
  @override
  Future<void> saveNotifications(bool enabled) async {
    if (failOnSave) {
      throw Exception('storage error');
    }
    saved = AppSettings(
      themeMode: saved.themeMode,
      notificationsEnabled: enabled,
      defaultDistrict: saved.defaultDistrict,
    );
  }

  /// Stores the district, or throws when [failOnSave] is true.
  @override
  Future<void> saveDefaultDistrict(String district) async {
    if (failOnSave) {
      throw Exception('storage error');
    }
    saved = AppSettings(
      themeMode: saved.themeMode,
      notificationsEnabled: saved.notificationsEnabled,
      defaultDistrict: district,
    );
  }
}

/// Unit tests for SettingsBloc, using the fake repository above.
/// Run them with: flutter test test/settings_bloc_test.dart
void main() {
  late FakeSettingsRepository repo;
  late SettingsBloc bloc;

  setUp(() {
    repo = FakeSettingsRepository();
    bloc = SettingsBloc(repo);
  });

  tearDown(() => bloc.close());

  test('loads the saved settings when the app starts', () async {
    repo.saved = const AppSettings(
      themeMode: ThemeMode.dark,
      notificationsEnabled: false,
      defaultDistrict: 'Kicukiro',
    );

    final states = expectLater(
      bloc.stream,
      emitsInOrder(const [
        SettingsState(status: SettingsStatus.loading),
        SettingsState(
          status: SettingsStatus.success,
          themeMode: ThemeMode.dark,
          notificationsEnabled: false,
          defaultDistrict: 'Kicukiro',
        ),
      ]),
    );
    bloc.add(const SettingsLoaded());
    await states;
  });

  test('switches to dark mode and saves it', () async {
    final states = expectLater(
      bloc.stream,
      emits(
        const SettingsState(
          status: SettingsStatus.success,
          themeMode: ThemeMode.dark,
        ),
      ),
    );
    bloc.add(const ThemeModeChanged(ThemeMode.dark));
    await states;
    await pumpEventQueue();

    expect(repo.saved.themeMode, ThemeMode.dark);
  });

  test(
    'puts the old theme back and reports an error if saving fails',
    () async {
      repo.failOnSave = true;

      final states = expectLater(
        bloc.stream,
        emitsInOrder(const [
          SettingsState(
            status: SettingsStatus.success,
            themeMode: ThemeMode.dark,
          ),
          SettingsState(
            status: SettingsStatus.failure,
            themeMode: ThemeMode.system,
            error: 'Could not save the theme. Please try again.',
          ),
        ]),
      );
      bloc.add(const ThemeModeChanged(ThemeMode.dark));
      await states;
    },
  );

  test('turns notifications off and saves it', () async {
    final states = expectLater(
      bloc.stream,
      emits(
        const SettingsState(
          status: SettingsStatus.success,
          notificationsEnabled: false,
        ),
      ),
    );
    bloc.add(const NotificationsToggled(false));
    await states;
    await pumpEventQueue();

    expect(repo.saved.notificationsEnabled, isFalse);
  });
}
