import 'question.dart';
import 'quick_quiz_length.dart';
import 'quiz_session_mode.dart';

final class PausedQuestionAttempt {
  PausedQuestionAttempt({
    required this.questionId,
    required this.selectedOptionId,
  });

  final String questionId;
  final String selectedOptionId;
}

final class PausedQuizSession {
  PausedQuizSession({
    required List<Question> questions,
    required this.currentIndex,
    required this.score,
    required this.bestScore,
    required this.elapsed,
    required this.length,
    required this.mode,
    required List<PausedQuestionAttempt> attempts,
  }) : questions = List.unmodifiable(questions),
       attempts = List.unmodifiable(attempts) {
    if (questions.isEmpty ||
        currentIndex < 0 ||
        currentIndex >= questions.length) {
      throw ArgumentError('A paused quiz must point to an available question.');
    }
  }

  final List<Question> questions;
  final int currentIndex;
  final int score;
  final int bestScore;
  final Duration elapsed;
  final QuickQuizLength length;
  final QuizSessionMode mode;
  final List<PausedQuestionAttempt> attempts;
}
