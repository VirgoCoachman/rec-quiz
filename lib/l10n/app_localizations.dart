import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('fr')];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quiz REC'**
  String get appTitle;

  /// No description provided for @welcomeMessage.
  ///
  /// In fr, this message translates to:
  /// **'Découvre l’histoire des rois dans les Chroniques, une question à la fois.'**
  String get welcomeMessage;

  /// No description provided for @startButton.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get startButton;

  /// No description provided for @focusedReviewButton.
  ///
  /// In fr, this message translates to:
  /// **'Réviser les questions à renforcer'**
  String get focusedReviewButton;

  /// No description provided for @quizLengthHeading.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de questions'**
  String get quizLengthHeading;

  /// No description provided for @quizLengthOption.
  ///
  /// In fr, this message translates to:
  /// **'{count} questions'**
  String quizLengthOption(int count);

  /// No description provided for @quizLengthSemantics.
  ///
  /// In fr, this message translates to:
  /// **'Quiz de {count} questions'**
  String quizLengthSemantics(int count);

  /// No description provided for @enableSoundButton.
  ///
  /// In fr, this message translates to:
  /// **'Activer le son'**
  String get enableSoundButton;

  /// No description provided for @disableSoundButton.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver le son'**
  String get disableSoundButton;

  /// No description provided for @pauseQuizButton.
  ///
  /// In fr, this message translates to:
  /// **'Mettre le quiz en pause'**
  String get pauseQuizButton;

  /// No description provided for @pausedHeading.
  ///
  /// In fr, this message translates to:
  /// **'Quiz en pause'**
  String get pausedHeading;

  /// No description provided for @pausedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Ta progression est conservée. Reprends quand tu es prêt.'**
  String get pausedMessage;

  /// No description provided for @resumeQuizButton.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre le quiz'**
  String get resumeQuizButton;

  /// No description provided for @discardQuizButton.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner le quiz'**
  String get discardQuizButton;

  /// No description provided for @discardQuizDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner ce quiz ?'**
  String get discardQuizDialogTitle;

  /// No description provided for @discardQuizDialogMessage.
  ///
  /// In fr, this message translates to:
  /// **'Ta progression sauvegardée sera supprimée.'**
  String get discardQuizDialogMessage;

  /// No description provided for @discardQuizConfirmButton.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner'**
  String get discardQuizConfirmButton;

  /// No description provided for @cancelButton.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancelButton;

  /// No description provided for @questionProgress.
  ///
  /// In fr, this message translates to:
  /// **'Question {current} sur {total}'**
  String questionProgress(int current, int total);

  /// No description provided for @answerSemantics.
  ///
  /// In fr, this message translates to:
  /// **'Réponse : {answer}'**
  String answerSemantics(String answer);

  /// No description provided for @correctFeedback.
  ///
  /// In fr, this message translates to:
  /// **'Bonne réponse !'**
  String get correctFeedback;

  /// No description provided for @incorrectFeedback.
  ///
  /// In fr, this message translates to:
  /// **'Ce n’est pas la bonne réponse.'**
  String get incorrectFeedback;

  /// No description provided for @correctAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Bonne réponse : {answer}'**
  String correctAnswer(String answer);

  /// No description provided for @biblicalReferenceHeading.
  ///
  /// In fr, this message translates to:
  /// **'Référence biblique'**
  String get biblicalReferenceHeading;

  /// No description provided for @explanationHeading.
  ///
  /// In fr, this message translates to:
  /// **'À retenir'**
  String get explanationHeading;

  /// No description provided for @nextQuestionButton.
  ///
  /// In fr, this message translates to:
  /// **'Question suivante'**
  String get nextQuestionButton;

  /// No description provided for @showResultButton.
  ///
  /// In fr, this message translates to:
  /// **'Voir mon résultat'**
  String get showResultButton;

  /// No description provided for @resultHeading.
  ///
  /// In fr, this message translates to:
  /// **'Résultat'**
  String get resultHeading;

  /// No description provided for @mistakesReviewCompletedHeading.
  ///
  /// In fr, this message translates to:
  /// **'Révision terminée'**
  String get mistakesReviewCompletedHeading;

  /// No description provided for @reviewMistakesButton.
  ///
  /// In fr, this message translates to:
  /// **'Revoir mes erreurs ({count})'**
  String reviewMistakesButton(int count);

  /// No description provided for @reviewRemainingMistakesButton.
  ///
  /// In fr, this message translates to:
  /// **'Revoir les erreurs restantes ({count})'**
  String reviewRemainingMistakesButton(int count);

  /// No description provided for @newQuickQuizButton.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau quiz rapide'**
  String get newQuickQuizButton;

  /// No description provided for @detailedReviewHeading.
  ///
  /// In fr, this message translates to:
  /// **'Correction détaillée'**
  String get detailedReviewHeading;

  /// No description provided for @correctAnswerStatus.
  ///
  /// In fr, this message translates to:
  /// **'réponse correcte'**
  String get correctAnswerStatus;

  /// No description provided for @incorrectAnswerStatus.
  ///
  /// In fr, this message translates to:
  /// **'réponse incorrecte'**
  String get incorrectAnswerStatus;

  /// No description provided for @reviewQuestionNumber.
  ///
  /// In fr, this message translates to:
  /// **'Question {number}'**
  String reviewQuestionNumber(int number);

  /// No description provided for @attemptSemantics.
  ///
  /// In fr, this message translates to:
  /// **'Question {number} : {status}'**
  String attemptSemantics(int number, String status);

  /// No description provided for @selectedAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Votre réponse : {answer}'**
  String selectedAnswer(String answer);

  /// No description provided for @score.
  ///
  /// In fr, this message translates to:
  /// **'Votre score : {score}/{total}'**
  String score(int score, int total);

  /// No description provided for @bestScore.
  ///
  /// In fr, this message translates to:
  /// **'Meilleur score : {score}/{total}'**
  String bestScore(int score, int total);

  /// No description provided for @sessionDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée : {minutes} min {seconds} s'**
  String sessionDuration(int minutes, int seconds);

  /// No description provided for @restartButton.
  ///
  /// In fr, this message translates to:
  /// **'Recommencer'**
  String get restartButton;

  /// No description provided for @loadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les questions.'**
  String get loadError;

  /// No description provided for @retryButton.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retryButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
