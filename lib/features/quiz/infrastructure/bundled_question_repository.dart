import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/question.dart';
import '../domain/question_repository.dart';
import 'question_dto.dart';

typedef AssetTextLoader = Future<String> Function(String assetPath);

final class BundledQuestionRepository implements QuestionRepository {
  BundledQuestionRepository({
    AssetTextLoader? assetTextLoader,
    this.assetPath = 'assets/content/fr/quiz_seed.json',
  }) : _assetTextLoader = assetTextLoader ?? rootBundle.loadString;

  final AssetTextLoader _assetTextLoader;
  final String assetPath;

  @override
  Future<List<Question>> loadActiveQuestions() async {
    final source = await _assetTextLoader(assetPath);
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('The question seed must be an object.');
    }

    if (decoded['schemaVersion'] != 1) {
      throw FormatException(
        'Unsupported question seed schema version: '
        '${decoded['schemaVersion']}.',
      );
    }

    final rawQuestions = decoded['questions'];
    if (rawQuestions is! List<Object?>) {
      throw const FormatException('The question seed must contain a list.');
    }

    final questions = <Question>[];
    final questionIds = <String>{};
    for (final rawQuestion in rawQuestions) {
      if (rawQuestion is! Map<String, Object?>) {
        throw const FormatException('Each question must be an object.');
      }
      final question = QuestionDto.fromJson(rawQuestion).toDomain();
      if (!questionIds.add(question.id)) {
        throw FormatException('Duplicate question identifier: ${question.id}.');
      }
      if (question.isActive) {
        questions.add(question);
      }
    }

    if (questions.isEmpty) {
      throw const FormatException('The question seed has no active question.');
    }
    return List.unmodifiable(questions);
  }
}
