import 'paused_quiz_session.dart';

abstract interface class PausedQuizSessionRepository {
  Future<PausedQuizSession?> load();

  Future<void> save(PausedQuizSession session);

  Future<void> clear();
}
