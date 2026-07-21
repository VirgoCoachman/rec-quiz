import 'package:flutter_test/flutter_test.dart';
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

  test(
    'bundled content starts at 1 Chronicles 10 and excludes genealogies',
    () async {
      final repository = BundledQuestionRepository();

      final question = await repository.loadFirstActiveQuestion();

      expect(question.biblicalReference, startsWith('1 Chroniques 10'));
      expect(question.prompt.toLowerCase(), isNot(contains('généalog')));
      expect(question.explanation.toLowerCase(), isNot(contains('généalog')));
      expect(question.subject.toLowerCase(), isNot(contains('généalog')));
      expect(
        question.options.map((option) => option.label.toLowerCase()),
        everyElement(isNot(contains('généalog'))),
      );
    },
  );
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
