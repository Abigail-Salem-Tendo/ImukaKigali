// SharedPreferences keys: themeMode, notificationsEnabled, defaultDistrict.
/// Keys for SharedPreferences do not type them elsewhere
class PrefKeys {
  PrefKeys._();

  static const String themeMode = 'themeMode'; // 'system' | 'light' | 'dark'
  static const String notificationsEnabled = 'notificationsEnabled'; // bool
  static const String defaultDistrict = 'defaultDistrict'; // String
}