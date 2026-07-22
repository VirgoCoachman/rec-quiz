import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/paused_quiz_session.dart';
import '../domain/paused_quiz_session_repository.dart';
import '../domain/question.dart';
import '../domain/quick_quiz_length.dart';
import '../domain/quiz_session_mode.dart';

final class SharedPreferencesPausedQuizSessionRepository
    implements PausedQuizSessionRepository {
  const SharedPreferencesPausedQuizSessionRepository(this._preferences);

  static const _storageKey = 'quiz.paused_session.v1';

  final SharedPreferences _preferences;

  @override
  Future<PausedQuizSession?> load() async {
    final encoded = _preferences.getString(_storageKey);
    if (encoded == null) {
      return null;
    }

    try {
      final json = jsonDecode(encoded);
      if (json is! Map<String, Object?> || json['schemaVersion'] != 1) {
        throw const FormatException('Unsupported paused quiz session.');
      }
      final questions = (json['questions'] as List<Object?>)
          .map((value) => _questionFromJson(value as Map<String, Object?>))
          .toList();
      final attempts = (json['attempts'] as List<Object?>)
          .map(
            (value) => PausedQuestionAttempt(
              questionId:
                  (value as Map<String, Object?>)['questionId']! as String,
              selectedOptionId: value['selectedOptionId']! as String,
            ),
          )
          .toList();
      return PausedQuizSession(
        questions: questions,
        currentIndex: json['currentIndex']! as int,
        score: json['score']! as int,
        bestScore: json['bestScore']! as int,
        elapsed: Duration(
          milliseconds: json['elapsedMilliseconds'] as int? ?? 0,
        ),
        length: QuickQuizLength.fromQuestionCount(json['length']! as int),
        mode: QuizSessionMode.values.byName(json['mode']! as String),
        attempts: attempts,
      );
    } on Object {
      await clear();
      return null;
    }
  }

  @override
  Future<void> save(PausedQuizSession session) async {
    final wasSaved = await _preferences.setString(
      _storageKey,
      jsonEncode({
        'schemaVersion': 1,
        'questions': session.questions.map(_questionToJson).toList(),
        'currentIndex': session.currentIndex,
        'score': session.score,
        'bestScore': session.bestScore,
        'elapsedMilliseconds': session.elapsed.inMilliseconds,
        'length': session.length.questionCount,
        'mode': session.mode.name,
        'attempts': session.attempts
            .map(
              (attempt) => {
                'questionId': attempt.questionId,
                'selectedOptionId': attempt.selectedOptionId,
              },
            )
            .toList(),
      }),
    );
    if (!wasSaved) {
      throw StateError('The paused quiz session could not be saved.');
    }
  }

  @override
  Future<void> clear() async {
    final wasCleared = await _preferences.remove(_storageKey);
    if (!wasCleared) {
      throw StateError('The paused quiz session could not be cleared.');
    }
  }

  Map<String, Object?> _questionToJson(Question question) => {
    'id': question.id,
    'prompt': question.prompt,
    'options': question.options
        .map((option) => {'id': option.id, 'label': option.label})
        .toList(),
    'correctOptionId': question.correctOptionId,
    'explanation': question.explanation,
    'biblicalReference': question.biblicalReference,
    'difficulty': question.difficulty.name,
    'theme': question.theme,
    'subject': question.subject,
    'languageCode': question.languageCode,
    'contentVersion': question.contentVersion,
    'isActive': question.isActive,
  };

  Question _questionFromJson(Map<String, Object?> json) => Question(
    id: json['id']! as String,
    prompt: json['prompt']! as String,
    options: (json['options'] as List<Object?>)
        .map(
          (value) => QuestionOption(
            id: (value as Map<String, Object?>)['id']! as String,
            label: value['label']! as String,
          ),
        )
        .toList(),
    correctOptionId: json['correctOptionId']! as String,
    explanation: json['explanation']! as String,
    biblicalReference: json['biblicalReference']! as String,
    difficulty: QuestionDifficulty.values.byName(json['difficulty']! as String),
    theme: json['theme']! as String,
    subject: json['subject']! as String,
    languageCode: json['languageCode']! as String,
    contentVersion: json['contentVersion']! as int,
    isActive: json['isActive']! as bool,
  );
}
