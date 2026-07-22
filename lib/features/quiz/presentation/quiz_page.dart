import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../application/quiz_bloc.dart';
import '../domain/question.dart';
import '../domain/question_attempt.dart';
import '../domain/quick_quiz_length.dart';
import '../domain/quiz_session_mode.dart';
import '../../settings/application/sound_settings_cubit.dart';

final class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

final class _QuizPageState extends State<QuizPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      context.read<QuizBloc>().add(const QuizPauseRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return BlocBuilder<QuizBloc, QuizState>(
      builder: (context, state) => PopScope<void>(
        canPop: state is! QuizQuestionReady && state is! QuizPaused,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && state is QuizQuestionReady) {
            context.read<QuizBloc>().add(const QuizPauseRequested());
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(strings.appTitle),
            actions: [
              BlocBuilder<QuizBloc, QuizState>(
                builder: (context, state) {
                  final canPause =
                      state is QuizQuestionReady &&
                      state.completedDuration == null;
                  if (!canPause) {
                    return const SizedBox.shrink();
                  }

                  return Semantics(
                    label: strings.pauseQuizButton,
                    button: true,
                    child: ExcludeSemantics(
                      child: IconButton(
                        onPressed: () => context.read<QuizBloc>().add(
                          const QuizPauseRequested(),
                        ),
                        tooltip: strings.pauseQuizButton,
                        icon: const Icon(Icons.pause_rounded),
                      ),
                    ),
                  );
                },
              ),
              BlocBuilder<SoundSettingsCubit, SoundSettingsState>(
                builder: (context, soundState) {
                  final isEnabled = soundState.isEnabled;
                  final label = isEnabled
                      ? strings.disableSoundButton
                      : strings.enableSoundButton;
                  return Semantics(
                    label: label,
                    button: true,
                    enabled: !soundState.isLoading,
                    child: ExcludeSemantics(
                      child: IconButton(
                        onPressed: soundState.isLoading
                            ? null
                            : () => context
                                  .read<SoundSettingsCubit>()
                                  .setEnabled(!isEnabled),
                        tooltip: label,
                        icon: Icon(
                          isEnabled
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: switch (state) {
              QuizInitial() => _WelcomeView(strings: strings, state: state),
              QuizLoading() => const Center(child: CircularProgressIndicator()),
              QuizQuestionReady() => _QuestionView(
                state: state,
                strings: strings,
              ),
              QuizCompleted() => _ResultView(state: state, strings: strings),
              QuizPaused() => _PausedView(strings: strings),
              QuizFailure() => _FailureView(strings: strings),
            },
          ),
        ),
      ),
    );
  }
}

final class _PausedView extends StatelessWidget {
  const _PausedView({required this.strings});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pause_circle_filled_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 20),
              Text(
                strings.pausedHeading,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                strings.pausedMessage,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Semantics(
                label: strings.resumeQuizButton,
                button: true,
                child: ExcludeSemantics(
                  child: FilledButton.icon(
                    onPressed: () => context.read<QuizBloc>().add(
                      const QuizResumeRequested(),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(strings.resumeQuizButton),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  final shouldDiscard = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(strings.discardQuizDialogTitle),
                      content: Text(strings.discardQuizDialogMessage),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: Text(strings.cancelButton),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: Text(strings.discardQuizConfirmButton),
                        ),
                      ],
                    ),
                  );
                  if (shouldDiscard == true && context.mounted) {
                    context.read<QuizBloc>().add(const QuizDiscardRequested());
                  }
                },
                child: Text(strings.discardQuizButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _WelcomeView extends StatelessWidget {
  const _WelcomeView({required this.strings, required this.state});

  final AppLocalizations strings;
  final QuizInitial state;

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
              const SizedBox(height: 16),
              Text(
                strings.quizLengthHeading,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  for (final length in QuickQuizLength.values)
                    Semantics(
                      label: strings.quizLengthSemantics(length.questionCount),
                      button: true,
                      selected: state.length == length,
                      child: ExcludeSemantics(
                        child: ChoiceChip(
                          label: Text(
                            strings.quizLengthOption(length.questionCount),
                          ),
                          selected: state.length == length,
                          onSelected: (isSelected) {
                            if (isSelected) {
                              context.read<QuizBloc>().add(
                                QuizLengthSelected(length),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                strings.bestScore(state.bestScore, state.length.questionCount),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () =>
                    context.read<QuizBloc>().add(const QuizStarted()),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(strings.startButton),
              ),
              if (state.hasFocusedReview) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.read<QuizBloc>().add(
                    const QuizFocusedReviewStarted(),
                  ),
                  icon: const Icon(Icons.school_rounded),
                  label: Text(strings.focusedReviewButton),
                ),
              ],
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
    final isMistakesReview = state.mode == QuizSessionMode.mistakesReview;
    final incorrectCount = state.incorrectAttempts.length;
    final reviewButtonLabel = isMistakesReview
        ? strings.reviewRemainingMistakesButton(incorrectCount)
        : strings.reviewMistakesButton(incorrectCount);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_rounded, size: 72),
            const SizedBox(height: 20),
            Text(
              isMistakesReview
                  ? strings.mistakesReviewCompletedHeading
                  : strings.resultHeading,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              strings.score(state.score, state.totalQuestions),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (!isMistakesReview) ...[
              Text(
                strings.bestScore(state.bestScore, state.totalQuestions),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              strings.sessionDuration(
                state.duration.inMinutes,
                state.duration.inSeconds.remainder(60),
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            Text(
              strings.detailedReviewHeading,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            for (var index = 0; index < state.attempts.length; index++) ...[
              _AttemptReviewCard(
                attempt: state.attempts[index],
                questionNumber: index + 1,
                strings: strings,
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 16),
            if (incorrectCount > 0) ...[
              Semantics(
                label: reviewButtonLabel,
                button: true,
                child: ExcludeSemantics(
                  child: FilledButton.icon(
                    onPressed: () => context.read<QuizBloc>().add(
                      const QuizMistakesReviewStarted(),
                    ),
                    icon: const Icon(Icons.replay_rounded),
                    label: Text(reviewButtonLabel),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              onPressed: () =>
                  context.read<QuizBloc>().add(const QuizRestarted()),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                isMistakesReview
                    ? strings.newQuickQuizButton
                    : strings.restartButton,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _AttemptReviewCard extends StatelessWidget {
  const _AttemptReviewCard({
    required this.attempt,
    required this.questionNumber,
    required this.strings,
  });

  final QuestionAttempt attempt;
  final int questionNumber;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final isCorrect = attempt.isCorrect;
    final status = isCorrect
        ? strings.correctAnswerStatus
        : strings.incorrectAnswerStatus;
    final accent = isCorrect
        ? const Color(0xFF1B5E20)
        : Theme.of(context).colorScheme.error;

    return Semantics(
      container: true,
      label: strings.attemptSemantics(questionNumber, status),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isCorrect
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.reviewQuestionNumber(questionNumber),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(status),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                attempt.prompt,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(strings.selectedAnswer(attempt.selectedOption.label)),
              if (!isCorrect) ...[
                const SizedBox(height: 6),
                Text(strings.correctAnswer(attempt.correctOption.label)),
              ],
              const SizedBox(height: 16),
              Text(
                strings.explanationHeading,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(attempt.explanation),
              const SizedBox(height: 12),
              Text(
                strings.biblicalReferenceHeading,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(attempt.biblicalReference),
            ],
          ),
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
