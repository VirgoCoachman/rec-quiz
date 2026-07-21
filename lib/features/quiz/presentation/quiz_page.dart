import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../application/quiz_bloc.dart';
import '../domain/question.dart';

final class QuizPage extends StatelessWidget {
  const QuizPage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.appTitle)),
      body: SafeArea(
        child: BlocBuilder<QuizBloc, QuizState>(
          builder: (context, state) {
            return switch (state) {
              QuizInitial() => _WelcomeView(strings: strings),
              QuizLoading() => const Center(child: CircularProgressIndicator()),
              QuizQuestionReady() => _QuestionView(
                state: state,
                strings: strings,
              ),
              QuizCompleted() => _ResultView(state: state, strings: strings),
              QuizFailure() => _FailureView(strings: strings),
            };
          },
        ),
      ),
    );
  }
}

final class _WelcomeView extends StatelessWidget {
  const _WelcomeView({required this.strings});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_stories_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 24),
              Text(
                strings.welcomeMessage,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () =>
                    context.read<QuizBloc>().add(const QuizStarted()),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(strings.startButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _QuestionView extends StatelessWidget {
  const _QuestionView({required this.state, required this.strings});

  final QuizQuestionReady state;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final question = state.question;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.questionProgress(
                  state.currentNumber,
                  state.totalQuestions,
                ),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: state.currentNumber / state.totalQuestions,
                semanticsValue: strings.questionProgress(
                  state.currentNumber,
                  state.totalQuestions,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                question.prompt,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              for (final option in question.options) ...[
                _AnswerButton(
                  option: option,
                  state: state,
                  semanticsLabel: strings.answerSemantics(option.label),
                ),
                const SizedBox(height: 12),
              ],
              if (state.evaluation case final evaluation?) ...[
                const SizedBox(height: 12),
                _FeedbackCard(
                  question: question,
                  evaluation: evaluation,
                  strings: strings,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () =>
                      context.read<QuizBloc>().add(const QuizNextRequested()),
                  child: Text(
                    state.isLastQuestion
                        ? strings.showResultButton
                        : strings.nextQuestionButton,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.option,
    required this.state,
    required this.semanticsLabel,
  });

  final QuestionOption option;
  final QuizQuestionReady state;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final evaluation = state.evaluation;
    final isSelected = evaluation?.selectedOptionId == option.id;
    final isCorrectOption = evaluation?.correctOptionId == option.id;
    final colorScheme = Theme.of(context).colorScheme;

    Color? backgroundColor;
    Color? foregroundColor;
    if (evaluation != null && isCorrectOption) {
      backgroundColor = const Color(0xFF1B5E20);
      foregroundColor = Colors.white;
    } else if (evaluation != null && isSelected) {
      backgroundColor = colorScheme.error;
      foregroundColor = colorScheme.onError;
    }

    return Semantics(
      label: semanticsLabel,
      button: true,
      selected: isSelected,
      child: ExcludeSemantics(
        child: OutlinedButton(
          onPressed: state.hasAnswered
              ? null
              : () => context.read<QuizBloc>().add(
                  QuizAnswerSubmitted(option.id),
                ),
          style: OutlinedButton.styleFrom(
            disabledBackgroundColor: backgroundColor,
            disabledForegroundColor: foregroundColor,
            side: BorderSide(
              color: backgroundColor ?? colorScheme.outline,
              width: isSelected || isCorrectOption ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text(option.label)),
                if (evaluation != null && isCorrectOption)
                  const Icon(Icons.check_circle_outline)
                else if (evaluation != null && isSelected)
                  const Icon(Icons.cancel_outlined),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.question,
    required this.evaluation,
    required this.strings,
  });

  final Question question;
  final AnswerEvaluation evaluation;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final isCorrect = evaluation.isCorrect;
    final feedback = isCorrect
        ? strings.correctFeedback
        : strings.incorrectFeedback;
    final accent = isCorrect
        ? const Color(0xFF1B5E20)
        : Theme.of(context).colorScheme.error;

    return Semantics(
      liveRegion: true,
      label: feedback,
      child: ExcludeSemantics(
        child: Card(
          color: accent.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.info_rounded,
                      color: accent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feedback,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                if (!isCorrect) ...[
                  const SizedBox(height: 12),
                  Text(strings.correctAnswer(question.correctOption.label)),
                ],
                const SizedBox(height: 16),
                Text(
                  strings.explanationHeading,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(question.explanation),
                const SizedBox(height: 12),
                Text(
                  strings.biblicalReferenceHeading,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(question.biblicalReference),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _ResultView extends StatelessWidget {
  const _ResultView({required this.state, required this.strings});

  final QuizCompleted state;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_rounded, size: 72),
            const SizedBox(height: 20),
            Text(
              strings.resultHeading,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              strings.score(state.score, state.totalQuestions),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () =>
                  context.read<QuizBloc>().add(const QuizRestarted()),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(strings.restartButton),
            ),
          ],
        ),
      ),
    );
  }
}

final class _FailureView extends StatelessWidget {
  const _FailureView({required this.strings});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(strings.loadError, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () =>
                  context.read<QuizBloc>().add(const QuizStarted()),
              child: Text(strings.retryButton),
            ),
          ],
        ),
      ),
    );
  }
}
