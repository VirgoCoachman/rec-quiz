import 'question.dart';
import 'question_attempt.dart';

final class MistakesReviewSelector {
  const MistakesReviewSelector();

  List<Question> select(List<QuestionAttempt> attempts) {
    final seenQuestionIds = <String>{};
    final questions = <Question>[];

    for (final attempt in attempts) {
      if (!attempt.isCorrect && seenQuestionIds.add(attempt.questionId)) {
        questions.add(attempt.question);
      }
    }

    return List.unmodifiable(questions);
  }
}
