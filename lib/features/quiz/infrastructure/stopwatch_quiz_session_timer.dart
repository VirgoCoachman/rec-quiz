import '../domain/quiz_session_timer.dart';

final class StopwatchQuizSessionTimer implements QuizSessionTimer {
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void start() {
    _stopwatch
      ..reset()
      ..start();
  }

  @override
  Duration stop() {
    _stopwatch.stop();
    return _stopwatch.elapsed;
  }
}
