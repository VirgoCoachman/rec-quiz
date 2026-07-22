import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/app/app.dart';
import 'package:rec_quiz/core/audio/quiz_feedback_player.dart';
import 'package:rec_quiz/features/quiz/domain/best_score_repository.dart';
import 'package:rec_quiz/features/quiz/domain/question.dart';
import 'package:rec_quiz/features/quiz/domain/question_repository.dart';
import 'package:rec_quiz/features/quiz/domain/quiz_question_selector.dart';
import 'package:rec_quiz/features/quiz/domain/quiz_session_timer.dart';
import 'package:rec_quiz/features/quiz/domain/quick_quiz_length.dart';
import 'package:rec_quiz/features/settings/domain/sound_settings_repository.dart';

import '../quiz_test_data.dart';

void main() {
  final questions = buildQuizQuestions(count: 20);

  testWidgets('completes the accessible ten-question quiz', (tester) async {
    final semantics = tester.ensureSemantics();
    final seeds = _SeedSequence([42, 99]);
    final bestScoreRepository = _MemoryBestScoreRepository({
      QuickQuizLength.ten: 7,
    });
    final soundRepository = _MemorySoundSettingsRepository(true);
    final feedbackPlayer = _RecordingQuizFeedbackPlayer();
    final sessionTimer = _FakeQuizSessionTimer(
      const Duration(minutes: 1, seconds: 23),
    );
    final firstOrder = const QuizQuestionSelector().select(
      questions: questions,
      count: 10,
      seed: 42,
    );
    final secondOrder = const QuizQuestionSelector().select(
      questions: questions,
      count: 10,
      seed: 99,
    );

    await tester.pumpWidget(
      RecQuizApp(
        questionRepository: _FakeQuestionRepository(questions),
        bestScoreRepository: bestScoreRepository,
        soundSettingsRepository: soundRepository,
        quizFeedbackPlayer: feedbackPlayer,
        quizSessionTimer: sessionTimer,
        seedGenerator: seeds.next,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quiz REC'), findsOneWidget);
    expect(find.text('Nombre de questions'), findsOneWidget);
    expect(find.bySemanticsLabel('Quiz de 5 questions'), findsOneWidget);
    expect(find.bySemanticsLabel('Quiz de 10 questions'), findsOneWidget);
    expect(find.bySemanticsLabel('Quiz de 20 questions'), findsOneWidget);
    expect(find.text('Meilleur score : 7/10'), findsOneWidget);
    expect(find.bySemanticsLabel('Désactiver le son'), findsOneWidget);
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    for (var index = 0; index < firstOrder.length; index++) {
      final question = firstOrder[index];
      expect(find.text('Question ${index + 1} sur 10'), findsOneWidget);
      expect(find.text(question.prompt), findsOneWidget);
      expect(
        find.bySemanticsLabel('Réponse : ${question.correctOption.label}'),
        findsOneWidget,
      );

      await tester.tap(find.text(question.correctOption.label));
      await tester.pumpAndSettle();

      expect(find.text('Bonne réponse !'), findsOneWidget);
      expect(find.text(question.explanation), findsOneWidget);
      expect(find.text(question.biblicalReference), findsOneWidget);

      final actionLabel = index == firstOrder.length - 1
          ? 'Voir mon résultat'
          : 'Question suivante';
      final actionButton = find.text(actionLabel);
      await tester.ensureVisible(actionButton);
      await tester.pumpAndSettle();
      await tester.tap(actionButton);
      await tester.pumpAndSettle();
    }

    expect(find.text('Votre score : 10/10'), findsOneWidget);
    expect(find.text('Meilleur score : 10/10'), findsOneWidget);
    expect(find.text('Durée : 1 min 23 s'), findsOneWidget);
    expect(sessionTimer.startCount, 1);
    expect(sessionTimer.stopCount, 1);
    expect(find.text('Correction détaillée'), findsOneWidget);
    expect(find.text('réponse correcte'), findsNWidgets(10));
    expect(find.bySemanticsLabel('Revoir mes erreurs (0)'), findsNothing);
    for (var index = 0; index < firstOrder.length; index++) {
      final reviewCard = find.bySemanticsLabel(
        'Question ${index + 1} : réponse correcte',
      );
      expect(reviewCard, findsOneWidget);
      expect(
        find.descendant(
          of: reviewCard,
          matching: find.text(firstOrder[index].prompt),
        ),
        findsWidgets,
      );
    }
    expect(feedbackPlayer.correctAnswerCount, 10);
    expect(feedbackPlayer.incorrectAnswerCount, 0);

    final restartButton = find.text('Recommencer');
    await tester.ensureVisible(restartButton);
    await tester.tap(restartButton);
    await tester.pumpAndSettle();

    expect(find.text('Question 1 sur 10'), findsOneWidget);
    expect(find.text(secondOrder.first.prompt), findsOneWidget);
    expect(find.text('Bonne réponse !'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      RecQuizApp(
        questionRepository: _FakeQuestionRepository(questions),
        bestScoreRepository: bestScoreRepository,
        soundSettingsRepository: soundRepository,
        quizFeedbackPlayer: feedbackPlayer,
        seedGenerator: () => 99,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Meilleur score : 10/10'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('completes and restarts a selected five-question quiz', (
    tester,
  ) async {
    final ordered = const QuizQuestionSelector().select(
      questions: questions,
      count: 5,
      seed: 42,
    );

    await tester.pumpWidget(
      RecQuizApp(
        questionRepository: _FakeQuestionRepository(questions),
        bestScoreRepository: _MemoryBestScoreRepository({
          QuickQuizLength.five: 3,
        }),
        soundSettingsRepository: _MemorySoundSettingsRepository(false),
        quizFeedbackPlayer: _RecordingQuizFeedbackPlayer(),
        quizSessionTimer: _FakeQuizSessionTimer(const Duration(seconds: 35)),
        seedGenerator: () => 42,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Quiz de 5 questions'));
    await tester.pumpAndSettle();
    expect(find.text('Meilleur score : 3/5'), findsOneWidget);

    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    for (var index = 0; index < ordered.length; index++) {
      await tester.tap(find.text(ordered[index].correctOption.label));
      await tester.pumpAndSettle();
      final action = find.text(
        index == ordered.length - 1 ? 'Voir mon résultat' : 'Question suivante',
      );
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
    }

    expect(find.text('Votre score : 5/5'), findsOneWidget);
    expect(find.text('Meilleur score : 5/5'), findsOneWidget);
    expect(find.text('réponse correcte'), findsNWidgets(5));

    final restart = find.text('Recommencer');
    await tester.ensureVisible(restart);
    await tester.tap(restart);
    await tester.pumpAndSettle();
    expect(find.text('Question 1 sur 5'), findsOneWidget);
  });

  testWidgets('starts a selected twenty-question quiz', (tester) async {
    await tester.pumpWidget(
      RecQuizApp(
        questionRepository: _FakeQuestionRepository(questions),
        bestScoreRepository: _MemoryBestScoreRepository({
          QuickQuizLength.twenty: 18,
        }),
        soundSettingsRepository: _MemorySoundSettingsRepository(false),
        quizFeedbackPlayer: _RecordingQuizFeedbackPlayer(),
        seedGenerator: () => 42,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Quiz de 20 questions'));
    await tester.pumpAndSettle();
    expect(find.text('Meilleur score : 18/20'), findsOneWidget);

    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    expect(find.text('Question 1 sur 20'), findsOneWidget);
  });

  testWidgets('offers a retry when bundled content cannot be loaded', (
    tester,
  ) async {
    await tester.pumpWidget(
      RecQuizApp(
        questionRepository: _FailingQuestionRepository(),
        bestScoreRepository: _MemoryBestScoreRepository({}),
        soundSettingsRepository: _MemorySoundSettingsRepository(true),
        quizFeedbackPlayer: _RecordingQuizFeedbackPlayer(),
        seedGenerator: () => 42,
      ),
    );

    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    expect(find.text('Impossible de charger les questions.'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('shows feedback for an incorrect answer and keeps score zero', (
    tester,
  ) async {
    final ordered = const QuizQuestionSelector().select(
      questions: questions,
      count: 10,
      seed: 42,
    );
    final first = ordered.first;
    final incorrect = first.options.firstWhere(
      (option) => option.id != first.correctOptionId,
    );
    final feedbackPlayer = _RecordingQuizFeedbackPlayer();

    await tester.pumpWidget(
      RecQuizApp(
        questionRepository: _FakeQuestionRepository(questions),
        bestScoreRepository: _MemoryBestScoreRepository({}),
        soundSettingsRepository: _MemorySoundSettingsRepository(true),
        quizFeedbackPlayer: feedbackPlayer,
        seedGenerator: () => 42,
      ),
    );

    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(incorrect.label));
    await tester.pumpAndSettle();

    expect(find.text('Ce n’est pas la bonne réponse.'), findsOneWidget);
    expect(
      find.text('Bonne réponse : ${first.correctOption.label}'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(feedbackPlayer.correctAnswerCount, 0);
    expect(feedbackPlayer.incorrectAnswerCount, 1);

    final nextButton = find.text('Question suivante');
    await tester.ensureVisible(nextButton);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();
    expect(find.text('Question 2 sur 10'), findsOneWidget);
  });

  testWidgets('disables sound and restores the preference after restart', (
    tester,
  ) async {
    final soundRepository = _MemorySoundSettingsRepository(true);
    final feedbackPlayer = _RecordingQuizFeedbackPlayer();
    final firstQuestion = const QuizQuestionSelector()
        .select(questions: questions, count: 10, seed: 42)
        .first;

    await tester.pumpWidget(
      RecQuizApp(
        questionRepository: _FakeQuestionRepository(questions),
        bestScoreRepository: _MemoryBestScoreRepository({}),
        soundSettingsRepository: soundRepository,
        quizFeedbackPlayer: feedbackPlayer,
        seedGenerator: () => 42,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Désactiver le son'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Activer le son'), findsOneWidget);

    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(firstQuestion.correctOption.label));
    await tester.pumpAndSettle();

    expect(feedbackPlayer.correctAnswerCount, 0);
    expect(soundRepository.isEnabled, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      RecQuizApp(
        questionRepository: _FakeQuestionRepository(questions),
        bestScoreRepository: _MemoryBestScoreRepository({}),
        soundSettingsRepository: soundRepository,
        quizFeedbackPlayer: feedbackPlayer,
        seedGenerator: () => 42,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Activer le son'), findsOneWidget);
  });

  testWidgets('keeps the quiz usable when audio playback fails', (
    tester,
  ) async {
    final reportedErrors = <FlutterErrorDetails>[];
    final previousHandler = FlutterError.onError;
    FlutterError.onError = reportedErrors.add;
    addTearDown(() => FlutterError.onError = previousHandler);
    final firstQuestion = const QuizQuestionSelector()
        .select(questions: questions, count: 10, seed: 42)
        .first;

    await tester.pumpWidget(
      RecQuizApp(
        questionRepository: _FakeQuestionRepository(questions),
        bestScoreRepository: _MemoryBestScoreRepository({}),
        soundSettingsRepository: _MemorySoundSettingsRepository(true),
        quizFeedbackPlayer: _FailingQuizFeedbackPlayer(),
        seedGenerator: () => 42,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(firstQuestion.correctOption.label));
    await tester.pumpAndSettle();

    expect(find.text('Bonne réponse !'), findsOneWidget);
    expect(find.text('Question suivante'), findsOneWidget);
    expect(reportedErrors, hasLength(1));
  });

  testWidgets('shows the selected and correct answers in the final review', (
    tester,
  ) async {
    final ordered = const QuizQuestionSelector().select(
      questions: questions,
      count: 10,
      seed: 42,
    );
    final first = ordered.first;
    final incorrect = first.options.firstWhere(
      (option) => option.id != first.correctOptionId,
    );

    await tester.pumpWidget(
      RecQuizApp(
        questionRepository: _FakeQuestionRepository(questions),
        bestScoreRepository: _MemoryBestScoreRepository({}),
        soundSettingsRepository: _MemorySoundSettingsRepository(false),
        quizFeedbackPlayer: _RecordingQuizFeedbackPlayer(),
        seedGenerator: () => 42,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    for (var index = 0; index < ordered.length; index++) {
      final option = index == 0 ? incorrect : ordered[index].correctOption;
      await tester.tap(find.text(option.label));
      await tester.pumpAndSettle();
      final action = find.text(
        index == ordered.length - 1 ? 'Voir mon résultat' : 'Question suivante',
      );
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
    }

    expect(find.text('Votre score : 9/10'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Question 1 : réponse incorrecte'),
      findsOneWidget,
    );
    expect(find.text('réponse incorrecte'), findsOneWidget);
    expect(find.text('réponse correcte'), findsNWidgets(9));
    expect(find.text('Votre réponse : ${incorrect.label}'), findsOneWidget);
    expect(
      find.text('Bonne réponse : ${first.correctOption.label}'),
      findsOneWidget,
    );
    expect(find.text(first.explanation), findsOneWidget);
    expect(find.text(first.biblicalReference), findsOneWidget);
  });

  testWidgets('reviews only quick quiz mistakes and returns to a quick quiz', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final seeds = _SeedSequence([42, 99]);
    final firstOrder = const QuizQuestionSelector().select(
      questions: questions,
      count: 10,
      seed: 42,
    );
    final secondOrder = const QuizQuestionSelector().select(
      questions: questions,
      count: 10,
      seed: 99,
    );
    final missedQuestion = firstOrder.first;
    final incorrectOption = missedQuestion.options.firstWhere(
      (option) => option.id != missedQuestion.correctOptionId,
    );

    await tester.pumpWidget(
      RecQuizApp(
        questionRepository: _FakeQuestionRepository(questions),
        bestScoreRepository: _MemoryBestScoreRepository({}),
        soundSettingsRepository: _MemorySoundSettingsRepository(false),
        quizFeedbackPlayer: _RecordingQuizFeedbackPlayer(),
        quizSessionTimer: _FakeQuizSessionTimer(const Duration(seconds: 30)),
        seedGenerator: seeds.next,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    for (var index = 0; index < firstOrder.length; index++) {
      final selectedOption = index == 0
          ? incorrectOption
          : firstOrder[index].correctOption;
      await tester.tap(find.text(selectedOption.label));
      await tester.pumpAndSettle();
      final action = find.text(
        index == firstOrder.length - 1
            ? 'Voir mon résultat'
            : 'Question suivante',
      );
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
    }

    expect(find.text('Votre score : 9/10'), findsOneWidget);
    final reviewButton = find.bySemanticsLabel('Revoir mes erreurs (1)');
    expect(reviewButton, findsOneWidget);
    await tester.ensureVisible(reviewButton);
    await tester.tap(reviewButton);
    await tester.pumpAndSettle();

    expect(find.text('Question 1 sur 1'), findsOneWidget);
    expect(find.text(missedQuestion.prompt), findsOneWidget);
    await tester.tap(find.text(missedQuestion.correctOption.label));
    await tester.pumpAndSettle();
    final showResult = find.text('Voir mon résultat');
    await tester.ensureVisible(showResult);
    await tester.tap(showResult);
    await tester.pumpAndSettle();

    expect(find.text('Révision terminée'), findsOneWidget);
    expect(find.text('Votre score : 1/1'), findsOneWidget);
    expect(find.textContaining('Meilleur score'), findsNothing);
    expect(find.bySemanticsLabel('Revoir mes erreurs (1)'), findsNothing);
    final newQuickQuiz = find.text('Nouveau quiz rapide');
    await tester.ensureVisible(newQuickQuiz);
    await tester.tap(newQuickQuiz);
    await tester.pumpAndSettle();

    expect(find.text('Question 1 sur 10'), findsOneWidget);
    expect(find.text(secondOrder.first.prompt), findsOneWidget);
    semantics.dispose();
  });
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

final class _MemoryBestScoreRepository implements BestScoreRepository {
  _MemoryBestScoreRepository(this.scores);

  final Map<QuickQuizLength, int> scores;

  @override
  Future<int> loadBestScore(QuickQuizLength length) async =>
      scores[length] ?? 0;

  @override
  Future<void> saveBestScore(QuickQuizLength length, int score) async {
    scores[length] = score;
  }
}

final class _MemorySoundSettingsRepository implements SoundSettingsRepository {
  _MemorySoundSettingsRepository(this.isEnabled);

  bool isEnabled;

  @override
  Future<bool> loadSoundEnabled() async => isEnabled;

  @override
  Future<void> saveSoundEnabled(bool isEnabled) async {
    this.isEnabled = isEnabled;
  }
}

class _RecordingQuizFeedbackPlayer implements QuizFeedbackPlayer {
  var correctAnswerCount = 0;
  var incorrectAnswerCount = 0;

  @override
  Future<void> playCorrectAnswer() async {
    correctAnswerCount++;
  }

  @override
  Future<void> playIncorrectAnswer() async {
    incorrectAnswerCount++;
  }
}

final class _FailingQuizFeedbackPlayer extends _RecordingQuizFeedbackPlayer {
  @override
  Future<void> playCorrectAnswer() {
    throw StateError('Audio unavailable');
  }
}

final class _SeedSequence {
  _SeedSequence(this._seeds);

  final List<int> _seeds;
  var _index = 0;

  int next() => _seeds[_index++];
}

final class _FakeQuizSessionTimer implements QuizSessionTimer {
  _FakeQuizSessionTimer(this.elapsed);

  final Duration elapsed;
  var startCount = 0;
  var stopCount = 0;

  @override
  void start() {
    startCount++;
  }

  @override
  Duration stop() {
    stopCount++;
    return elapsed;
  }
}
