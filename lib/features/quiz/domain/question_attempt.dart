import 'question.dart';

final class QuestionAttempt {
  QuestionAttempt.answer({
    required Question question,
    required String selectedOptionId,
  }) : _question = question,
       _evaluation = question.evaluateAnswer(selectedOptionId);

  final Question _question;
  final AnswerEvaluation _evaluation;

  Question get question => _question;
  String get questionId => _question.id;
  String get prompt => _question.prompt;
  bool get isCorrect => _evaluation.isCorrect;
  int get score => _evaluation.score;
  String get explanation => _question.explanation;
  String get biblicalReference => _question.biblicalReference;
  AnswerEvaluation get evaluation => _evaluation;
  QuestionOption get selectedOption => _question.options.firstWhere(
    (option) => option.id == _evaluation.selectedOptionId,
  );
  QuestionOption get correctOption => _question.correctOption;
}
