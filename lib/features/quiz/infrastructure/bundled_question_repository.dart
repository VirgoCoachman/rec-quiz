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
  Future<Question> loadFirstActiveQuestion() async {
    final source = await _assetTextLoader(assetPath);
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('The question seed must be an object.');
    }

    final rawQuestions = decoded['questions'];
    if (rawQuestions is! List<Object?>) {
      throw const FormatException('The question seed must contain a list.');
    }

    for (final rawQuestion in rawQuestions) {
      if (rawQuestion is! Map<String, Object?>) {
        throw const FormatException('Each question must be an object.');
      }
      final question = QuestionDto.fromJson(rawQuestion).toDomain();
      if (question.isActive) {
        return question;
      }
    }

    throw const FormatException('The question seed has no active question.');
  }
}
