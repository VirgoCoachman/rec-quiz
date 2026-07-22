import '../domain/best_score_repository.dart';

final class LoadBestScore {
  const LoadBestScore(this._repository);

  final BestScoreRepository _repository;

  Future<int> call() => _repository.loadBestScore();
}
