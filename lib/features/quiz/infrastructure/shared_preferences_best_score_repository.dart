import 'package:shared_preferences/shared_preferences.dart';

import '../domain/best_score_repository.dart';
import '../domain/quick_quiz_length.dart';

final class SharedPreferencesBestScoreRepository
    implements BestScoreRepository {
  const SharedPreferencesBestScoreRepository(this._preferences);

  static const _legacyTenQuestionStorageKey = 'quiz.quick.best_score.v1';
  static const _storageKeyPrefix = 'quiz.quick.best_score.v2';

  final SharedPreferences _preferences;

  @override
  Future<int> loadBestScore(QuickQuizLength length) async {
    final storageKey = _storageKey(length);
    final score = _preferences.getInt(storageKey);
    if (score != null) {
      return score;
    }

    if (length == QuickQuizLength.ten) {
      final legacyScore = _preferences.getInt(_legacyTenQuestionStorageKey);
      if (legacyScore != null) {
        final wasMigrated = await _preferences.setInt(storageKey, legacyScore);
        if (!wasMigrated) {
          throw StateError('The legacy best score could not be migrated.');
        }
        return legacyScore;
      }
    }

    return 0;
  }

  @override
  Future<void> saveBestScore(QuickQuizLength length, int score) async {
    final wasSaved = await _preferences.setInt(_storageKey(length), score);
    if (!wasSaved) {
      throw StateError('The best score could not be saved.');
    }
  }

  String _storageKey(QuickQuizLength length) =>
      '$_storageKeyPrefix.${length.questionCount}';
}
