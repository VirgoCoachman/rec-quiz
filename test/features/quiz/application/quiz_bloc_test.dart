import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/features/quiz/application/load_quiz_question.dart';
import 'package:rec_quiz/features/quiz/application/quiz_bloc.dart';
import 'package:rec_quiz/features/quiz/domain/question.dart';
import 'package:rec_quiz/features/quiz/domain/question_repository.dart';

void main() {
  late Question question;
  late QuestionRepository repository;

  setUp(() {
    question = _buildQuestion();
    repository = _FakeQuestionRepository(question);
  });

  blocTest<QuizBloc, QuizState>(
    'loads the local question when the quiz starts',
    build: () => QuizBloc(LoadQuizQuestion(repository)),
    act: (bloc) => bloc.add(const QuizStarted()),
    expect: () => [
      isA<QuizLoading>(),
      isA<QuizQuestionReady>().having(
        (state) => state.question.id,
        'question id',
        question.id,
      ),
    ],
  );

  blocTest<QuizBloc, QuizState>(
    'evaluates one answer and ignores subsequent submissions',
    build: () => QuizBloc(LoadQuizQuestion(repository)),
    act: (bloc) async {
      bloc.add(const QuizStarted());
      await Future<void>.delayed(Duration.zero);
      bloc
        ..add(const QuizAnswerSubmitted('infidelity'))
        ..add(const QuizAnswerSubmitted('temple'));
    },
    expect: () => [
      isA<QuizLoading>(),
      isA<QuizQuestionReady>(),
      isA<QuizQuestionReady>()
          .having((state) => state.hasAnswered, 'answered', isTrue)
          .having(
            (state) => state.evaluation?.selectedOptionId,
            'selected option',
            'infidelity',
          )
          .having(
            (state) => state.evaluation?.isCorrect,
            'correct answer',
            isTrue,
          ),
    ],
  );

  blocTest<QuizBloc, QuizState>(
    'shows the final score after an answered question',
    build: () => QuizBloc(LoadQuizQuestion(repository)),
    act: (bloc) async {
      bloc.add(const QuizStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const QuizAnswerSubmitted('infidelity'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const QuizResultRequested());
    },
    expect: () => [
      isA<QuizLoading>(),
      isA<QuizQuestionReady>(),
      isA<QuizQuestionReady>(),
      isA<QuizCompleted>()
          .having((state) => state.score, 'score', 1)
          .having((state) => state.totalQuestions, 'total', 1),
    ],
  );

  blocTest<QuizBloc, QuizState>(
    'exposes a recoverable failure when local content cannot be loaded',
    build: () => QuizBloc(LoadQuizQuestion(_FailingQuestionRepository())),
    act: (bloc) => bloc.add(const QuizStarted()),
    expect: () => [isA<QuizLoading>(), isA<QuizFailure>()],
    errors: () => [isA<FormatException>()],
  );
}

final class _FakeQuestionRepository implements QuestionRepository {
  _FakeQuestionRepository(this.question);

  final Question question;

  @override
  Future<Question> loadFirstActiveQuestion() async => question;
}

final class _FailingQuestionRepository implements QuestionRepository {
  @override
  Future<Question> loadFirstActiveQuestion() {
    throw const FormatException('Invalid local content');
  }
}

Question _buildQuestion() {
  return Question(
    id: 'saul-death-reason',
    prompt: 'Pourquoi Saül mourut-il selon 1 Chroniques 10 ?',
    options: [
      QuestionOption(id: 'infidelity', label: 'À cause de son infidélité'),
      QuestionOption(id: 'temple', label: 'Parce qu’il refusa le Temple'),
      QuestionOption(id: 'division', label: 'Parce qu’il divisa le royaume'),
    ],
    correctOptionId: 'infidelity',
    explanation: 'Saül mourut à cause de son infidélité envers l’Éternel.',
    biblicalReference: '1 Chroniques 10:13-14',
    difficulty: QuestionDifficulty.easy,
    theme: 'fidelite',
    subject: 'Saül',
    languageCode: 'fr',
    contentVersion: 1,
    isActive: true,
  );
}
