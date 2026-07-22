import 'question_learning_progress.dart';

abstract interface class QuestionLearningProgressRepository {
  Future<Map<String, QuestionLearningProgress>> loadAll();

  Future<void> save(QuestionLearningProgress progress);
}
