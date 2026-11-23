// Owner: Member 2
// abstract class SettingsRepository: loadSettings, saveThemeMode, saveNotifications, saveDefaultDistrict.
import 'package:flutter/material.dart' show ThemeMode;
import 'package:imuka_kigali/core/constants/kigali_districts.dart';

/// All of the user's saved preferences in one object. They are kept on
/// the phone with SharedPreferences, not in Firestore.
class AppSettings {
  /// Creates the settings. With no arguments these are the defaults used
  /// the first time the app runs.
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.defaultDistrict = KigaliDistricts.gasabo,
  });

  /// Light, dark, or follow the phone's own setting.
  final ThemeMode themeMode;

  /// Whether the user wants alerts about their moves.
  final bool notificationsEnabled;

  /// The user's usual area in Kigali. Always one of [KigaliDistricts.all].
  final String defaultDistrict;
}

/// The list of things the app can do with settings.
/// The SharedPreferences code behind each method is in
/// data/repositories/settings_repository_impl.dart.
abstract class SettingsRepository {
  /// Reads every saved setting. A setting that was never saved comes
  /// back with its default value.
  Future<AppSettings> loadSettings();

  /// Saves the chosen theme mode on the phone.
  Future<void> saveThemeMode(ThemeMode mode);

  /// Saves whether notifications are turned on.
  Future<void> saveNotifications(bool enabled);

  /// Saves the user's default district.
  Future<void> saveDefaultDistrict(String district);
}
