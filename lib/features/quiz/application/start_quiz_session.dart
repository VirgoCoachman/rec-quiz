import '../domain/question.dart';
import '../domain/question_repository.dart';
import '../domain/quiz_question_selector.dart';

typedef SeedGenerator = int Function();

final class StartQuizSession {
  const StartQuizSession({
    required QuestionRepository repository,
    required QuizQuestionSelector selector,
    required SeedGenerator seedGenerator,
    this.questionCount = 10,
  }) : _repository = repository,
       _selector = selector,
       _seedGenerator = seedGenerator;

  final QuestionRepository _repository;
  final QuizQuestionSelector _selector;
  final SeedGenerator _seedGenerator;
  final int questionCount;

  Future<List<Question>> call() async {
    final questions = await _repository.loadActiveQuestions();
    return _selector.select(
      questions: questions,
      count: questionCount,
      seed: _seedGenerator(),
    );
  }
}
