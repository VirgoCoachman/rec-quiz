import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/features/quiz/domain/question_learning_progress.dart';
import 'package:rec_quiz/features/quiz/infrastructure/shared_preferences_question_learning_progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('persists progress for a question', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = SharedPreferencesQuestionLearningProgressRepository(
      await SharedPreferences.getInstance(),
    );
    final progress = QuestionLearningProgress(
      questionId: 'question-1',
      correctAnswers: 2,
      incorrectAnswers: 1,
      correctStreak: 1,
      lastSeenAt: DateTime(2026, 7, 22),
    );

    await repository.save(progress);
    final restored = await repository.loadAll();

    expect(restored['question-1']?.correctAnswers, 2);
    expect(restored['question-1']?.incorrectAnswers, 1);
    expect(restored['question-1']?.lastSeenAt, DateTime(2026, 7, 22));
  });
}
