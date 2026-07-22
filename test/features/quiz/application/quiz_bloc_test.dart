import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/features/quiz/application/load_best_score.dart';
import 'package:rec_quiz/features/quiz/application/quiz_bloc.dart';
import 'package:rec_quiz/features/quiz/application/start_quiz_session.dart';
import 'package:rec_quiz/features/quiz/application/update_best_score.dart';
import 'package:rec_quiz/features/quiz/domain/best_score_repository.dart';
import 'package:rec_quiz/features/quiz/domain/paused_quiz_session.dart';
import 'package:rec_quiz/features/quiz/domain/paused_quiz_session_repository.dart';
import 'package:rec_quiz/features/quiz/domain/question.dart';
import 'package:rec_quiz/features/quiz/domain/question_repository.dart';
import 'package:rec_quiz/features/quiz/domain/quiz_question_selector.dart';
import 'package:rec_quiz/features/quiz/domain/quiz_session_mode.dart';
import 'package:rec_quiz/features/quiz/domain/quiz_session_timer.dart';
import 'package:rec_quiz/features/quiz/domain/quick_quiz_length.dart';

import '../quiz_test_data.dart';

void main() {
  late List<Question> questions;
  late QuestionRepository questionRepository;
  late StartQuizSession startQuizSession;
  late List<Question> expectedOrder;
  late _MemoryBestScoreRepository bestScoreRepository;
  late _FakeQuizSessionTimer sessionTimer;

  setUp(() {
    questions = buildQuizQuestions(count: 20);
    questionRepository = _FakeQuestionRepository(questions);
    startQuizSession = StartQuizSession(
      repository: questionRepository,
      selector: const QuizQuestionSelector(),
      seedGenerator: () => 42,
    );
    expectedOrder = const QuizQuestionSelector().select(
      questions: questions,
      count: 10,
      seed: 42,
    );
    bestScoreRepository = _MemoryBestScoreRepository({});
    sessionTimer = _FakeQuizSessionTimer(const [
      Duration(minutes: 1, seconds: 23),
      Duration(seconds: 17),
    ]);
  });

  blocTest<QuizBloc, QuizState>(
    'loads the persisted best score during initialization',
    build: () {
      bestScoreRepository.scores[QuickQuizLength.ten] = 7;
      return _buildBloc(startQuizSession, bestScoreRepository, sessionTimer);
    },
    act: (bloc) => bloc.add(const QuizInitialized()),
    expect: () => [
      isA<QuizInitial>().having((state) => state.bestScore, 'best score', 7),
    ],
  );

  blocTest<QuizBloc, QuizState>(
    'restores a persisted paused session during initialization',
    build: () => _buildBloc(
      startQuizSession,
      bestScoreRepository,
      sessionTimer,
      pausedSessionRepository: _MemoryPausedQuizSessionRepository(
        PausedQuizSession(
          questions: expectedOrder,
          currentIndex: 1,
          score: 1,
          bestScore: 6,
          length: QuickQuizLength.ten,
          mode: QuizSessionMode.quickQuiz,
          attempts: [
            PausedQuestionAttempt(
              questionId: expectedOrder.first.id,
              selectedOptionId: expectedOrder.first.correctOptionId,
            ),
          ],
        ),
      ),
    ),
    act: (bloc) => bloc.add(const QuizInitialized()),
    expect: () => [
      isA<QuizPaused>()
          .having((state) => state.session.currentIndex, 'index', 1)
          .having((state) => state.session.score, 'score', 1)
          .having((state) => state.session.attempts, 'attempts', hasLength(1)),
    ],
  );

  blocTest<QuizBloc, QuizState>(
    'loads the best score for the selected quiz length',
    setUp: () {
      bestScoreRepository.scores[QuickQuizLength.five] = 4;
    },
    build: () =>
        _buildBloc(startQuizSession, bestScoreRepository, sessionTimer),
    seed: () => const QuizInitial(bestScore: 7),
    act: (bloc) => bloc.add(const QuizLengthSelected(QuickQuizLength.five)),
    expect: () => [
      isA<QuizInitial>()
          .having((state) => state.length, 'length', QuickQuizLength.five)
          .having((state) => state.bestScore, 'best score', 4),
    ],
  );

  blocTest<QuizBloc, QuizState>(
    'loads a ten-question session and carries the best score',
    build: () =>
        _buildBloc(startQuizSession, bestScoreRepository, sessionTimer),
    seed: () => const QuizInitial(bestScore: 6),
    act: (bloc) => bloc.add(const QuizStarted()),
    expect: () => [
      isA<QuizLoading>().having((state) => state.bestScore, 'best score', 6),
      isA<QuizQuestionReady>()
          .having(
            (state) => state.question.id,
            'question id',
            expectedOrder[0].id,
          )
          .having((state) => state.currentNumber, 'current number', 1)
          .having((state) => state.totalQuestions, 'total', 10)
          .having((state) => state.length, 'length', QuickQuizLength.ten)
          .having((state) => state.bestScore, 'best score', 6),
    ],
  );

  blocTest<QuizBloc, QuizState>(
    'loads a five-question session after selection',
    build: () =>
        _buildBloc(startQuizSession, bestScoreRepository, sessionTimer),
    seed: () => const QuizInitial(bestScore: 4, length: QuickQuizLength.five),
    act: (bloc) => bloc.add(const QuizStarted()),
    expect: () => [
      isA<QuizLoading>().having(
        (state) => state.length,
        'length',
        QuickQuizLength.five,
      ),
      isA<QuizQuestionReady>()
          .having((state) => state.totalQuestions, 'total', 5)
          .having((state) => state.length, 'length', QuickQuizLength.five)
          .having((state) => state.bestScore, 'best score', 4),
    ],
  );

  blocTest<QuizBloc, QuizState>(
    'evaluates one answer and ignores subsequent submissions',
    build: () =>
        _buildBloc(startQuizSession, bestScoreRepository, sessionTimer),
    act: (bloc) async {
      bloc.add(const QuizStarted());
      await Future<void>.delayed(Duration.zero);
      bloc
        ..add(QuizAnswerSubmitted(expectedOrder[0].correctOptionId))
        ..add(QuizAnswerSubmitted(expectedOrder[0].options.last.id));
    },
    expect: () => [
      isA<QuizLoading>(),
      isA<QuizQuestionReady>(),
      isA<QuizQuestionReady>()
          .having((state) => state.hasAnswered, 'answered', isTrue)
          .having((state) => state.score, 'score', 1)
          .having(
            (state) => state.evaluation?.selectedOptionId,
            'selected option',
            expectedOrder[0].correctOptionId,
          )
          .having((state) => state.attempts, 'attempts', hasLength(1))
          .having(
            (state) => state.attempts.single.questionId,
            'attempted question',
            expectedOrder[0].id,
          ),
    ],
  );

  blocTest<QuizBloc, QuizState>(
    'moves to the next question and preserves scores',
    build: () =>
        _buildBloc(startQuizSession, bestScoreRepository, sessionTimer),
    seed: () => const QuizInitial(bestScore: 5),
    act: (bloc) async {
      bloc.add(const QuizStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(QuizAnswerSubmitted(expectedOrder[0].correctOptionId));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const QuizNextRequested());
    },
    expect: () => [
      isA<QuizLoading>(),
      isA<QuizQuestionReady>(),
      isA<QuizQuestionReady>(),
      isA<QuizQuestionReady>()
          .having(
            (state) => state.question.id,
            'question id',
            expectedOrder[1].id,
          )
          .having((state) => state.currentNumber, 'current number', 2)
          .having((state) => state.score, 'score', 1)
          .having((state) => state.bestScore, 'best score', 5)
          .having((state) => state.attempts, 'attempts', hasLength(1))
          .having((state) => state.hasAnswered, 'answered', isFalse),
    ],
  );

  blocTest<QuizBloc, QuizState>(
    'persists a new best score when the session completes',
    build: () =>
        _buildBloc(startQuizSession, bestScoreRepository, sessionTimer),
    act: (bloc) async {
      bloc.add(const QuizStarted());
      await Future<void>.delayed(Duration.zero);
      await _completePerfectSession(bloc);
    },
    verify: (bloc) {
      final completed = bloc.state as QuizCompleted;
      expect(completed.score, 10);
      expect(completed.bestScore, 10);
      expect(completed.totalQuestions, 10);
      expect(completed.duration, const Duration(minutes: 1, seconds: 23));
      expect(completed.attempts, hasLength(10));
      expect(
        completed.attempts.map((attempt) => attempt.questionId),
        expectedOrder.map((question) => question.id),
      );
      expect(
        () => completed.attempts.add(completed.attempts.first),
        throwsUnsupportedError,
      );
      expect(bestScoreRepository.savedScores, [(QuickQuizLength.ten, 10)]);
      expect(sessionTimer.startCount, 1);
      expect(sessionTimer.stopCount, 1);
    },
  );

  test(
    'starts a review containing only the mistakes from the quick quiz',
    () async {
      final bloc = _buildBloc(
        startQuizSession,
        bestScoreRepository,
        sessionTimer,
      );
      addTearDown(bloc.close);
      bloc.add(const QuizStarted());
      await Future<void>.delayed(Duration.zero);

      final missedQuestionIds = <String>[];
      for (var index = 0; index < 10; index++) {
        final ready = bloc.state as QuizQuestionReady;
        final shouldMiss = index == 1 || index == 4;
        if (shouldMiss) {
          missedQuestionIds.add(ready.question.id);
        }
        bloc.add(
          QuizAnswerSubmitted(
            shouldMiss
                ? ready.question.options
                      .firstWhere(
                        (option) => option.id != ready.question.correctOptionId,
                      )
                      .id
                : ready.question.correctOptionId,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const QuizNextRequested());
        await Future<void>.delayed(Duration.zero);
      }

      final quickResult = bloc.state as QuizCompleted;
      expect(quickResult.mode, QuizSessionMode.quickQuiz);
      expect(quickResult.incorrectAttempts, hasLength(2));

      bloc
        ..add(const QuizMistakesReviewStarted())
        ..add(const QuizMistakesReviewStarted());
      await Future<void>.delayed(Duration.zero);

      final review = bloc.state as QuizQuestionReady;
      expect(review.mode, QuizSessionMode.mistakesReview);
      expect(review.totalQuestions, 2);
      expect(
        review.questions.map((question) => question.id),
        missedQuestionIds,
      );
      expect(review.attempts, isEmpty);
      expect(sessionTimer.startCount, 2);
    },
  );

  test('does not start a mistakes review after a perfect quick quiz', () async {
    final bloc = _buildBloc(
      startQuizSession,
      bestScoreRepository,
      sessionTimer,
    );
    addTearDown(bloc.close);
    bloc.add(const QuizStarted());
    await Future<void>.delayed(Duration.zero);
    await _completePerfectSession(bloc);

    final completed = bloc.state;
    bloc.add(const QuizMistakesReviewStarted());
    await Future<void>.delayed(Duration.zero);

    expect(identical(bloc.state, completed), isTrue);
    expect(sessionTimer.startCount, 1);
  });

  test(
    'completes a mistakes review without changing the quick best score',
    () async {
      bestScoreRepository.scores[QuickQuizLength.five] = 3;
      final bloc = _buildBloc(
        startQuizSession,
        bestScoreRepository,
        sessionTimer,
      );
      addTearDown(bloc.close);
      bloc.add(const QuizLengthSelected(QuickQuizLength.five));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const QuizStarted());
      await Future<void>.delayed(Duration.zero);

      for (var index = 0; index < 5; index++) {
        final ready = bloc.state as QuizQuestionReady;
        final optionId = index == 0
            ? ready.question.options
                  .firstWhere(
                    (option) => option.id != ready.question.correctOptionId,
                  )
                  .id
            : ready.question.correctOptionId;
        bloc.add(QuizAnswerSubmitted(optionId));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const QuizNextRequested());
        await Future<void>.delayed(Duration.zero);
      }

      bloc.add(const QuizMistakesReviewStarted());
      await Future<void>.delayed(Duration.zero);
      await _completePerfectSession(bloc);

      final reviewResult = bloc.state as QuizCompleted;
      expect(reviewResult.mode, QuizSessionMode.mistakesReview);
      expect(reviewResult.score, 1);
      expect(reviewResult.totalQuestions, 1);
      expect(reviewResult.bestScore, 4);
      expect(bestScoreRepository.savedScores, [(QuickQuizLength.five, 4)]);

      bloc.add(const QuizRestarted());
      await Future<void>.delayed(Duration.zero);
      final restarted = bloc.state as QuizQuestionReady;
      expect(restarted.mode, QuizSessionMode.quickQuiz);
      expect(restarted.length, QuickQuizLength.five);
      expect(restarted.totalQuestions, 5);
    },
  );

  test(
    'keeps only unresolved mistakes in each successive review cycle',
    () async {
      final iterativeTimer = _FakeQuizSessionTimer(const [
        Duration(seconds: 40),
        Duration(seconds: 12),
        Duration(seconds: 5),
      ]);
      final bloc = _buildBloc(
        startQuizSession,
        bestScoreRepository,
        iterativeTimer,
      );
      addTearDown(bloc.close);
      bloc.add(const QuizStarted());
      await Future<void>.delayed(Duration.zero);

      final initiallyMissedIds = <String>[];
      for (var index = 0; index < 10; index++) {
        final ready = bloc.state as QuizQuestionReady;
        final shouldMiss = index < 2;
        if (shouldMiss) {
          initiallyMissedIds.add(ready.question.id);
        }
        bloc.add(
          QuizAnswerSubmitted(
            shouldMiss
                ? ready.question.options
                      .firstWhere(
                        (option) => option.id != ready.question.correctOptionId,
                      )
                      .id
                : ready.question.correctOptionId,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const QuizNextRequested());
        await Future<void>.delayed(Duration.zero);
      }

      bloc.add(const QuizMistakesReviewStarted());
      await Future<void>.delayed(Duration.zero);
      var review = bloc.state as QuizQuestionReady;
      expect(
        review.questions.map((question) => question.id),
        initiallyMissedIds,
      );

      bloc.add(QuizAnswerSubmitted(review.question.correctOptionId));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const QuizNextRequested());
      await Future<void>.delayed(Duration.zero);
      review = bloc.state as QuizQuestionReady;
      final unresolvedQuestionId = review.question.id;
      final incorrectOption = review.question.options.firstWhere(
        (option) => option.id != review.question.correctOptionId,
      );
      bloc.add(QuizAnswerSubmitted(incorrectOption.id));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const QuizNextRequested());
      await Future<void>.delayed(Duration.zero);

      final firstReviewResult = bloc.state as QuizCompleted;
      expect(firstReviewResult.incorrectAttempts, hasLength(1));
      bloc
        ..add(const QuizMistakesReviewStarted())
        ..add(const QuizMistakesReviewStarted());
      await Future<void>.delayed(Duration.zero);

      review = bloc.state as QuizQuestionReady;
      expect(review.mode, QuizSessionMode.mistakesReview);
      expect(review.totalQuestions, 1);
      expect(review.question.id, unresolvedQuestionId);
      expect(review.attempts, isEmpty);

      await _completePerfectSession(bloc);
      final mastered = bloc.state as QuizCompleted;
      expect(mastered.incorrectAttempts, isEmpty);
      final masteredState = bloc.state;
      bloc.add(const QuizMistakesReviewStarted());
      await Future<void>.delayed(Duration.zero);
      expect(identical(bloc.state, masteredState), isTrue);
      expect(bestScoreRepository.savedScores, [(QuickQuizLength.ten, 8)]);
      expect(iterativeTimer.startCount, 3);
      expect(iterativeTimer.stopCount, 3);
    },
  );

  test('pauses and resumes the exact active session', () async {
    final bloc = _buildBloc(
      startQuizSession,
      bestScoreRepository,
      sessionTimer,
    );
    addTearDown(bloc.close);
    bloc.add(const QuizStarted());
    await Future<void>.delayed(Duration.zero);
    final active = bloc.state as QuizQuestionReady;

    bloc
      ..add(const QuizPauseRequested())
      ..add(QuizAnswerSubmitted(active.question.correctOptionId))
      ..add(const QuizNextRequested())
      ..add(const QuizPauseRequested());
    await Future<void>.delayed(Duration.zero);

    final paused = bloc.state as QuizPaused;
    expect(identical(paused.session, active), isTrue);
    expect(paused.bestScore, active.bestScore);
    expect(paused.length, active.length);
    expect(sessionTimer.pauseCount, 1);
    expect(sessionTimer.resumeCount, 0);

    bloc
      ..add(const QuizResumeRequested())
      ..add(const QuizResumeRequested());
    await Future<void>.delayed(Duration.zero);

    expect(identical(bloc.state, active), isTrue);
    expect(sessionTimer.pauseCount, 1);
    expect(sessionTimer.resumeCount, 1);
  });

  test('does not pause after the final answer has stopped timing', () async {
    final bloc = _buildBloc(
      startQuizSession,
      bestScoreRepository,
      sessionTimer,
    );
    addTearDown(bloc.close);
    bloc.add(const QuizStarted());
    await Future<void>.delayed(Duration.zero);

    for (var index = 0; index < 9; index++) {
      final ready = bloc.state as QuizQuestionReady;
      bloc.add(QuizAnswerSubmitted(ready.question.correctOptionId));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const QuizNextRequested());
      await Future<void>.delayed(Duration.zero);
    }

    final finalQuestion = bloc.state as QuizQuestionReady;
    bloc.add(QuizAnswerSubmitted(finalQuestion.question.correctOptionId));
    await Future<void>.delayed(Duration.zero);
    final answered = bloc.state;
    bloc.add(const QuizPauseRequested());
    await Future<void>.delayed(Duration.zero);

    expect(identical(bloc.state, answered), isTrue);
    expect(sessionTimer.pauseCount, 0);
    expect(sessionTimer.stopCount, 1);
  });

  test('stops timing as soon as the final answer is submitted', () async {
    final bloc = _buildBloc(
      startQuizSession,
      bestScoreRepository,
      sessionTimer,
    );
    addTearDown(bloc.close);
    bloc.add(const QuizStarted());
    await Future<void>.delayed(Duration.zero);

    for (var index = 0; index < 9; index++) {
      final ready = bloc.state as QuizQuestionReady;
      bloc.add(QuizAnswerSubmitted(ready.question.correctOptionId));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const QuizNextRequested());
      await Future<void>.delayed(Duration.zero);
    }

    final finalQuestion = bloc.state as QuizQuestionReady;
    bloc.add(QuizAnswerSubmitted(finalQuestion.question.correctOptionId));
    await Future<void>.delayed(Duration.zero);

    expect(sessionTimer.stopCount, 1);
    expect(bloc.state, isA<QuizQuestionReady>());
  });

  test('uses a fresh injected seed for every new session', () async {
    final seeds = _SeedSequence([1, 2]);
    final useCase = StartQuizSession(
      repository: questionRepository,
      selector: const QuizQuestionSelector(),
      seedGenerator: seeds.next,
    );

    final first = await useCase(QuickQuizLength.ten);
    final second = await useCase(QuickQuizLength.ten);

    expect(
      first.map((question) => question.id),
      isNot(second.map((question) => question.id)),
    );
  });

  test('starts a twenty-question session', () async {
    final session = await startQuizSession(QuickQuizLength.twenty);

    expect(session, hasLength(20));
    expect(session.map((question) => question.id).toSet(), hasLength(20));
  });

  blocTest<QuizBloc, QuizState>(
    'exposes a recoverable failure when local content cannot be loaded',
    build: () => _buildBloc(
      StartQuizSession(
        repository: _FailingQuestionRepository(),
        selector: const QuizQuestionSelector(),
        seedGenerator: () => 42,
      ),
      bestScoreRepository,
      sessionTimer,
    ),
    act: (bloc) => bloc.add(const QuizStarted()),
    expect: () => [isA<QuizLoading>(), isA<QuizFailure>()],
    errors: () => [isA<FormatException>()],
    verify: (_) => expect(sessionTimer.startCount, 0),
  );

  blocTest<QuizBloc, QuizState>(
    'still shows the current result when saving the best score fails',
    build: () => _buildBloc(
      startQuizSession,
      _FailingSaveBestScoreRepository({QuickQuizLength.ten: 5}),
      sessionTimer,
    ),
    seed: () => const QuizInitial(bestScore: 5),
    act: (bloc) async {
      bloc.add(const QuizStarted());
      await Future<void>.delayed(Duration.zero);
      await _completePerfectSession(bloc);
    },
    verify: (bloc) {
      final completed = bloc.state as QuizCompleted;
      expect(completed.score, 10);
      expect(completed.bestScore, 5);
      expect(completed.duration, const Duration(minutes: 1, seconds: 23));
    },
    errors: () => [isA<StateError>()],
  );

  test('starts a new session without attempts from the previous one', () async {
    final bloc = _buildBloc(
      startQuizSession,
      bestScoreRepository,
      sessionTimer,
    );
    addTearDown(bloc.close);
    bloc.add(const QuizLengthSelected(QuickQuizLength.five));
    await Future<void>.delayed(Duration.zero);
    bloc.add(const QuizStarted());
    await Future<void>.delayed(Duration.zero);
    await _completePerfectSession(bloc);
    expect((bloc.state as QuizCompleted).attempts, hasLength(5));

    bloc.add(const QuizRestarted());
    await Future<void>.delayed(Duration.zero);

    final restarted = bloc.state as QuizQuestionReady;
    expect(restarted.currentNumber, 1);
    expect(restarted.totalQuestions, 5);
    expect(restarted.length, QuickQuizLength.five);
    expect(restarted.attempts, isEmpty);
    expect(sessionTimer.startCount, 2);
    expect(sessionTimer.stopCount, 1);
  });
}

