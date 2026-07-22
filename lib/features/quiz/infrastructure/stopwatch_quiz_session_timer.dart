import '../domain/quiz_session_timer.dart';

final class StopwatchQuizSessionTimer implements QuizSessionTimer {
  final Stopwatch _stopwatch = Stopwatch();
  Duration _initialElapsed = Duration.zero;

  @override
  void start({Duration initialElapsed = Duration.zero}) {
    _initialElapsed = initialElapsed;
    _stopwatch
      ..reset()
      ..start();
  }

  @override
  Duration pause() {
    _stopwatch.stop();
    return _elapsed;
  }

  @override
  void resume() {
    _stopwatch.start();
  }

  @override
  Duration stop() {
    _stopwatch.stop();
    return _elapsed;
  }

  Duration get _elapsed => _initialElapsed + _stopwatch.elapsed;
}
