import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/question_learning_progress.dart';
import '../domain/question_learning_progress_repository.dart';

final class SharedPreferencesQuestionLearningProgressRepository
    implements QuestionLearningProgressRepository {
  const SharedPreferencesQuestionLearningProgressRepository(this._preferences);

  static const _storageKey = 'quiz.question_learning_progress.v1';

  final SharedPreferences _preferences;

  @override
  Future<Map<String, QuestionLearningProgress>> loadAll() async {
    final encoded = _preferences.getString(_storageKey);
    if (encoded == null) {
      return const {};
    }
    try {
      final decoded = jsonDecode(encoded) as Map<String, Object?>;
      return Map.unmodifiable({
        for (final entry in decoded.entries)
          entry.key: _fromJson(entry.key, entry.value as Map<String, Object?>),
      });
    } on Object {
      return const {};
    }
  }

  @override
  Future<void> save(QuestionLearningProgress progress) async {
    final values = <String, Object?>{};
    final encoded = _preferences.getString(_storageKey);
    if (encoded != null) {
      final decoded = _decode(encoded);
      if (decoded != null) {
        values.addAll(decoded);
      }
    }
    values[progress.questionId] = _toJson(progress);
    final wasSaved = await _preferences.setString(
      _storageKey,
      jsonEncode(values),
    );
    if (!wasSaved) {
      throw StateError('Question learning progress could not be saved.');
    }
  }

  Map<String, Object?>? _decode(String encoded) {
    try {
      return jsonDecode(encoded) as Map<String, Object?>;
    } on Object {
      return null;
    }
  }

  Map<String, Object?> _toJson(QuestionLearningProgress progress) => {
    'correctAnswers': progress.correctAnswers,
    'incorrectAnswers': progress.incorrectAnswers,
    'correctStreak': progress.correctStreak,
    'lastSeenAt': progress.lastSeenAt?.toIso8601String(),
  };

  QuestionLearningProgress _fromJson(
    String questionId,
    Map<String, Object?> json,
  ) {
    final lastSeenAt = json['lastSeenAt'];
    return QuestionLearningProgress(
      questionId: questionId,
      correctAnswers: json['correctAnswers']! as int,
      incorrectAnswers: json['incorrectAnswers']! as int,
      correctStreak: json['correctStreak']! as int,
      lastSeenAt: lastSeenAt is String ? DateTime.parse(lastSeenAt) : null,
    );
  }
}
