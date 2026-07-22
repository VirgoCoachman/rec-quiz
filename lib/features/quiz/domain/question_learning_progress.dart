final class QuestionLearningProgress {
  const QuestionLearningProgress({
    required this.questionId,
    this.correctAnswers = 0,
    this.incorrectAnswers = 0,
    this.correctStreak = 0,
    this.lastSeenAt,
    this.nextReviewAt,
  });

  final String questionId;
  final int correctAnswers;
  final int incorrectAnswers;
  final int correctStreak;
  final DateTime? lastSeenAt;
  final DateTime? nextReviewAt;

  int get priority => (incorrectAnswers * 3) - correctStreak;

  bool isDue(DateTime now) =>
      nextReviewAt != null && !nextReviewAt!.isAfter(now);

  QuestionLearningProgress recordAnswer({
    required bool isCorrect,
    required DateTime answeredAt,
  }) => QuestionLearningProgress(
    questionId: questionId,
    correctAnswers: correctAnswers + (isCorrect ? 1 : 0),
    incorrectAnswers: incorrectAnswers + (isCorrect ? 0 : 1),
    correctStreak: isCorrect ? correctStreak + 1 : 0,
    lastSeenAt: answeredAt,
    nextReviewAt: answeredAt.add(
      isCorrect
          ? switch (correctStreak + 1) {
              1 => const Duration(days: 1),
              2 => const Duration(days: 3),
              _ => const Duration(days: 7),
            }
          : const Duration(hours: 1),
    ),
  );
}
