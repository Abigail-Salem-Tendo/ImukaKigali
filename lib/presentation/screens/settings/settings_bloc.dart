// Owner: Member 2
// Bloc: GLOBAL SettingsBloc - loads/saves SharedPreferences, controls themeMode (template: ARCHITECTURE.md Part 5)
// Owner: Member 2
// Bloc: GLOBAL SettingsBloc - loads/saves SharedPreferences, controls themeMode (template: ARCHITECTURE.md Part 5)
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imuka_kigali/domain/repositories/settings_repository.dart';

part 'settings_event.dart';
part 'settings_state.dart';

/// The logic of the settings. It is created once for the whole app, so
/// the theme and every screen read the same values.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  /// Creates the bloc with the default settings and links each event to
  /// the method that handles it.
  SettingsBloc(this._repo) : super(const SettingsState()) {
    on<SettingsLoaded>(_onLoaded);
    on<ThemeModeChanged>(_onThemeModeChanged);
    on<NotificationsToggled>(_onNotificationsToggled);
    on<DefaultDistrictChanged>(_onDefaultDistrictChanged);
  }

  final SettingsRepository _repo;

  /// Reads the saved settings from the phone and puts them in the state.
  /// If reading fails, the defaults stay and an error message is set.
  Future<void> _onLoaded(
      SettingsLoaded event,
      Emitter<SettingsState> emit,
      ) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    try {
      final saved = await _repo.loadSettings();
      emit(
        state.copyWith(
          status: SettingsStatus.success,
          themeMode: saved.themeMode,
          notificationsEnabled: saved.notificationsEnabled,
          defaultDistrict: saved.defaultDistrict,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          error: 'We could not load your settings, so the defaults are in use.',
        ),
      );
    }
  }

  /// Shows the new theme at once, then saves it. If saving fails, it
  /// puts the old theme back and sets an error message.
  Future<void> _onThemeModeChanged(
      ThemeModeChanged event,
      Emitter<SettingsState> emit,
      ) async {
    final previous = state.themeMode;
    emit(
      state.copyWith(
        status: SettingsStatus.success,
        themeMode: event.themeMode,
      ),
    );
    try {
      await _repo.saveThemeMode(event.themeMode);
    } catch (_) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          themeMode: previous,
          error: 'Could not save the theme. Please try again.',
        ),
      );
    }
  }

  /// Shows the new switch position at once, then saves it. If saving
  /// fails, it puts the old position back and sets an error message.
  Future<void> _onNotificationsToggled(
      NotificationsToggled event,
      Emitter<SettingsState> emit,
      ) async {
    final previous = state.notificationsEnabled;
    emit(
      state.copyWith(
        status: SettingsStatus.success,
        notificationsEnabled: event.enabled,
      ),
    );
    try {
      await _repo.saveNotifications(event.enabled);
    } catch (_) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          notificationsEnabled: previous,
          error: 'Could not save your notification setting. Please try again.',
        ),
      );
    }
  }

  /// Shows the new district at once, then saves it. If saving fails, it
  /// puts the old district back and sets an error message.
  Future<void> _onDefaultDistrictChanged(
      DefaultDistrictChanged event,
      Emitter<SettingsState> emit,
      ) async {
    final previous = state.defaultDistrict;
    emit(
      state.copyWith(
        status: SettingsStatus.success,
        defaultDistrict: event.district,
      ),
    );
    try {
      await _repo.saveDefaultDistrict(event.district);
    } catch (_) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          defaultDistrict: previous,
          error: 'Could not save your district. Please try again.',
        ),
      );
    }
  }
}
