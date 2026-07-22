import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/features/quiz/domain/quick_quiz_length.dart';

void main() {
  test('exposes only the supported quick quiz question counts', () {
    expect(QuickQuizLength.values.map((length) => length.questionCount), [
      5,
      10,
      20,
    ]);
  });

  test('maps supported question counts to a quick quiz length', () {
    expect(QuickQuizLength.fromQuestionCount(5), QuickQuizLength.five);
    expect(QuickQuizLength.fromQuestionCount(10), QuickQuizLength.ten);
    expect(QuickQuizLength.fromQuestionCount(20), QuickQuizLength.twenty);
  });

  test('rejects unsupported quick quiz question counts', () {
    expect(() => QuickQuizLength.fromQuestionCount(0), throwsArgumentError);
    expect(() => QuickQuizLength.fromQuestionCount(15), throwsArgumentError);
  });
}
