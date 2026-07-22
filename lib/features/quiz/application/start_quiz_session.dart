import '../domain/question.dart';
import 'dart:math';
import '../domain/question_learning_progress_repository.dart';
import '../domain/question_repository.dart';
import '../domain/quiz_question_selector.dart';
import '../domain/quick_quiz_length.dart';

typedef SeedGenerator = int Function();

final class StartQuizSession {
  const StartQuizSession({
    required QuestionRepository repository,
    required QuizQuestionSelector selector,
    required SeedGenerator seedGenerator,
    QuestionLearningProgressRepository? learningProgressRepository,
  }) : _repository = repository,
       _selector = selector,
       _seedGenerator = seedGenerator,
       _learningProgressRepository = learningProgressRepository;

  final QuestionRepository _repository;
  final QuizQuestionSelector _selector;
  final SeedGenerator _seedGenerator;
  final QuestionLearningProgressRepository? _learningProgressRepository;

  Future<List<Question>> call(
    QuickQuizLength length, {
    bool focusedOnly = false,
  }) async {
    final questions = await _repository.loadActiveQuestions();
    final progressByQuestionId =
        await _learningProgressRepository?.loadAll() ?? const {};
    final fragile = questions
        .where(
          (question) => (progressByQuestionId[question.id]?.priority ?? 0) > 0,
        )
        .toList();
    final due = fragile
        .where(
          (question) =>
              progressByQuestionId[question.id]?.isDue(
                DateTime.now().toUtc(),
              ) ??
              false,
        )
        .toList();
    final candidates = focusedOnly
        ? (due.isNotEmpty ? due : fragile)
        : questions;
    return _selector.select(
      questions: candidates,
      count: min(length.questionCount, candidates.length),
      seed: _seedGenerator(),
      progressByQuestionId: progressByQuestionId,
    );
  }
}
