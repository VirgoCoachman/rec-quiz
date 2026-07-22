import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/features/quiz/domain/question.dart';
import 'package:rec_quiz/features/quiz/infrastructure/bundled_question_repository.dart';
import 'package:rec_quiz/features/quiz/infrastructure/question_dto.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuestionDto', () {
    test('maps valid external data to a domain question', () {
      final question = QuestionDto.fromJson(_validJson).toDomain();

      expect(question.id, 'fr-1ch-10-saul-infidelity-v1');
      expect(question.correctOption.id, 'infidelity');
      expect(question.biblicalReference, '1 Chroniques 10:13-14');
    });

    test('reports malformed external data as a format error', () {
      final malformed = Map<String, Object?>.from(_validJson)
        ..['correctOptionId'] = 'missing';

      expect(
        () => QuestionDto.fromJson(malformed).toDomain(),
        throwsFormatException,
      );
    });
  });

  test('bundled content is broad, diverse, and excludes genealogies', () async {
    final repository = BundledQuestionRepository();

    final questions = await repository.loadActiveQuestions();

    expect(questions.length, greaterThanOrEqualTo(20));
    expect(
      questions.map((question) => question.id).toSet(),
      hasLength(questions.length),
    );
    expect(questions.first.biblicalReference, startsWith('1 Chroniques 10'));
    expect(
      questions.map((question) => question.difficulty).toSet(),
      QuestionDifficulty.values.toSet(),
    );
    expect(
      questions.map((question) => question.subject).toSet(),
      containsAll(<String>[
        'Abija',
        'Joram',
        'Athalie',
        'Joas',
        'Ozias',
        'Jotham',
        'Achaz',
        'Amon',
        'Derniers rois de Juda',
        'Cyrus',
      ]),
    );
    expect(
      questions
          .expand((question) sync* {
            yield question.prompt;
            yield question.explanation;
            yield question.subject;
            yield* question.options.map((option) => option.label);
          })
          .map((text) => text.toLowerCase()),
      everyElement(
        allOf(
          isNot(contains('généalog')),
          isNot(contains('1 chroniques 1 à 9')),
        ),
      ),
    );
  });

  test('rejects an unsupported seed schema version', () async {
    final repository = BundledQuestionRepository(
      assetTextLoader: (_) async => jsonEncode({
        'schemaVersion': 2,
        'questions': [_validJson],
      }),
    );

    expect(repository.loadActiveQuestions(), throwsFormatException);
  });

  test('rejects duplicate question identifiers', () async {
    final repository = BundledQuestionRepository(
      assetTextLoader: (_) async => jsonEncode({
        'schemaVersion': 1,
        'questions': [_validJson, _validJson],
      }),
    );

    expect(repository.loadActiveQuestions(), throwsFormatException);
  });
}

final Map<String, Object?> _validJson = {
  'id': 'fr-1ch-10-saul-infidelity-v1',
  'prompt': 'Pourquoi Saül mourut-il selon 1 Chroniques 10 ?',
  'options': [
    {'id': 'infidelity', 'label': 'À cause de son infidélité'},
    {'id': 'temple', 'label': 'Parce qu’il refusa de bâtir le Temple'},
    {'id': 'division', 'label': 'Parce qu’il divisa le royaume'},
  ],
  'correctOptionId': 'infidelity',
  'explanation': 'Saül mourut à cause de son infidélité envers l’Éternel.',
  'biblicalReference': '1 Chroniques 10:13-14',
  'difficulty': 'easy',
  'theme': 'fidelite',
  'subject': 'Saül',
  'languageCode': 'fr',
  'contentVersion': 1,
  'isActive': true,
};
