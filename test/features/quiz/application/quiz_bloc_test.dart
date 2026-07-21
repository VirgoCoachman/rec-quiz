import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/features/quiz/application/quiz_bloc.dart';
import 'package:rec_quiz/features/quiz/application/start_quiz_session.dart';
import 'package:rec_quiz/features/quiz/domain/question.dart';
import 'package:rec_quiz/features/quiz/domain/question_repository.dart';
import 'package:rec_quiz/features/quiz/domain/quiz_question_selector.dart';

import '../quiz_test_data.dart';

void main() {
  late List<Question> questions;
  late QuestionRepository repository;
  late StartQuizSession startQuizSession;
  late List<Question> expectedOrder;

  setUp(() {
    questions = buildQuizQuestions();
    repository = _FakeQuestionRepository(questions);
    startQuizSession = StartQuizSession(
      repository: repository,
      selector: const QuizQuestionSelector(),
      seedGenerator: () => 42,
    );
    expectedOrder = const QuizQuestionSelector().select(
      questions: questions,
      count: 10,
      seed: 42,
    );
  });

  blocTest<QuizBloc, QuizState>(
    'loads a ten-question session when the quiz starts',
    build: () => QuizBloc(startQuizSession),
    act: (bloc) => bloc.add(const QuizStarted()),
    expect: () => [
      isA<QuizLoading>(),
      isA<QuizQuestionReady>()
          .having(
            (state) => state.question.id,
            'question id',
            expectedOrder[0].id,
          )
          .having((state) => state.currentNumber, 'current number', 1)
          .having((state) => state.totalQuestions, 'total', 10),
    ],
  );

  blocTest<QuizBloc, QuizState>(
    'evaluates one answer and ignores subsequent submissions',
    build: () => QuizBloc(startQuizSession),
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
          ),
    ],
  );

  blocTest<QuizBloc, QuizState>(
    'moves to the next question and preserves the accumulated score',
    build: () => QuizBloc(startQuizSession),
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
          .having((state) => state.hasAnswered, 'answered', isFalse),
    ],
  );

  blocTest<QuizBloc, QuizState>(
    'completes the session after ten answered questions',
    build: () => QuizBloc(startQuizSession),
    act: (bloc) async {
      bloc.add(const QuizStarted());
      await Future<void>.delayed(Duration.zero);

      for (var index = 0; index < 10; index++) {
        final ready = bloc.state as QuizQuestionReady;
        bloc.add(QuizAnswerSubmitted(ready.question.correctOptionId));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const QuizNextRequested());
        await Future<void>.delayed(Duration.zero);
      }
    },
    verify: (bloc) {
      final completed = bloc.state as QuizCompleted;
      expect(completed.score, 10);
      expect(completed.totalQuestions, 10);
    },
  );

  test('uses a fresh injected seed for every new session', () async {
    final seeds = _SeedSequence([1, 2]);
    final useCase = StartQuizSession(
      repository: repository,
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
    build: () => QuizBloc(
      StartQuizSession(
        repository: _FailingQuestionRepository(),
        selector: const QuizQuestionSelector(),
        seedGenerator: () => 42,
      ),
    ),
    act: (bloc) => bloc.add(const QuizStarted()),
    expect: () => [isA<QuizLoading>(), isA<QuizFailure>()],
    errors: () => [isA<FormatException>()],
  );
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

final class _SeedSequence {
  _SeedSequence(this._seeds);

  final List<int> _seeds;
  var _index = 0;

  int next() => _seeds[_index++];
}
