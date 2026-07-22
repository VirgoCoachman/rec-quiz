import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/features/quiz/infrastructure/stopwatch_quiz_session_timer.dart';

void main() {
  test('excludes paused time from the final elapsed duration', () async {
    final timer = StopwatchQuizSessionTimer();

    timer.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    timer.pause();
    final elapsedBeforePause = timer.stop();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final elapsedAfterPause = timer.stop();

    expect(elapsedAfterPause, elapsedBeforePause);

    timer.resume();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final elapsedAfterResume = timer.stop();

    expect(elapsedAfterResume, greaterThan(elapsedAfterPause));
  });

  test('allows idempotent pause and resume calls', () async {
    final timer = StopwatchQuizSessionTimer();

    timer.start();
    timer
      ..pause()
      ..pause()
      ..resume()
      ..resume();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(timer.stop(), greaterThan(Duration.zero));
  });

  test('continues from a restored elapsed duration', () async {
    final timer = StopwatchQuizSessionTimer();

    timer.start(initialElapsed: const Duration(minutes: 2, seconds: 15));
    timer.pause();
    timer.resume();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(timer.stop(), greaterThan(const Duration(minutes: 2, seconds: 15)));
  });
}
