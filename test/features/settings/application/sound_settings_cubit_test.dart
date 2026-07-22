import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/features/settings/application/sound_settings_cubit.dart';
import 'package:rec_quiz/features/settings/domain/sound_settings_repository.dart';

void main() {
  blocTest<SoundSettingsCubit, SoundSettingsState>(
    'loads the persisted sound preference',
    build: () => SoundSettingsCubit(_MemorySoundSettingsRepository(false)),
    act: (cubit) => cubit.load(),
    expect: () => [
      const SoundSettingsState(isEnabled: false, isLoading: false),
    ],
  );

  test('persists a changed sound preference', () async {
    final repository = _MemorySoundSettingsRepository(true);
    final cubit = SoundSettingsCubit(repository);
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.setEnabled(false);

    expect(
      cubit.state,
      const SoundSettingsState(isEnabled: false, isLoading: false),
    );
    expect(repository.savedValues, [false]);
  });

  blocTest<SoundSettingsCubit, SoundSettingsState>(
    'keeps the current setting when persistence fails',
    build: () => SoundSettingsCubit(_FailingSoundSettingsRepository()),
    seed: () => const SoundSettingsState(isEnabled: true, isLoading: false),
    act: (cubit) => cubit.setEnabled(false),
    expect: () => <SoundSettingsState>[],
    errors: () => [isA<StateError>()],
  );
}

class _MemorySoundSettingsRepository implements SoundSettingsRepository {
  _MemorySoundSettingsRepository(this.isEnabled);

  bool isEnabled;
  final savedValues = <bool>[];

  @override
  Future<bool> loadSoundEnabled() async => isEnabled;

  @override
  Future<void> saveSoundEnabled(bool isEnabled) async {
    this.isEnabled = isEnabled;
    savedValues.add(isEnabled);
  }
}

final class _FailingSoundSettingsRepository
    extends _MemorySoundSettingsRepository {
  _FailingSoundSettingsRepository() : super(true);

  @override
  Future<void> saveSoundEnabled(bool isEnabled) {
    throw StateError('Storage unavailable');
  }
}
