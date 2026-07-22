import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/features/settings/infrastructure/shared_preferences_sound_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('enables sound by default', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesSoundSettingsRepository(preferences);

    expect(await repository.loadSoundEnabled(), isTrue);
  });

  test('persists a disabled sound preference across instances', () async {
    final preferences = await SharedPreferences.getInstance();
    final firstRepository = SharedPreferencesSoundSettingsRepository(
      preferences,
    );

    await firstRepository.saveSoundEnabled(false);

    final reloadedPreferences = await SharedPreferences.getInstance();
    final secondRepository = SharedPreferencesSoundSettingsRepository(
      reloadedPreferences,
    );
    expect(await secondRepository.loadSoundEnabled(), isFalse);
  });
}
