import 'quick_quiz_length.dart';

abstract interface class BestScoreRepository {
  Future<int> loadBestScore(QuickQuizLength length);

  Future<void> saveBestScore(QuickQuizLength length, int score);
}
