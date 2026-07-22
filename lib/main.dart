import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'features/quiz/infrastructure/shared_preferences_best_score_repository.dart';
import 'features/quiz/infrastructure/shared_preferences_paused_quiz_session_repository.dart';
import 'features/quiz/infrastructure/shared_preferences_question_learning_progress_repository.dart';
import 'features/settings/infrastructure/shared_preferences_sound_settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();

  runApp(
    RecQuizApp(
      bestScoreRepository: SharedPreferencesBestScoreRepository(preferences),
      pausedQuizSessionRepository: SharedPreferencesPausedQuizSessionRepository(
        preferences,
      ),
      learningProgressRepository:
          SharedPreferencesQuestionLearningProgressRepository(preferences),
      soundSettingsRepository: SharedPreferencesSoundSettingsRepository(
        preferences,
      ),
    ),
  );
}
