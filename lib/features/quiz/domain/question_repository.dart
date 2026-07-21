import 'question.dart';

abstract interface class QuestionRepository {
  Future<Question> loadFirstActiveQuestion();
}
