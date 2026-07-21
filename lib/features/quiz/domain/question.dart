enum QuestionDifficulty { easy, medium, hard }

final class QuestionOption {
  QuestionOption({required String id, required String label})
    : id = _requiredText(id, 'id'),
      label = _requiredText(label, 'label');

  final String id;
  final String label;
}

final class AnswerEvaluation {
  const AnswerEvaluation({
    required this.selectedOptionId,
    required this.correctOptionId,
    required this.isCorrect,
  });

  final String selectedOptionId;
  final String correctOptionId;
  final bool isCorrect;

  int get score => isCorrect ? 1 : 0;
}

final class Question {
  Question({
    required String id,
    required String prompt,
    required List<QuestionOption> options,
    required String correctOptionId,
    required String explanation,
    required String biblicalReference,
    required this.difficulty,
    required String theme,
    required String subject,
    required String languageCode,
    required this.contentVersion,
    required this.isActive,
  }) : id = _requiredText(id, 'id'),
       prompt = _requiredText(prompt, 'prompt'),
       options = List.unmodifiable(options),
       correctOptionId = _requiredText(correctOptionId, 'correctOptionId'),
       explanation = _requiredText(explanation, 'explanation'),
       biblicalReference = _requiredText(
         biblicalReference,
         'biblicalReference',
       ),
       theme = _requiredText(theme, 'theme'),
       subject = _requiredText(subject, 'subject'),
       languageCode = _requiredText(languageCode, 'languageCode') {
    if (this.options.length < 3) {
      throw ArgumentError.value(
        this.options.length,
        'options',
        'A question requires at least three options.',
      );
    }

    final optionIds = this.options.map((option) => option.id).toSet();
    if (optionIds.length != this.options.length) {
      throw ArgumentError.value(
        this.options,
        'options',
        'Option identifiers must be unique.',
      );
    }

    final normalizedLabels = this.options
        .map((option) => option.label.toLowerCase())
        .toSet();
    if (normalizedLabels.length != this.options.length) {
      throw ArgumentError.value(
        this.options,
        'options',
        'Option labels must be unique.',
      );
    }

    if (!optionIds.contains(this.correctOptionId)) {
      throw ArgumentError.value(
        this.correctOptionId,
        'correctOptionId',
        'The correct option must be one of the available options.',
      );
    }

    if (contentVersion < 1) {
      throw ArgumentError.value(
        contentVersion,
        'contentVersion',
        'The content version must be positive.',
      );
    }
  }

  final String id;
  final String prompt;
  final List<QuestionOption> options;
  final String correctOptionId;
  final String explanation;
  final String biblicalReference;
  final QuestionDifficulty difficulty;
  final String theme;
  final String subject;
  final String languageCode;
  final int contentVersion;
  final bool isActive;

  QuestionOption get correctOption =>
      options.firstWhere((option) => option.id == correctOptionId);

  AnswerEvaluation evaluateAnswer(String selectedOptionId) {
    if (!options.any((option) => option.id == selectedOptionId)) {
      throw ArgumentError.value(
        selectedOptionId,
        'selectedOptionId',
        'The selected option must belong to the question.',
      );
    }

    return AnswerEvaluation(
      selectedOptionId: selectedOptionId,
      correctOptionId: correctOptionId,
      isCorrect: selectedOptionId == correctOptionId,
    );
  }
}

String _requiredText(String value, String fieldName) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, fieldName, 'The value must not be empty.');
  }
  return trimmed;
}
