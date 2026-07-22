import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/features/quiz/domain/question.dart';

void main() {
  group('Question', () {
    test('accepts a valid question with at least three unique options', () {
      final question = _buildQuestion();

      expect(question.id, 'saul-death-reason');
      expect(question.options, hasLength(3));
      expect(question.correctOption.label, 'À cause de son infidélité');
    });

    test('rejects a question with fewer than three options', () {
      expect(
        () => Question(
          id: 'invalid-question',
          prompt: 'Question invalide',
          options: [
            QuestionOption(id: 'a', label: 'A'),
            QuestionOption(id: 'b', label: 'B'),
          ],
          correctOptionId: 'a',
          explanation: 'Explication',
          biblicalReference: '1 Chroniques 10:13-14',
          difficulty: QuestionDifficulty.easy,
          theme: 'fidelite',
          subject: 'Saül',
          languageCode: 'fr',
          contentVersion: 1,
          isActive: true,
        ),
        throwsArgumentError,
      );
    });

    test('rejects a correct option identifier absent from the options', () {
      expect(
        () => _buildQuestion(correctOptionId: 'missing'),
        throwsArgumentError,
      );
    });

    test('rejects duplicate option identifiers', () {
      expect(
        () => _buildQuestion(
          options: [
            QuestionOption(id: 'same', label: 'Première réponse'),
            QuestionOption(id: 'same', label: 'Deuxième réponse'),
            QuestionOption(id: 'third', label: 'Troisième réponse'),
          ],
          correctOptionId: 'same',
        ),
        throwsArgumentError,
      );
    });

    test('rejects duplicate option labels', () {
      expect(
        () => _buildQuestion(
          options: [
            QuestionOption(id: 'first', label: 'Même réponse'),
            QuestionOption(id: 'second', label: 'même réponse'),
            QuestionOption(id: 'third', label: 'Autre réponse'),
          ],
          correctOptionId: 'first',
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty option content and non-positive versions', () {
      expect(
        () => QuestionOption(id: ' ', label: 'Réponse'),
        throwsArgumentError,
      );
      expect(() => _buildQuestion(contentVersion: 0), throwsArgumentError);
    });

    test('evaluates correct and incorrect answers', () {
      final question = _buildQuestion();

      final correct = question.evaluateAnswer('infidelity');
      final incorrect = question.evaluateAnswer('temple');

      expect(correct.isCorrect, isTrue);
      expect(correct.score, 1);
      expect(incorrect.isCorrect, isFalse);
      expect(incorrect.score, 0);
    });

    test('rejects an answer that is not one of the available options', () {
      final question = _buildQuestion();

      expect(() => question.evaluateAnswer('unknown'), throwsArgumentError);
    });
  });
}

Question _buildQuestion({
  String correctOptionId = 'infidelity',
  List<QuestionOption>? options,
  int contentVersion = 1,
}) {
  return Question(
    id: 'saul-death-reason',
    prompt: 'Pourquoi Saül mourut-il selon 1 Chroniques 10 ?',
    options:
        options ??
        [
          QuestionOption(id: 'infidelity', label: 'À cause de son infidélité'),
          QuestionOption(id: 'temple', label: 'Parce qu’il refusa le Temple'),
          QuestionOption(
            id: 'division',
            label: 'Parce qu’il divisa le royaume',
          ),
        ],
    correctOptionId: correctOptionId,
    explanation: 'Saül mourut à cause de son infidélité envers l’Éternel.',
    biblicalReference: '1 Chroniques 10:13-14',
    difficulty: QuestionDifficulty.easy,
    theme: 'fidelite',
    subject: 'Saül',
    languageCode: 'fr',
    contentVersion: contentVersion,
    isActive: true,
  );
}
