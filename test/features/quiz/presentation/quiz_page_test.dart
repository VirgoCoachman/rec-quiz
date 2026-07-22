import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/app/app.dart';
import 'package:rec_quiz/features/quiz/domain/best_score_repository.dart';
import 'package:rec_quiz/features/quiz/domain/question.dart';
import 'package:rec_quiz/features/quiz/domain/question_repository.dart';
import 'package:rec_quiz/features/quiz/domain/quiz_question_selector.dart';

import '../quiz_test_data.dart';

void main() {
  final questions = buildQuizQuestions();

  testWidgets('completes the accessible ten-question quiz', (tester) async {
    final semantics = tester.ensureSemantics();
    final seeds = _SeedSequence([42, 99]);
    final bestScoreRepository = _MemoryBestScoreRepository(7);
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
        seedGenerator: seeds.next,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quiz REC'), findsOneWidget);
    expect(find.text('Meilleur score : 7/10'), findsOneWidget);
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

    await tester.tap(find.text('Recommencer'));
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
        seedGenerator: () => 99,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Meilleur score : 10/10'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('offers a retry when bundled content cannot be loaded', (
    tester,
  ) async {
    await tester.pumpWidget(
      RecQuizApp(
        questionRepository: _FailingQuestionRepository(),
        bestScoreRepository: _MemoryBestScoreRepository(0),
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

    await tester.pumpWidget(
      RecQuizApp(
        questionRepository: _FakeQuestionRepository(questions),
        bestScoreRepository: _MemoryBestScoreRepository(0),
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

    final nextButton = find.text('Question suivante');
    await tester.ensureVisible(nextButton);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();
    expect(find.text('Question 2 sur 10'), findsOneWidget);
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
  _MemoryBestScoreRepository(this.score);

  int score;

  @override
  Future<int> loadBestScore() async => score;

  @override
  Future<void> saveBestScore(int score) async {
    this.score = score;
  }
}

final class _SeedSequence {
  _SeedSequence(this._seeds);

  final List<int> _seeds;
  var _index = 0;

  int next() => _seeds[_index++];
}