QuizBloc _buildBloc(
  StartQuizSession startQuizSession,
  BestScoreRepository bestScoreRepository,
  QuizSessionTimer sessionTimer, {
  PausedQuizSessionRepository? pausedSessionRepository,
}) {
  return QuizBloc(
    startQuizSession,
    LoadBestScore(bestScoreRepository),
    UpdateBestScore(bestScoreRepository),
    sessionTimer: sessionTimer,
    pausedSessionRepository: pausedSessionRepository,
  );
}

Future<void> _completePerfectSession(QuizBloc bloc) async {
  final totalQuestions = (bloc.state as QuizQuestionReady).totalQuestions;
  for (var index = 0; index < totalQuestions; index++) {
    final ready = bloc.state as QuizQuestionReady;
    bloc.add(QuizAnswerSubmitted(ready.question.correctOptionId));
    await Future<void>.delayed(Duration.zero);
    bloc.add(const QuizNextRequested());
    await Future<void>.delayed(Duration.zero);
  }
}

final class _MemoryPausedQuizSessionRepository
    implements PausedQuizSessionRepository {
  _MemoryPausedQuizSessionRepository(this.session);

  PausedQuizSession? session;

  @override
  Future<void> clear() async {
    session = null;
  }

  @override
  Future<PausedQuizSession?> load() async => session;

  @override
  Future<void> save(PausedQuizSession value) async {
    session = value;
  }
}

