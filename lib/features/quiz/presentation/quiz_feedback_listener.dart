import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/audio/quiz_feedback_player.dart';
import '../../settings/application/sound_settings_cubit.dart';
import '../application/quiz_bloc.dart';

final class QuizFeedbackListener extends StatelessWidget {
  const QuizFeedbackListener({
    required this.player,
    required this.child,
    super.key,
  });

  final QuizFeedbackPlayer player;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<QuizBloc, QuizState>(
      listenWhen: _hasNewEvaluation,
      listener: (context, state) {
        if (!context.read<SoundSettingsCubit>().state.isEnabled) {
          return;
        }

        final ready = state as QuizQuestionReady;
        final evaluation = ready.evaluation!;
        unawaited(
          _playAndReport(
            evaluation.isCorrect
                ? player.playCorrectAnswer
                : player.playIncorrectAnswer,
          ),
        );
      },
      child: child,
    );
  }

  bool _hasNewEvaluation(QuizState previous, QuizState current) {
    if (current is! QuizQuestionReady || !current.hasAnswered) {
      return false;
    }
    return previous is! QuizQuestionReady ||
        !previous.hasAnswered ||
        previous.currentIndex != current.currentIndex;
  }

  Future<void> _playAndReport(Future<void> Function() play) async {
    try {
      await play();
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'REC Quiz audio feedback',
          context: ErrorDescription('while playing answer feedback'),
        ),
      );
    }
  }
}
