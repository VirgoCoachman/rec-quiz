import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/app/app.dart';
import 'package:rec_quiz/features/quiz/domain/question.dart';
import 'package:rec_quiz/features/quiz/domain/question_repository.dart';

void main() {
  testWidgets('completes the accessible one-question learning loop', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      RecQuizApp(questionRepository: _FakeQuestionRepository(_question)),
    );

    expect(find.text('Quiz REC'), findsOneWidget);
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    expect(find.text(_question.prompt), findsOneWidget);
    expect(
      find.bySemanticsLabel('Réponse : À cause de son infidélité'),
      findsOneWidget,
    );

    await tester.tap(find.text('À cause de son infidélité'));
    await tester.pumpAndSettle();

    expect(find.text('Bonne réponse !'), findsOneWidget);
    expect(find.text(_question.explanation), findsOneWidget);
    expect(find.text(_question.biblicalReference), findsOneWidget);

    final showResultButton = find.text('Voir mon résultat');
    await tester.ensureVisible(showResultButton);
    await tester.pumpAndSettle();
    await tester.tap(showResultButton);
    await tester.pumpAndSettle();

    expect(find.text('Votre score : 1/1'), findsOneWidget);

    await tester.tap(find.text('Recommencer'));
    await tester.pumpAndSettle();

    expect(find.text(_question.prompt), findsOneWidget);
    expect(find.text('Bonne réponse !'), findsNothing);
    semantics.dispose();
  });

  testWidgets('offers a retry when bundled content cannot be loaded', (
    tester,
  ) async {
    await tester.pumpWidget(
      RecQuizApp(questionRepository: _FailingQuestionRepository()),
    );

    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    expect(find.text('Impossible de charger la question.'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('shows textual and visual feedback for an incorrect answer', (
    tester,
  ) async {
    await tester.pumpWidget(
      RecQuizApp(questionRepository: _FakeQuestionRepository(_question)),
    );

    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Parce qu’il refusa le Temple'));
    await tester.pumpAndSettle();

    expect(find.text('Ce n’est pas la bonne réponse.'), findsOneWidget);
    expect(
      find.text('Bonne réponse : À cause de son infidélité'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });
}

final Question _question = Question(
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

final class _FakeQuestionRepository implements QuestionRepository {
  const _FakeQuestionRepository(this.question);

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
