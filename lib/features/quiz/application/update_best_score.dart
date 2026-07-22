import '../domain/best_score_repository.dart';
import '../domain/quick_quiz_length.dart';

final class UpdateBestScore {
  const UpdateBestScore(this._repository);

  final BestScoreRepository _repository;

  Future<int> call({
    required QuickQuizLength length,
    required int candidate,
    required int currentBest,
  }) {
    if (candidate < 0 || currentBest < 0) {
      throw ArgumentError.value(
        candidate < 0 ? candidate : currentBest,
        candidate < 0 ? 'candidate' : 'currentBest',
        'A score cannot be negative.',
      );
    }
    if (candidate > length.questionCount ||
        currentBest > length.questionCount) {
      final invalidScore = candidate > length.questionCount
          ? candidate
          : currentBest;
      throw ArgumentError.value(
        invalidScore,
        candidate > length.questionCount ? 'candidate' : 'currentBest',
        'A score cannot exceed ${length.questionCount}.',
      );
    }
    if (candidate <= currentBest) {
      return Future.value(currentBest);
    }
    return _save(length, candidate);
  }

  Future<int> _save(QuickQuizLength length, int score) async {
    await _repository.saveBestScore(length, score);
    return score;
  }
}
