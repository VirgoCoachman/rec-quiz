abstract interface class SoundSettingsRepository {
  Future<bool> loadSoundEnabled();

  Future<void> saveSoundEnabled(bool isEnabled);
}
