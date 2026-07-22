import 'package:shared_preferences/shared_preferences.dart';

import '../domain/sound_settings_repository.dart';

final class SharedPreferencesSoundSettingsRepository
    implements SoundSettingsRepository {
  const SharedPreferencesSoundSettingsRepository(this._preferences);

  static const _storageKey = 'quiz.sound.enabled.v1';

  final SharedPreferences _preferences;

  @override
  Future<bool> loadSoundEnabled() async {
    return _preferences.getBool(_storageKey) ?? true;
  }

  @override
  Future<void> saveSoundEnabled(bool isEnabled) async {
    final wasSaved = await _preferences.setBool(_storageKey, isEnabled);
    if (!wasSaved) {
      throw StateError('The sound preference could not be saved.');
    }
  }
}
