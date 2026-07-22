abstract interface class QuizSessionTimer {
  void start();

  void pause();

  void resume();

  Duration stop();
}
