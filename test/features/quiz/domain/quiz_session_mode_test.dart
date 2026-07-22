import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/features/quiz/domain/quiz_session_mode.dart';

void main() {
  test('supports only quick quiz and mistakes review sessions', () {
    expect(QuizSessionMode.values, [
      QuizSessionMode.quickQuiz,
      QuizSessionMode.mistakesReview,
    ]);
  });
}
