// Owner: Member 2
// Events for settings_bloc.dart. First line will be: part of 'settings_bloc.dart';
part of 'settings_bloc.dart';

/// The parent of every event that can change the settings.
sealed class SettingsEvent extends Equatable {
  /// Lets every event be created as a constant.
  const SettingsEvent();

  /// The values Equatable compares. Events with no data have none.
  @override
  List<Object?> get props => [];
}

/// Sent once when the app starts, to read the saved settings.
class SettingsLoaded extends SettingsEvent {
  /// Creates the event. It carries no data.
  const SettingsLoaded();
}

/// Sent when the user picks System, Light or Dark.
class ThemeModeChanged extends SettingsEvent {
  /// Creates the event for the chosen theme mode.
  const ThemeModeChanged(this.themeMode);

  final ThemeMode themeMode;

  /// Two of these events are equal when the theme mode matches.
  @override
  List<Object?> get props => [themeMode];
}

/// Sent when the user flips the notifications switch.
class NotificationsToggled extends SettingsEvent {
  /// Creates the event with the switch's new position.
  const NotificationsToggled(this.enabled);

  final bool enabled;

  /// Two of these events are equal when the switch position matches.
  @override
  List<Object?> get props => [enabled];
}

/// Sent when the user picks a different default district.
class DefaultDistrictChanged extends SettingsEvent {
  /// Creates the event for the chosen district.
  const DefaultDistrictChanged(this.district);

  final String district;

  /// Two of these events are equal when the district matches.
  @override
  List<Object?> get props => [district];
}
