import 'question.dart';

abstract interface class QuestionRepository {
  Future<List<Question>> loadActiveQuestions();
}