final class _FakeQuestionRepository implements QuestionRepository {
  const _FakeQuestionRepository(this.questions);

  final List<Question> questions;

  @override
  Future<List<Question>> loadActiveQuestions() async => questions;
}

final class _FailingQuestionRepository implements QuestionRepository {
  @override
  Future<List<Question>> loadActiveQuestions() {
    throw const FormatException('Invalid local content');
  }
}

class _MemoryBestScoreRepository implements BestScoreRepository {
  _MemoryBestScoreRepository(this.scores);

  final Map<QuickQuizLength, int> scores;
  final savedScores = <(QuickQuizLength, int)>[];

  @override
  Future<int> loadBestScore(QuickQuizLength length) async =>
      scores[length] ?? 0;

  @override
  Future<void> saveBestScore(QuickQuizLength length, int score) async {
    scores[length] = score;
    savedScores.add((length, score));
  }
}

final class _FailingSaveBestScoreRepository extends _MemoryBestScoreRepository {
  _FailingSaveBestScoreRepository(super.scores);

  @override
  Future<void> saveBestScore(QuickQuizLength length, int score) {
    throw StateError('Storage unavailable');
  }
}

final class _SeedSequence {
  _SeedSequence(this._seeds);

  final List<int> _seeds;
  var _index = 0;

  int next() => _seeds[_index++];
}

final class _FakeQuizSessionTimer implements QuizSessionTimer {
  _FakeQuizSessionTimer(this._durations);

  final List<Duration> _durations;
  var _durationIndex = 0;
  var startCount = 0;
  var pauseCount = 0;
  var resumeCount = 0;
  var stopCount = 0;

  @override
  void start() {
    startCount++;
  }

  @override
  void pause() {
    pauseCount++;
  }

  @override
  void resume() {
    resumeCount++;
  }

  @override
  Duration stop() {
    stopCount++;
    return _durations[_durationIndex++];
  }
}
