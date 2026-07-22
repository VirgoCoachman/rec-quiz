import '../domain/best_score_repository.dart';
import '../domain/quick_quiz_length.dart';

final class LoadBestScore {
  const LoadBestScore(this._repository);

  final BestScoreRepository _repository;

  Future<int> call(QuickQuizLength length) => _repository.loadBestScore(length);
}
