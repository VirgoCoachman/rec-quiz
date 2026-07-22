import '../domain/question.dart';
import '../domain/question_repository.dart';
import '../domain/quiz_question_selector.dart';
import '../domain/quick_quiz_length.dart';

typedef SeedGenerator = int Function();

final class StartQuizSession {
  const StartQuizSession({
    required QuestionRepository repository,
    required QuizQuestionSelector selector,
    required SeedGenerator seedGenerator,
  }) : _repository = repository,
       _selector = selector,
       _seedGenerator = seedGenerator;

  final QuestionRepository _repository;
  final QuizQuestionSelector _selector;
  final SeedGenerator _seedGenerator;

  Future<List<Question>> call(QuickQuizLength length) async {
    final questions = await _repository.loadActiveQuestions();
    return _selector.select(
      questions: questions,
      count: length.questionCount,
      seed: _seedGenerator(),
    );
  }
}
