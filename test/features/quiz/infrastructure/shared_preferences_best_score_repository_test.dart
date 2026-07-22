import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/features/quiz/domain/quick_quiz_length.dart';
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

    for (final length in QuickQuizLength.values) {
      expect(await repository.loadBestScore(length), 0);
    }
  });

  test('persists independent best scores for every quiz length', () async {
    final preferences = await SharedPreferences.getInstance();
    final firstRepository = SharedPreferencesBestScoreRepository(preferences);

    await firstRepository.saveBestScore(QuickQuizLength.five, 4);
    await firstRepository.saveBestScore(QuickQuizLength.ten, 9);
    await firstRepository.saveBestScore(QuickQuizLength.twenty, 18);

    final reloadedPreferences = await SharedPreferences.getInstance();
    final secondRepository = SharedPreferencesBestScoreRepository(
      reloadedPreferences,
    );
    expect(await secondRepository.loadBestScore(QuickQuizLength.five), 4);
    expect(await secondRepository.loadBestScore(QuickQuizLength.ten), 9);
    expect(await secondRepository.loadBestScore(QuickQuizLength.twenty), 18);
  });

  test('migrates the legacy ten-question best score', () async {
    SharedPreferences.setMockInitialValues({'quiz.quick.best_score.v1': 7});
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesBestScoreRepository(preferences);

    expect(await repository.loadBestScore(QuickQuizLength.ten), 7);
    expect(preferences.getInt('quiz.quick.best_score.v2.10'), 7);
    expect(await repository.loadBestScore(QuickQuizLength.five), 0);
    expect(await repository.loadBestScore(QuickQuizLength.twenty), 0);
  });
}
