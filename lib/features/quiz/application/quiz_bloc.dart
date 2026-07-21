import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/question.dart';
import 'load_quiz_question.dart';

sealed class QuizEvent {
  const QuizEvent();
}

final class QuizStarted extends QuizEvent {
  const QuizStarted();
}

final class QuizAnswerSubmitted extends QuizEvent {
  const QuizAnswerSubmitted(this.optionId);

  final String optionId;
}

final class QuizResultRequested extends QuizEvent {
  const QuizResultRequested();
}

final class QuizRestarted extends QuizEvent {
  const QuizRestarted();
}

sealed class QuizState {
  const QuizState();
}

final class QuizInitial extends QuizState {
  const QuizInitial();
}

final class QuizLoading extends QuizState {
  const QuizLoading();
}

final class QuizQuestionReady extends QuizState {
  const QuizQuestionReady({required this.question, this.evaluation});

  final Question question;
  final AnswerEvaluation? evaluation;

  bool get hasAnswered => evaluation != null;
}

final class QuizCompleted extends QuizState {
  const QuizCompleted({required this.score, required this.totalQuestions});

  final int score;
  final int totalQuestions;
}

final class QuizFailure extends QuizState {
  const QuizFailure();
}

final class QuizBloc extends Bloc<QuizEvent, QuizState> {
  QuizBloc(this._loadQuizQuestion) : super(const QuizInitial()) {
    on<QuizStarted>(_loadQuestion);
    on<QuizRestarted>(_loadQuestion);
    on<QuizAnswerSubmitted>(_submitAnswer);
    on<QuizResultRequested>(_showResult);
  }

  final LoadQuizQuestion _loadQuizQuestion;

  Future<void> _loadQuestion(QuizEvent event, Emitter<QuizState> emit) async {
    emit(const QuizLoading());
    try {
      final question = await _loadQuizQuestion();
      emit(QuizQuestionReady(question: question));
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(const QuizFailure());
    }
  }

  void _submitAnswer(QuizAnswerSubmitted event, Emitter<QuizState> emit) {
    final currentState = state;
    if (currentState is! QuizQuestionReady || currentState.hasAnswered) {
      return;
    }

    final evaluation = currentState.question.evaluateAnswer(event.optionId);
    emit(
      QuizQuestionReady(
        question: currentState.question,
        evaluation: evaluation,
      ),
    );
  }

  void _showResult(QuizResultRequested event, Emitter<QuizState> emit) {
    final currentState = state;
    if (currentState is! QuizQuestionReady || !currentState.hasAnswered) {
      return;
    }

    emit(
      QuizCompleted(score: currentState.evaluation!.score, totalQuestions: 1),
    );
  }
}
