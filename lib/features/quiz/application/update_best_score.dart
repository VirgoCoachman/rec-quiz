import '../domain/best_score_repository.dart';

final class UpdateBestScore {
  const UpdateBestScore(this._repository);

  final BestScoreRepository _repository;

  Future<int> call({required int candidate, required int currentBest}) {
    if (candidate < 0 || currentBest < 0) {
      throw ArgumentError.value(
        candidate < 0 ? candidate : currentBest,
        candidate < 0 ? 'candidate' : 'currentBest',
        'A score cannot be negative.',
      );
    }
    if (candidate <= currentBest) {
      return Future.value(currentBest);
    }
    return _save(candidate);
  }

  Future<int> _save(int score) async {
    await _repository.saveBestScore(score);
    return score;
  }
}
