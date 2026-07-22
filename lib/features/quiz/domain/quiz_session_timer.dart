abstract interface class QuizSessionTimer {
  void start({Duration initialElapsed = Duration.zero});

  Duration pause();

  void resume();

  Duration stop();
}
