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
  String get enableSoundButton => 'Activer le son';

  @override
  String get disableSoundButton => 'Désactiver le son';

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
  String get detailedReviewHeading => 'Correction détaillée';

  @override
  String get correctAnswerStatus => 'réponse correcte';

  @override
  String get incorrectAnswerStatus => 'réponse incorrecte';

  @override
  String reviewQuestionNumber(int number) {
    return 'Question $number';
  }

  @override
  String attemptSemantics(int number, String status) {
    return 'Question $number : $status';
  }

  @override
  String selectedAnswer(String answer) {
    return 'Votre réponse : $answer';
  }

  @override
  String score(int score, int total) {
    return 'Votre score : $score/$total';
  }

  @override
  String bestScore(int score, int total) {
    return 'Meilleur score : $score/$total';
  }

  @override
  String get restartButton => 'Recommencer';

  @override
  String get loadError => 'Impossible de charger les questions.';

  @override
  String get retryButton => 'Réessayer';
}
