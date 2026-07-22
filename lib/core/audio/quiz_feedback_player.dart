abstract interface class QuizFeedbackPlayer {
  Future<void> playCorrectAnswer();

  Future<void> playIncorrectAnswer();
}
