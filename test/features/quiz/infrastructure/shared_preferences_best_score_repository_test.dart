import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/features/quiz/infrastructure/shared_preferences_best_score_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('returns zero when no best score has been saved', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesBestScoreRepository(preferences);

    expect(await repository.loadBestScore(), 0);
  });

  test('persists the best score across repository instances', () async {
    final preferences = await SharedPreferences.getInstance();
    final firstRepository = SharedPreferencesBestScoreRepository(preferences);

    await firstRepository.saveBestScore(9);

    final reloadedPreferences = await SharedPreferences.getInstance();
    final secondRepository = SharedPreferencesBestScoreRepository(
      reloadedPreferences,
    );
    expect(await secondRepository.loadBestScore(), 9);
  });
}
