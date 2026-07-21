import '../domain/question.dart';
import '../domain/question_repository.dart';

final class LoadQuizQuestion {
  const LoadQuizQuestion(this._repository);

  final QuestionRepository _repository;

  Future<Question> call() => _repository.loadFirstActiveQuestion();
}
