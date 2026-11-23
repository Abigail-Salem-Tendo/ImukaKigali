// Owner: Member 2
// State for settings_bloc.dart. First line will be: part of 'settings_bloc.dart';
part of 'settings_bloc.dart';

/// Where the settings are: not read yet, loading, ready, or failed.
enum SettingsStatus { initial, loading, success, failure }

/// Everything the settings screen and the app's theme need to know.
class SettingsState extends Equatable {
  /// Creates a state. With no arguments it holds the default settings.
  const SettingsState({
    this.status = SettingsStatus.initial,
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.defaultDistrict = KigaliDistricts.gasabo,
    this.error,
  });

  final SettingsStatus status;
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final String defaultDistrict;

  /// A readable message for a snackbar when something fails.
  final String? error;

  /// Returns a copy of this state with only the given values replaced.
  /// [error] is cleared unless a new one is passed.
  SettingsState copyWith({
    SettingsStatus? status,
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    String? defaultDistrict,
    String? error,
  }) {
    return SettingsState(
      status: status ?? this.status,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      defaultDistrict: defaultDistrict ?? this.defaultDistrict,
      error: error,
    );
  }

  /// The values Equatable compares to decide if the screen must redraw.
  @override
  List<Object?> get props => [
    status,
    themeMode,
    notificationsEnabled,
    defaultDistrict,
    error,
  ];
}
