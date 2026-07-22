import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/features/quiz/domain/question_attempt.dart';

import '../quiz_test_data.dart';

void main() {
  final question = buildQuizQuestions().first;

  test('records an immutable correct answer with its learning content', () {
    final attempt = QuestionAttempt.answer(
      question: question,
      selectedOptionId: question.correctOptionId,
    );

    expect(attempt.questionId, question.id);
    expect(attempt.prompt, question.prompt);
    expect(attempt.selectedOption, question.correctOption);
    expect(attempt.correctOption, question.correctOption);
    expect(attempt.isCorrect, isTrue);
    expect(attempt.score, 1);
    expect(attempt.explanation, question.explanation);
    expect(attempt.biblicalReference, question.biblicalReference);
  });

  test('records the selected and correct options for an incorrect answer', () {
    final incorrectOption = question.options.firstWhere(
      (option) => option.id != question.correctOptionId,
    );

    final attempt = QuestionAttempt.answer(
      question: question,
      selectedOptionId: incorrectOption.id,
    );

    expect(attempt.selectedOption, incorrectOption);
    expect(attempt.correctOption, question.correctOption);
    expect(attempt.isCorrect, isFalse);
    expect(attempt.score, 0);
  });

  test('rejects an option that does not belong to the question', () {
    expect(
      () => QuestionAttempt.answer(
        question: question,
        selectedOptionId: 'unknown',
      ),
      throwsArgumentError,
    );
  });
}
