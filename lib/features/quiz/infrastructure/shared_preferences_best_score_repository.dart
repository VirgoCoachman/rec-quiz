import 'package:shared_preferences/shared_preferences.dart';

import '../domain/best_score_repository.dart';

final class SharedPreferencesBestScoreRepository
    implements BestScoreRepository {
  const SharedPreferencesBestScoreRepository(this._preferences);

  static const _storageKey = 'quiz.quick.best_score.v1';

  final SharedPreferences _preferences;

  @override
  Future<int> loadBestScore() async => _preferences.getInt(_storageKey) ?? 0;

  @override
  Future<void> saveBestScore(int score) async {
    final wasSaved = await _preferences.setInt(_storageKey, score);
    if (!wasSaved) {
      throw StateError('The best score could not be saved.');
    }
  }
}
