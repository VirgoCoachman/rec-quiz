import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/sound_settings_repository.dart';

final class SoundSettingsState {
  const SoundSettingsState({required this.isEnabled, required this.isLoading});

  const SoundSettingsState.initial() : isEnabled = true, isLoading = true;

  final bool isEnabled;
  final bool isLoading;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SoundSettingsState &&
            other.isEnabled == isEnabled &&
            other.isLoading == isLoading;
  }

  @override
  int get hashCode => Object.hash(isEnabled, isLoading);
}

final class SoundSettingsCubit extends Cubit<SoundSettingsState> {
  SoundSettingsCubit(this._repository)
    : super(const SoundSettingsState.initial());

  final SoundSettingsRepository _repository;

  Future<void> load() async {
    try {
      emit(
        SoundSettingsState(
          isEnabled: await _repository.loadSoundEnabled(),
          isLoading: false,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(SoundSettingsState(isEnabled: state.isEnabled, isLoading: false));
    }
  }

  Future<void> setEnabled(bool isEnabled) async {
    if (state.isLoading || state.isEnabled == isEnabled) {
      return;
    }

    try {
      await _repository.saveSoundEnabled(isEnabled);
      emit(SoundSettingsState(isEnabled: isEnabled, isLoading: false));
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
    }
  }
}
