import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/question.dart';
import '../domain/question_attempt.dart';
import '../domain/quiz_session_timer.dart';
import '../domain/quick_quiz_length.dart';
import 'load_best_score.dart';
import 'start_quiz_session.dart';
import 'update_best_score.dart';

sealed class QuizEvent {
  const QuizEvent();
}

final class QuizInitialized extends QuizEvent {
  const QuizInitialized();
}

final class QuizStarted extends QuizEvent {
  const QuizStarted();
}

final class QuizLengthSelected extends QuizEvent {
  const QuizLengthSelected(this.length);

  final QuickQuizLength length;
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
  const QuizState({required this.bestScore, required this.length});

  final int bestScore;
  final QuickQuizLength length;
}

final class QuizInitial extends QuizState {
  const QuizInitial({
    required super.bestScore,
    super.length = QuickQuizLength.ten,
  });
}

final class QuizLoading extends QuizState {
  const QuizLoading({required super.bestScore, required super.length});
}

final class QuizQuestionReady extends QuizState {
  QuizQuestionReady({
    required List<Question> questions,
    required this.currentIndex,
    required this.score,
    required super.bestScore,
    required super.length,
    List<QuestionAttempt> attempts = const [],
    this.currentAttempt,
    this.completedDuration,
  }) : questions = List.unmodifiable(questions),
       attempts = List.unmodifiable(attempts);

  final List<Question> questions;
  final int currentIndex;
  final int score;
  final List<QuestionAttempt> attempts;
  final QuestionAttempt? currentAttempt;
  final Duration? completedDuration;

  Question get question => questions[currentIndex];
  AnswerEvaluation? get evaluation => currentAttempt?.evaluation;
  int get currentNumber => currentIndex + 1;
  int get totalQuestions => questions.length;
  bool get hasAnswered => currentAttempt != null;
  bool get isLastQuestion => currentIndex == questions.length - 1;
}

final class QuizCompleted extends QuizState {
  QuizCompleted({
    required this.score,
    required this.totalQuestions,
    required this.duration,
    required super.bestScore,
    required super.length,
    required List<QuestionAttempt> attempts,
  }) : attempts = List.unmodifiable(attempts);

  final int score;
  final int totalQuestions;
  final Duration duration;
  final List<QuestionAttempt> attempts;
}

final class QuizFailure extends QuizState {
  const QuizFailure({required super.bestScore, required super.length});
}

final class QuizBloc extends Bloc<QuizEvent, QuizState> {
  QuizBloc(
    this._startQuizSession,
    this._loadBestScore,
    this._updateBestScore, {
    required QuizSessionTimer sessionTimer,
  }) : _sessionTimer = sessionTimer,
       super(const QuizInitial(bestScore: 0)) {
    on<QuizInitialized>(_initialize);
    on<QuizLengthSelected>(_selectLength);
    on<QuizStarted>(_loadSession);
    on<QuizRestarted>(_loadSession);
    on<QuizAnswerSubmitted>(_submitAnswer);
    on<QuizNextRequested>(_moveNext);
  }

  final StartQuizSession _startQuizSession;
  final LoadBestScore _loadBestScore;
  final UpdateBestScore _updateBestScore;
  final QuizSessionTimer _sessionTimer;

  Future<void> _initialize(
    QuizInitialized event,
    Emitter<QuizState> emit,
  ) async {
    try {
      final length = state.length;
      emit(
        QuizInitial(bestScore: await _loadBestScore(length), length: length),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
    }
  }

  Future<void> _selectLength(
    QuizLengthSelected event,
    Emitter<QuizState> emit,
  ) async {
    if (state is! QuizInitial) {
      return;
    }

    try {
      emit(
        QuizInitial(
          bestScore: await _loadBestScore(event.length),
          length: event.length,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
    }
  }

  Future<void> _loadSession(QuizEvent event, Emitter<QuizState> emit) async {
    final bestScore = state.bestScore;
    final length = state.length;
    emit(QuizLoading(bestScore: bestScore, length: length));
    try {
      final questions = await _startQuizSession(length);
      _sessionTimer.start();
      emit(
        QuizQuestionReady(
          questions: questions,
          currentIndex: 0,
          score: 0,
          bestScore: bestScore,
          length: length,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(QuizFailure(bestScore: bestScore, length: length));
    }
  }

  void _submitAnswer(QuizAnswerSubmitted event, Emitter<QuizState> emit) {
    final currentState = state;
    if (currentState is! QuizQuestionReady || currentState.hasAnswered) {
      return;
    }

    final attempt = QuestionAttempt.answer(
      question: currentState.question,
      selectedOptionId: event.optionId,
    );
    final completedDuration = currentState.isLastQuestion
        ? _sessionTimer.stop()
        : null;
    emit(
      QuizQuestionReady(
        questions: currentState.questions,
        currentIndex: currentState.currentIndex,
        score: currentState.score + attempt.score,
        bestScore: currentState.bestScore,
        length: currentState.length,
        attempts: [...currentState.attempts, attempt],
        currentAttempt: attempt,
        completedDuration: completedDuration,
      ),
    );
  }

  Future<void> _moveNext(
    QuizNextRequested event,
    Emitter<QuizState> emit,
  ) async {
    final currentState = state;
    if (currentState is! QuizQuestionReady || !currentState.hasAnswered) {
      return;
    }

    if (currentState.isLastQuestion) {
      final duration = currentState.completedDuration;
      if (duration == null) {
        throw StateError('A completed quiz must have a measured duration.');
      }
      var bestScore = currentState.bestScore;
      try {
        bestScore = await _updateBestScore(
          length: currentState.length,
          candidate: currentState.score,
          currentBest: bestScore,
        );
      } on Object catch (error, stackTrace) {
        addError(error, stackTrace);
      }
      emit(
        QuizCompleted(
          score: currentState.score,
          totalQuestions: currentState.totalQuestions,
          duration: duration,
          bestScore: bestScore,
          length: currentState.length,
          attempts: currentState.attempts,
        ),
      );
      return;
    }

    emit(
      QuizQuestionReady(
        questions: currentState.questions,
        currentIndex: currentState.currentIndex + 1,
        score: currentState.score,
        bestScore: currentState.bestScore,
        length: currentState.length,
        attempts: currentState.attempts,
      ),
    );
  }
}
