import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/features/quiz/domain/paused_quiz_session.dart';
import 'package:rec_quiz/features/quiz/domain/quick_quiz_length.dart';
import 'package:rec_quiz/features/quiz/domain/quiz_session_mode.dart';
import 'package:rec_quiz/features/quiz/infrastructure/shared_preferences_paused_quiz_session_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../quiz_test_data.dart';

void main() {
  test('persists, restores, and clears a paused quiz session', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesPausedQuizSessionRepository(
      preferences,
    );
    final questions = buildQuizQuestions(count: 5);
    final session = PausedQuizSession(
      questions: questions,
      currentIndex: 1,
      score: 1,
      bestScore: 3,
      length: QuickQuizLength.five,
      mode: QuizSessionMode.quickQuiz,
      attempts: [
        PausedQuestionAttempt(
          questionId: questions.first.id,
          selectedOptionId: questions.first.correctOptionId,
        ),
      ],
    );

    await repository.save(session);
    final restored = await repository.load();

    expect(restored, isNotNull);
    expect(restored!.questions.map((question) => question.id), [
      questions[0].id,
      questions[1].id,
      questions[2].id,
      questions[3].id,
      questions[4].id,
    ]);
    expect(
      restored.questions[0].options.map((option) => option.id),
      questions[0].options.map((option) => option.id),
    );
    expect(restored.currentIndex, 1);
    expect(restored.score, 1);
    expect(restored.bestScore, 3);
    expect(restored.length, QuickQuizLength.five);
    expect(restored.mode, QuizSessionMode.quickQuiz);
    expect(restored.attempts.single.questionId, questions.first.id);

    await repository.clear();

    expect(await repository.load(), isNull);
  });
}
