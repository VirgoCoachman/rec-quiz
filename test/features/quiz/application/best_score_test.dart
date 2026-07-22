import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/features/quiz/application/load_best_score.dart';
import 'package:rec_quiz/features/quiz/application/update_best_score.dart';
import 'package:rec_quiz/features/quiz/domain/best_score_repository.dart';
import 'package:rec_quiz/features/quiz/domain/quick_quiz_length.dart';

void main() {
  test('loads the persisted best score', () async {
    final repository = _FakeBestScoreRepository({QuickQuizLength.twenty: 17});

    final score = await LoadBestScore(repository)(QuickQuizLength.twenty);

    expect(score, 17);
  });

  test('persists and returns a score higher than the current best', () async {
    final repository = _FakeBestScoreRepository({QuickQuizLength.ten: 6});
    final update = UpdateBestScore(repository);

    final bestScore = await update(
      length: QuickQuizLength.ten,
      candidate: 8,
      currentBest: 6,
    );

    expect(bestScore, 8);
    expect(repository.savedScores, [(QuickQuizLength.ten, 8)]);
  });

  test('keeps the current best when a score is lower or equal', () async {
    final repository = _FakeBestScoreRepository({QuickQuizLength.ten: 8});
    final update = UpdateBestScore(repository);

    expect(
      await update(length: QuickQuizLength.ten, candidate: 7, currentBest: 8),
      8,
    );
    expect(
      await update(length: QuickQuizLength.ten, candidate: 8, currentBest: 8),
      8,
    );
    expect(repository.savedScores, isEmpty);
  });

  test('rejects scores outside the selected quiz length', () {
    final update = UpdateBestScore(_FakeBestScoreRepository({}));

    expect(
      () => update(length: QuickQuizLength.five, candidate: -1, currentBest: 0),
      throwsArgumentError,
    );
    expect(
      () => update(length: QuickQuizLength.five, candidate: 1, currentBest: -1),
      throwsArgumentError,
    );
    expect(
      () => update(length: QuickQuizLength.five, candidate: 6, currentBest: 0),
      throwsArgumentError,
    );
  });
}

final class _FakeBestScoreRepository implements BestScoreRepository {
  _FakeBestScoreRepository(this.scores);

  final Map<QuickQuizLength, int> scores;
  final savedScores = <(QuickQuizLength, int)>[];

  @override
  Future<int> loadBestScore(QuickQuizLength length) async =>
      scores[length] ?? 0;

  @override
  Future<void> saveBestScore(QuickQuizLength length, int score) async {
    scores[length] = score;
    savedScores.add((length, score));
  }
}
