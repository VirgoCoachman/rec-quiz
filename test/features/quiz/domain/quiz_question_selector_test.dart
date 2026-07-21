import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/features/quiz/domain/question.dart';
import 'package:rec_quiz/features/quiz/domain/quiz_question_selector.dart';

import '../quiz_test_data.dart';

void main() {
  const selector = QuizQuestionSelector();
  final questions = buildQuizQuestions(count: 12);

  test('selects ten unique questions and shuffles their options', () {
    final selected = selector.select(questions: questions, count: 10, seed: 42);

    expect(selected, hasLength(10));
    expect(selected.map((question) => question.id).toSet(), hasLength(10));
    expect(
      selected.every(
        (question) => question.options.any(
          (option) => option.id == question.correctOptionId,
        ),
      ),
      isTrue,
    );

    final correctPositions = selected
        .map(
          (question) => question.options.indexWhere(
            (option) => option.id == question.correctOptionId,
          ),
        )
        .toSet();
    expect(correctPositions.length, greaterThan(1));
  });

  test('produces the same order and option positions for the same seed', () {
    final first = selector.select(questions: questions, count: 10, seed: 1234);
    final second = selector.select(questions: questions, count: 10, seed: 1234);

    expect(_signature(first), _signature(second));
  });

  test('produces a different order when the seed changes', () {
    final first = selector.select(questions: questions, count: 10, seed: 1);
    final second = selector.select(questions: questions, count: 10, seed: 2);

    expect(_signature(first), isNot(_signature(second)));
  });

  test('rejects invalid counts without mutating the source list', () {
    final originalIds = questions.map((question) => question.id).toList();

    expect(
      () => selector.select(questions: questions, count: 0, seed: 1),
      throwsArgumentError,
    );
    expect(
      () => selector.select(questions: questions, count: 13, seed: 1),
      throwsStateError,
    );
    expect(questions.map((question) => question.id), originalIds);
  });
}

List<String> _signature(List<Question> questions) {
  return questions
      .map<String>(
        (question) =>
            '${question.id}:${question.options.map((option) => option.id).join(',')}',
      )
      .toList();
}
