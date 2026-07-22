import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/audio/method_channel_quiz_feedback_player.dart';
import '../core/audio/quiz_feedback_player.dart';
import '../features/quiz/application/quiz_bloc.dart';
import '../features/quiz/application/load_best_score.dart';
import '../features/quiz/application/start_quiz_session.dart';
import '../features/quiz/application/update_best_score.dart';
import '../features/quiz/domain/best_score_repository.dart';
import '../features/quiz/domain/question_repository.dart';
import '../features/quiz/domain/quiz_question_selector.dart';
import '../features/quiz/infrastructure/bundled_question_repository.dart';
import '../features/quiz/presentation/quiz_page.dart';
import '../features/quiz/presentation/quiz_feedback_listener.dart';
import '../features/settings/application/sound_settings_cubit.dart';
import '../features/settings/domain/sound_settings_repository.dart';
import '../l10n/app_localizations.dart';

final class RecQuizApp extends StatelessWidget {
  const RecQuizApp({
    required this.bestScoreRepository,
    required this.soundSettingsRepository,
    super.key,
    this.questionRepository,
    this.seedGenerator,
    this.quizFeedbackPlayer = const MethodChannelQuizFeedbackPlayer(),
  });

  final BestScoreRepository bestScoreRepository;
  final SoundSettingsRepository soundSettingsRepository;
  final QuestionRepository? questionRepository;
  final SeedGenerator? seedGenerator;
  final QuizFeedbackPlayer quizFeedbackPlayer;

  @override
  Widget build(BuildContext context) {
    final repository = questionRepository ?? BundledQuestionRepository();
    final generateSeed =
        seedGenerator ?? () => DateTime.now().microsecondsSinceEpoch;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: _buildTheme(),
      home: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => SoundSettingsCubit(soundSettingsRepository)..load(),
          ),
          BlocProvider(
            create: (_) => QuizBloc(
              StartQuizSession(
                repository: repository,
                selector: const QuizQuestionSelector(),
                seedGenerator: generateSeed,
              ),
              LoadBestScore(bestScoreRepository),
              UpdateBestScore(bestScoreRepository),
            )..add(const QuizInitialized()),
          ),
        ],
        child: QuizFeedbackListener(
          player: quizFeedbackPlayer,
          child: const QuizPage(),
        ),
      ),
    );
  }
}

ThemeData _buildTheme() {
  const deepBlue = Color(0xFF17365D);
  const gold = Color(0xFFC28B18);
  const ivory = Color(0xFFFFFBF2);

  final colorScheme = ColorScheme.fromSeed(
    seedColor: deepBlue,
    brightness: Brightness.light,
    surface: ivory,
    primary: deepBlue,
    secondary: gold,
  );

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: ivory,
    useMaterial3: true,
    appBarTheme: const AppBarTheme(centerTitle: true),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        alignment: Alignment.centerLeft,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
