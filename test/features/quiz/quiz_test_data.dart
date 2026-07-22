import 'package:rec_quiz/features/quiz/domain/question.dart';

List<Question> buildQuizQuestions({int count = 10}) {
  return List.generate(count, (index) {
    final number = index + 1;
    return Question(
      id: 'question-$number',
      prompt: 'Question $number',
      options: [
        QuestionOption(
          id: 'question-$number-correct',
          label: 'Bonne réponse $number',
        ),
        QuestionOption(
          id: 'question-$number-wrong-a',
          label: 'Mauvaise réponse A$number',
        ),
        QuestionOption(
          id: 'question-$number-wrong-b',
          label: 'Mauvaise réponse B$number',
        ),
      ],
      correctOptionId: 'question-$number-correct',
      explanation: 'Explication $number',
      biblicalReference: '1 Chroniques 10:$number',
      difficulty: QuestionDifficulty.easy,
      theme: 'theme-$number',
      subject: 'Sujet $number',
      languageCode: 'fr',
      contentVersion: 1,
      isActive: true,
    );
  });
}
