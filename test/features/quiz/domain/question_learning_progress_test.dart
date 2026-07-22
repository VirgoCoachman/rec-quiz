import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/features/quiz/domain/question_learning_progress.dart';

void main() {
  test('records answers with a streak reset after an incorrect answer', () {
    const initial = QuestionLearningProgress(questionId: 'question-1');
    final firstCorrect = initial.recordAnswer(
      isCorrect: true,
      answeredAt: DateTime.utc(2026, 7, 22, 10),
    );
    final incorrect = firstCorrect.recordAnswer(
      isCorrect: false,
      answeredAt: DateTime.utc(2026, 7, 22, 11),
    );

    expect(firstCorrect.correctAnswers, 1);
    expect(firstCorrect.correctStreak, 1);
    expect(incorrect.correctAnswers, 1);
    expect(incorrect.incorrectAnswers, 1);
    expect(incorrect.correctStreak, 0);
    expect(incorrect.lastSeenAt, DateTime.utc(2026, 7, 22, 11));
    expect(incorrect.priority, greaterThan(initial.priority));
  });

  test('schedules progressively later reviews after correct answers', () {
    const progress = QuestionLearningProgress(questionId: 'question-1');
    final firstCorrect = progress.recordAnswer(
      isCorrect: true,
      answeredAt: DateTime.utc(2026, 7, 22, 10),
    );
    final incorrect = firstCorrect.recordAnswer(
      isCorrect: false,
      answeredAt: DateTime.utc(2026, 7, 23, 10),
    );

    expect(firstCorrect.nextReviewAt, DateTime.utc(2026, 7, 23, 10));
    expect(incorrect.nextReviewAt, DateTime.utc(2026, 7, 23, 11));
  });
}
