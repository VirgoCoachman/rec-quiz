enum QuickQuizLength {
  five(5),
  ten(10),
  twenty(20);

  const QuickQuizLength(this.questionCount);

  factory QuickQuizLength.fromQuestionCount(int questionCount) {
    return switch (questionCount) {
      5 => QuickQuizLength.five,
      10 => QuickQuizLength.ten,
      20 => QuickQuizLength.twenty,
      _ => throw ArgumentError.value(
        questionCount,
        'questionCount',
        'A quick quiz must contain 5, 10, or 20 questions.',
      ),
    };
  }

  final int questionCount;
}
