import '../domain/question.dart';

final class QuestionOptionDto {
  const QuestionOptionDto({required this.id, required this.label});

  factory QuestionOptionDto.fromJson(Map<String, Object?> json) {
    return QuestionOptionDto(
      id: _readString(json, 'id'),
      label: _readString(json, 'label'),
    );
  }

  final String id;
  final String label;

  QuestionOption toDomain() => QuestionOption(id: id, label: label);
}

final class QuestionDto {
  const QuestionDto({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctOptionId,
    required this.explanation,
    required this.biblicalReference,
    required this.difficulty,
    required this.theme,
    required this.subject,
    required this.languageCode,
    required this.contentVersion,
    required this.isActive,
  });

  factory QuestionDto.fromJson(Map<String, Object?> json) {
    final rawOptions = json['options'];
    if (rawOptions is! List<Object?>) {
      throw const FormatException('Question options must be a list.');
    }

    return QuestionDto(
      id: _readString(json, 'id'),
      prompt: _readString(json, 'prompt'),
      options: rawOptions
          .map((rawOption) {
            if (rawOption is! Map<String, Object?>) {
              throw const FormatException(
                'Each question option must be an object.',
              );
            }
            return QuestionOptionDto.fromJson(rawOption);
          })
          .toList(growable: false),
      correctOptionId: _readString(json, 'correctOptionId'),
      explanation: _readString(json, 'explanation'),
      biblicalReference: _readString(json, 'biblicalReference'),
      difficulty: _readString(json, 'difficulty'),
      theme: _readString(json, 'theme'),
      subject: _readString(json, 'subject'),
      languageCode: _readString(json, 'languageCode'),
      contentVersion: _readInt(json, 'contentVersion'),
      isActive: _readBool(json, 'isActive'),
    );
  }

  final String id;
  final String prompt;
  final List<QuestionOptionDto> options;
  final String correctOptionId;
  final String explanation;
  final String biblicalReference;
  final String difficulty;
  final String theme;
  final String subject;
  final String languageCode;
  final int contentVersion;
  final bool isActive;

  Question toDomain() {
    try {
      return Question(
        id: id,
        prompt: prompt,
        options: options.map((option) => option.toDomain()).toList(),
        correctOptionId: correctOptionId,
        explanation: explanation,
        biblicalReference: biblicalReference,
        difficulty: _parseDifficulty(difficulty),
        theme: theme,
        subject: subject,
        languageCode: languageCode,
        contentVersion: contentVersion,
        isActive: isActive,
      );
    } on ArgumentError catch (error) {
      throw FormatException('Invalid question "$id": ${error.message}');
    }
  }
}

QuestionDifficulty _parseDifficulty(String value) {
  return switch (value) {
    'easy' => QuestionDifficulty.easy,
    'medium' => QuestionDifficulty.medium,
    'hard' => QuestionDifficulty.hard,
    _ => throw FormatException('Unknown question difficulty: $value'),
  };
}

String _readString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Question field "$key" must be a non-empty string.');
  }
  return value;
}

int _readInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('Question field "$key" must be an integer.');
  }
  return value;
}

bool _readBool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! bool) {
    throw FormatException('Question field "$key" must be a boolean.');
  }
  return value;
}
