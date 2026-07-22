import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'features/quiz/infrastructure/shared_preferences_best_score_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();

  runApp(
    RecQuizApp(
      bestScoreRepository: SharedPreferencesBestScoreRepository(preferences),
    ),
  );
}
