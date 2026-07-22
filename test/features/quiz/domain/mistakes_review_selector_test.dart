import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/features/quiz/domain/mistakes_review_selector.dart';
import 'package:rec_quiz/features/quiz/domain/question_attempt.dart';

import '../quiz_test_data.dart';

void main() {
  const selector = MistakesReviewSelector();
  final questions = buildQuizQuestions(count: 3);

  test('selects each incorrectly answered question once in attempt order', () {
    final firstIncorrect = QuestionAttempt.answer(
      question: questions[0],
      selectedOptionId: questions[0].options[1].id,
    );
    final correct = QuestionAttempt.answer(
      question: questions[1],
      selectedOptionId: questions[1].correctOptionId,
    );
    final thirdIncorrect = QuestionAttempt.answer(
      question: questions[2],
      selectedOptionId: questions[2].options[2].id,
    );

    final selected = selector.select([
      firstIncorrect,
      correct,
      firstIncorrect,
      thirdIncorrect,
    ]);

    expect(selected.map((question) => question.id), [
      questions[0].id,
      questions[2].id,
    ]);
  });

  test('returns an immutable empty selection after a perfect session', () {
    final selected = selector.select([
      for (final question in questions)
        QuestionAttempt.answer(
          question: question,
          selectedOptionId: question.correctOptionId,
        ),
    ]);

    expect(selected, isEmpty);
    expect(() => selected.add(questions.first), throwsUnsupportedError);
  });
}
