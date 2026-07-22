import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/features/quiz/application/load_best_score.dart';
import 'package:rec_quiz/features/quiz/application/quiz_bloc.dart';
import 'package:rec_quiz/features/quiz/application/start_quiz_session.dart';
import 'package:rec_quiz/features/quiz/application/update_best_score.dart';
import 'package:rec_quiz/features/quiz/domain/best_score_repository.dart';
import 'package:rec_quiz/features/quiz/domain/question.dart';
import 'package:rec_quiz/features/quiz/domain/question_repository.dart';
import 'package:rec_quiz/features/quiz/domain/quiz_question_selector.dart';

import '../quiz_test_data.dart';

void main() {
  late List<Question> questions;
  late QuestionRepository questionRepository;
  late StartQuizSession startQuizSession;
  late List<Question> expectedOrder;
  late _MemoryBestScoreRepository bestScoreRepository;

  setUp(() {
    questions = buildQuizQuestions();
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
    bestScoreRepository = _MemoryBestScoreRepository(0);
  });

  blocTest<QuizBloc, QuizState>(
    'loads the persisted best score during initialization',
    build: () {
      bestScoreRepository.score = 7;
      return _buildBloc(startQuizSession, bestScoreRepository);
    },
    act: (bloc) => bloc.add(const QuizInitialized()),
    expect: () => [
      isA<QuizInitial>().having((state) => state.bestScore, 'best score', 7),
    ],
  );

  blocTest<QuizBloc, QuizState>(
    'loads a ten-question session and carries the best score',
    build: () => _buildBloc(startQuizSession, bestScoreRepository),
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
          .having((state) => state.bestScore, 'best score', 6),
    ],
  );

  blocTest<QuizBloc, QuizState>(
    'evaluates one answer and ignores subsequent submissions',
    build: () => _buildBloc(startQuizSession, bestScoreRepository),
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
    build: () => _buildBloc(startQuizSession, bestScoreRepository),
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
    build: () => _buildBloc(startQuizSession, bestScoreRepository),
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
      expect(completed.attempts, hasLength(10));
      expect(
        completed.attempts.map((attempt) => attempt.questionId),
        expectedOrder.map((question) => question.id),
      );
      expect(
        () => completed.attempts.add(completed.attempts.first),
        throwsUnsupportedError,
      );
      expect(bestScoreRepository.savedScores, [10]);
    },
  );

  test('uses a fresh injected seed for every new session', () async {
    final seeds = _SeedSequence([1, 2]);
    final useCase = StartQuizSession(
      repository: questionRepository,
      selector: const QuizQuestionSelector(),
      seedGenerator: seeds.next,
    );

    final first = await useCase();
    final second = await useCase();

    expect(
      first.map((question) => question.id),
      isNot(second.map((question) => question.id)),
    );
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
    ),
    act: (bloc) => bloc.add(const QuizStarted()),
    expect: () => [isA<QuizLoading>(), isA<QuizFailure>()],
    errors: () => [isA<FormatException>()],
  );

  blocTest<QuizBloc, QuizState>(
    'still shows the current result when saving the best score fails',
    build: () =>
        _buildBloc(startQuizSession, _FailingSaveBestScoreRepository(5)),
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
    },
    errors: () => [isA<StateError>()],
  );

  test('starts a new session without attempts from the previous one', () async {
    final bloc = _buildBloc(startQuizSession, bestScoreRepository);
    addTearDown(bloc.close);
    bloc.add(const QuizStarted());
    await Future<void>.delayed(Duration.zero);
    await _completePerfectSession(bloc);
    expect((bloc.state as QuizCompleted).attempts, hasLength(10));

    bloc.add(const QuizRestarted());
    await Future<void>.delayed(Duration.zero);

    final restarted = bloc.state as QuizQuestionReady;
    expect(restarted.currentNumber, 1);
    expect(restarted.attempts, isEmpty);
  });
}

QuizBloc _buildBloc(
  StartQuizSession startQuizSession,
  BestScoreRepository bestScoreRepository,
) {
  return QuizBloc(
    startQuizSession,
    LoadBestScore(bestScoreRepository),
    UpdateBestScore(bestScoreRepository),
  );
}

Future<void> _completePerfectSession(QuizBloc bloc) async {
  for (var index = 0; index < 10; index++) {
    final ready = bloc.state as QuizQuestionReady;
    bloc.add(QuizAnswerSubmitted(ready.question.correctOptionId));
    await Future<void>.delayed(Duration.zero);
    bloc.add(const QuizNextRequested());
    await Future<void>.delayed(Duration.zero);
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
  _MemoryBestScoreRepository(this.score);

  int score;
  final savedScores = <int>[];

  @override
  Future<int> loadBestScore() async => score;

  @override
  Future<void> saveBestScore(int score) async {
    this.score = score;
    savedScores.add(score);
  }
}

final class _FailingSaveBestScoreRepository extends _MemoryBestScoreRepository {
  _FailingSaveBestScoreRepository(super.score);

  @override
  Future<void> saveBestScore(int score) {
    throw StateError('Storage unavailable');
  }
}

final class _SeedSequence {
  _SeedSequence(this._seeds);

  final List<int> _seeds;
  var _index = 0;

  int next() => _seeds[_index++];
}
