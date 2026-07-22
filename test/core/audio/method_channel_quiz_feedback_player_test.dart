import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rec_quiz/core/audio/method_channel_quiz_feedback_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('rec_quiz/audio_feedback_test');
  final methodCalls = <MethodCall>[];

  setUp(() {
    methodCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          methodCalls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'sends distinct platform commands for correct and incorrect answers',
    () async {
      const player = MethodChannelQuizFeedbackPlayer(channel: channel);

      await player.playCorrectAnswer();
      await player.playIncorrectAnswer();

      expect(methodCalls.map((call) => call.method), [
        'playCorrectAnswer',
        'playIncorrectAnswer',
      ]);
    },
  );
}
