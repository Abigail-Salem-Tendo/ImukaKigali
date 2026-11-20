// Owner: Member 2
// SettingsRepositoryImpl implements SettingsRepository using shared_preferences.
import 'package:flutter/material.dart' show ThemeMode;
import 'package:imuka_kigali/core/constants/pref_keys.dart';
import 'package:imuka_kigali/domain/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saves the settings on the phone with SharedPreferences, so they are
/// still there after the app is closed and opened again.
class SettingsRepositoryImpl implements SettingsRepository {
  /// Creates the repository. The app passes nothing. A test can pass its
  /// own [prefs] instead.
  SettingsRepositoryImpl({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  /// Opens SharedPreferences the first time it is needed and reuses it
  /// after that.
  Future<SharedPreferences> get _store async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Reads the three settings from the phone. A missing or unknown value
  /// is replaced by its default, so the result is always usable.
  @override
  Future<AppSettings> loadSettings() async {
    final prefs = await _store;
    const defaults = AppSettings();

    // The theme is saved as a word: "system", "light" or "dark".
    final savedTheme = prefs.getString(PrefKeys.themeMode);
    final themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == savedTheme,
      orElse: () => defaults.themeMode,
    );

    final savedDistrict = prefs.getString(PrefKeys.defaultDistrict);
    final district =
        savedDistrict != null && kigaliDistricts.contains(savedDistrict)
        ? savedDistrict
        : defaults.defaultDistrict;

    return AppSettings(
      themeMode: themeMode,
      notificationsEnabled:
          prefs.getBool(PrefKeys.notificationsEnabled) ??
          defaults.notificationsEnabled,
      defaultDistrict: district,
    );
  }

  /// Saves the theme mode as its name, for example "dark".
  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await _store;
    await prefs.setString(PrefKeys.themeMode, mode.name);
  }

  /// Saves the notifications switch as true or false.
  @override
  Future<void> saveNotifications(bool enabled) async {
    final prefs = await _store;
    await prefs.setBool(PrefKeys.notificationsEnabled, enabled);
  }

  /// Saves the name of the default district.
  @override
  Future<void> saveDefaultDistrict(String district) async {
    final prefs = await _store;
    await prefs.setString(PrefKeys.defaultDistrict, district);
  }
}
