import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/question.dart';
import 'start_quiz_session.dart';

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

final class QuizNextRequested extends QuizEvent {
  const QuizNextRequested();
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
  QuizQuestionReady({
    required List<Question> questions,
    required this.currentIndex,
    required this.score,
    this.evaluation,
  }) : questions = List.unmodifiable(questions);

  final List<Question> questions;
  final int currentIndex;
  final int score;
  final AnswerEvaluation? evaluation;

  Question get question => questions[currentIndex];
  int get currentNumber => currentIndex + 1;
  int get totalQuestions => questions.length;
  bool get hasAnswered => evaluation != null;
  bool get isLastQuestion => currentIndex == questions.length - 1;
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
  QuizBloc(this._startQuizSession) : super(const QuizInitial()) {
    on<QuizStarted>(_loadSession);
    on<QuizRestarted>(_loadSession);
    on<QuizAnswerSubmitted>(_submitAnswer);
    on<QuizNextRequested>(_moveNext);
  }

  final StartQuizSession _startQuizSession;

  Future<void> _loadSession(QuizEvent event, Emitter<QuizState> emit) async {
    emit(const QuizLoading());
    try {
      final questions = await _startQuizSession();
      emit(QuizQuestionReady(questions: questions, currentIndex: 0, score: 0));
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
        questions: currentState.questions,
        currentIndex: currentState.currentIndex,
        score: currentState.score + evaluation.score,
        evaluation: evaluation,
      ),
    );
  }

  void _moveNext(QuizNextRequested event, Emitter<QuizState> emit) {
    final currentState = state;
    if (currentState is! QuizQuestionReady || !currentState.hasAnswered) {
      return;
    }

    if (currentState.isLastQuestion) {
      emit(
        QuizCompleted(
          score: currentState.score,
          totalQuestions: currentState.totalQuestions,
        ),
      );
      return;
    }

    emit(
      QuizQuestionReady(
        questions: currentState.questions,
        currentIndex: currentState.currentIndex + 1,
        score: currentState.score,
      ),
    );
  }
}
