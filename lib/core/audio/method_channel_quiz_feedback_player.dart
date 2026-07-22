import 'package:flutter/services.dart';

import 'quiz_feedback_player.dart';

final class MethodChannelQuizFeedbackPlayer implements QuizFeedbackPlayer {
  const MethodChannelQuizFeedbackPlayer({
    MethodChannel channel = const MethodChannel(_channelName),
  }) : _channel = channel;

  static const _channelName = 'rec_quiz/audio_feedback';

  final MethodChannel _channel;

  @override
  Future<void> playCorrectAnswer() {
    return _channel.invokeMethod<void>('playCorrectAnswer');
  }

  @override
  Future<void> playIncorrectAnswer() {
    return _channel.invokeMethod<void>('playIncorrectAnswer');
  }
}
