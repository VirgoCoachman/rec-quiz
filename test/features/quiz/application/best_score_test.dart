import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/features/quiz/application/load_best_score.dart';
import 'package:rec_quiz/features/quiz/application/update_best_score.dart';
import 'package:rec_quiz/features/quiz/domain/best_score_repository.dart';

void main() {
  test('loads the persisted best score', () async {
    final repository = _FakeBestScoreRepository(7);

    final score = await LoadBestScore(repository)();

    expect(score, 7);
  });

  test('persists and returns a score higher than the current best', () async {
    final repository = _FakeBestScoreRepository(6);
    final update = UpdateBestScore(repository);

    final bestScore = await update(candidate: 8, currentBest: 6);

    expect(bestScore, 8);
    expect(repository.savedScores, [8]);
  });

  test('keeps the current best when a score is lower or equal', () async {
    final repository = _FakeBestScoreRepository(8);
    final update = UpdateBestScore(repository);

    expect(await update(candidate: 7, currentBest: 8), 8);
    expect(await update(candidate: 8, currentBest: 8), 8);
    expect(repository.savedScores, isEmpty);
  });

  test('rejects negative score values', () {
    final update = UpdateBestScore(_FakeBestScoreRepository(0));

    expect(() => update(candidate: -1, currentBest: 0), throwsArgumentError);
    expect(() => update(candidate: 1, currentBest: -1), throwsArgumentError);
  });
}

final class _FakeBestScoreRepository implements BestScoreRepository {
  _FakeBestScoreRepository(this.score);

  int score;
  final savedScores = <int>[];

  @override
  Future<int> loadBestScore() async => score;

  @override
  Future<void> saveBestScore(int score) async {
    this.score = score;
    savedScores.add(score);
  }
}
