// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Quiz REC';

  @override
  String get welcomeMessage =>
      'Découvre l’histoire des rois dans les Chroniques, une question à la fois.';

  @override
  String get startButton => 'Commencer';

  @override
  String questionProgress(int current, int total) {
    return 'Question $current sur $total';
  }

  @override
  String answerSemantics(String answer) {
    return 'Réponse : $answer';
  }

  @override
  String get correctFeedback => 'Bonne réponse !';

  @override
  String get incorrectFeedback => 'Ce n’est pas la bonne réponse.';

  @override
  String correctAnswer(String answer) {
    return 'Bonne réponse : $answer';
  }

  @override
  String get biblicalReferenceHeading => 'Référence biblique';

  @override
  String get explanationHeading => 'À retenir';

  @override
  String get nextQuestionButton => 'Question suivante';

  @override
  String get showResultButton => 'Voir mon résultat';

  @override
  String get resultHeading => 'Résultat';

  @override
  String score(int score, int total) {
    return 'Votre score : $score/$total';
  }

  @override
  String get restartButton => 'Recommencer';

  @override
  String get loadError => 'Impossible de charger les questions.';

  @override
  String get retryButton => 'Réessayer';
}
