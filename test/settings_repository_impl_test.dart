import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/pref_keys.dart';
import 'package:imuka_kigali/data/repositories/settings_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unit tests for SettingsRepositoryImpl. They check that the settings
/// are saved on the phone and restored after a restart.
/// Run them with: flutter test test/settings_repository_impl_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Every test starts with empty, in-memory phone storage.
    SharedPreferences.setMockInitialValues({});
  });

  test('gives the defaults the first time the app runs', () async {
    final settings = await SettingsRepositoryImpl().loadSettings();

    expect(settings.themeMode, ThemeMode.system);
    expect(settings.notificationsEnabled, isTrue);
    expect(settings.defaultDistrict, 'Gasabo');
  });

  test('settings saved before a restart are restored after it', () async {
    final beforeRestart = SettingsRepositoryImpl();
    await beforeRestart.saveThemeMode(ThemeMode.dark);
    await beforeRestart.saveNotifications(false);
    await beforeRestart.saveDefaultDistrict('Nyarugenge');

    // A new repository behaves like the app after it restarts.
    final settings = await SettingsRepositoryImpl().loadSettings();

    expect(settings.themeMode, ThemeMode.dark);
    expect(settings.notificationsEnabled, isFalse);
    expect(settings.defaultDistrict, 'Nyarugenge');
  });

  test('ignores a saved district that is not in Kigali', () async {
    SharedPreferences.setMockInitialValues({
      PrefKeys.defaultDistrict: 'Musanze',
    });

    final settings = await SettingsRepositoryImpl().loadSettings();

    expect(settings.defaultDistrict, 'Gasabo');
  });
}
