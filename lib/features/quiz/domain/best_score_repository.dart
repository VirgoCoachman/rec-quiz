abstract interface class BestScoreRepository {
  Future<int> loadBestScore();

  Future<void> saveBestScore(int score);
}
