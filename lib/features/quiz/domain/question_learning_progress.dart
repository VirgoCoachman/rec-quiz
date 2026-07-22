final class QuestionLearningProgress {
  const QuestionLearningProgress({
    required this.questionId,
    this.correctAnswers = 0,
    this.incorrectAnswers = 0,
    this.correctStreak = 0,
    this.lastSeenAt,
  });

  final String questionId;
  final int correctAnswers;
  final int incorrectAnswers;
  final int correctStreak;
  final DateTime? lastSeenAt;

  int get priority => (incorrectAnswers * 3) - correctStreak;

  QuestionLearningProgress recordAnswer({
    required bool isCorrect,
    required DateTime answeredAt,
  }) => QuestionLearningProgress(
    questionId: questionId,
    correctAnswers: correctAnswers + (isCorrect ? 1 : 0),
    incorrectAnswers: incorrectAnswers + (isCorrect ? 0 : 1),
    correctStreak: isCorrect ? correctStreak + 1 : 0,
    lastSeenAt: answeredAt,
  );
}
