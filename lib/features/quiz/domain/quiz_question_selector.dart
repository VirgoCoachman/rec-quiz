import 'dart:math';

import 'question.dart';

final class QuizQuestionSelector {
  const QuizQuestionSelector();

  List<Question> select({
    required List<Question> questions,
    required int count,
    required int seed,
  }) {
    if (count < 1) {
      throw ArgumentError.value(count, 'count', 'The count must be positive.');
    }
    if (questions.length < count) {
      throw StateError(
        'Cannot select $count questions from ${questions.length} available.',
      );
    }

    final random = Random(seed);
    final questionPool = List<Question>.of(questions)..shuffle(random);
    final selected = questionPool.take(count).map((question) {
      final shuffledOptions = List<QuestionOption>.of(question.options)
        ..shuffle(random);
      return Question(
        id: question.id,
        prompt: question.prompt,
        options: shuffledOptions,
        correctOptionId: question.correctOptionId,
        explanation: question.explanation,
        biblicalReference: question.biblicalReference,
        difficulty: question.difficulty,
        theme: question.theme,
        subject: question.subject,
        languageCode: question.languageCode,
        contentVersion: question.contentVersion,
        isActive: question.isActive,
      );
    });

    return List.unmodifiable(selected);
  }
}
