import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionBodyMetrics.
  ///
  /// In en, this message translates to:
  /// **'Body Metrics'**
  String get sectionBodyMetrics;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// No description provided for @sectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get sectionAccount;

  /// No description provided for @sectionApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get sectionApp;

  /// No description provided for @sectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get sectionLanguage;

  /// No description provided for @labelWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get labelWeight;

  /// No description provided for @labelHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get labelHeight;

  /// No description provided for @labelDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get labelDarkMode;

  /// No description provided for @labelAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get labelAccentColor;

  /// No description provided for @accentBlue.
  ///
  /// In en, this message translates to:
  /// **'Cobalt'**
  String get accentBlue;

  /// No description provided for @accentRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get accentRed;

  /// No description provided for @accentPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get accentPurple;

  /// No description provided for @accentGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get accentGreen;

  /// No description provided for @labelNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get labelNotifications;

  /// No description provided for @labelAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get labelAbout;

  /// No description provided for @labelReenableWeightReminders.
  ///
  /// In en, this message translates to:
  /// **'Re-enable weight reminders'**
  String get labelReenableWeightReminders;

  /// No description provided for @labelLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get labelLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get languageRussian;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordMin.
  ///
  /// In en, this message translates to:
  /// **'Password (min 8 chars)'**
  String get passwordMin;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @continueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueGoogle;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get noAccount;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @alreadyAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyAccount;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @weekStreak.
  ///
  /// In en, this message translates to:
  /// **'TRAINING CHAIN'**
  String get weekStreak;

  /// No description provided for @nextGoal.
  ///
  /// In en, this message translates to:
  /// **'NEXT GOAL'**
  String get nextGoal;

  /// No description provided for @routines.
  ///
  /// In en, this message translates to:
  /// **'ROUTINES'**
  String get routines;

  /// No description provided for @workouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get workouts;

  /// No description provided for @workoutsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Programs and routines'**
  String get workoutsSubtitle;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @progressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'History and personal records'**
  String get progressSubtitle;

  /// No description provided for @strengthPassport.
  ///
  /// In en, this message translates to:
  /// **'Strength Passport'**
  String get strengthPassport;

  /// No description provided for @strengthPassportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your median-ranked strength identity'**
  String get strengthPassportSubtitle;

  /// No description provided for @exercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercises;

  /// No description provided for @exercisesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Movement library'**
  String get exercisesSubtitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences and account'**
  String get settingsSubtitle;

  /// No description provided for @startWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start workout'**
  String get startWorkout;

  /// No description provided for @rankedLifts.
  ///
  /// In en, this message translates to:
  /// **'RANKED LIFTS'**
  String get rankedLifts;

  /// No description provided for @bodyweight.
  ///
  /// In en, this message translates to:
  /// **'BODYWEIGHT'**
  String get bodyweight;

  /// No description provided for @bestLift.
  ///
  /// In en, this message translates to:
  /// **'BEST LIFT'**
  String get bestLift;

  /// No description provided for @medianRankedNote.
  ///
  /// In en, this message translates to:
  /// **'Median-ranked · extreme results excluded'**
  String get medianRankedNote;

  /// No description provided for @passportLocked.
  ///
  /// In en, this message translates to:
  /// **'Record 3+ exercises\nto issue your passport'**
  String get passportLocked;

  /// No description provided for @resumeWorkout.
  ///
  /// In en, this message translates to:
  /// **'Resume active workout'**
  String get resumeWorkout;

  /// No description provided for @chooseWorkout.
  ///
  /// In en, this message translates to:
  /// **'Choose a workout'**
  String get chooseWorkout;

  /// No description provided for @resumeSummary.
  ///
  /// In en, this message translates to:
  /// **'{elapsed} · {done}/{total} sets · tap to resume'**
  String resumeSummary(String elapsed, int done, int total);

  /// No description provided for @repetitions.
  ///
  /// In en, this message translates to:
  /// **'Repetitions'**
  String get repetitions;

  /// No description provided for @weightField.
  ///
  /// In en, this message translates to:
  /// **'Weight in {unit}'**
  String weightField(String unit);

  /// No description provided for @restoringSession.
  ///
  /// In en, this message translates to:
  /// **'Restoring your session…'**
  String get restoringSession;

  /// No description provided for @gettingReady.
  ///
  /// In en, this message translates to:
  /// **'Getting things ready…'**
  String get gettingReady;

  /// No description provided for @takingLonger.
  ///
  /// In en, this message translates to:
  /// **'This is taking longer than expected.'**
  String get takingLonger;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @mineCount.
  ///
  /// In en, this message translates to:
  /// **'Mine ({count})'**
  String mineCount(int count);

  /// No description provided for @libraryCount.
  ///
  /// In en, this message translates to:
  /// **'Library ({count})'**
  String libraryCount(int count);

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @allWorkouts.
  ///
  /// In en, this message translates to:
  /// **'All workouts'**
  String get allWorkouts;

  /// No description provided for @searchWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Search all workouts'**
  String get searchWorkouts;

  /// No description provided for @noWorkoutsFound.
  ///
  /// In en, this message translates to:
  /// **'No workouts found'**
  String get noWorkoutsFound;

  /// No description provided for @noWorkoutsYet.
  ///
  /// In en, this message translates to:
  /// **'No workouts yet'**
  String get noWorkoutsYet;

  /// No description provided for @libraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Library is empty'**
  String get libraryEmpty;

  /// No description provided for @createWorkout.
  ///
  /// In en, this message translates to:
  /// **'Create workout'**
  String get createWorkout;

  /// No description provided for @couldNotLoadWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Could not load workouts'**
  String get couldNotLoadWorkouts;

  /// No description provided for @workoutUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'This workout is not on this device yet'**
  String get workoutUnavailableTitle;

  /// No description provided for @workoutUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet and open it once. After that, it will be available offline.'**
  String get workoutUnavailableBody;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @sortExercises.
  ///
  /// In en, this message translates to:
  /// **'Sort exercises'**
  String get sortExercises;

  /// No description provided for @searchExercises.
  ///
  /// In en, this message translates to:
  /// **'Search {count} exercises'**
  String searchExercises(int count);

  /// No description provided for @catalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get catalog;

  /// No description provided for @myExercises.
  ///
  /// In en, this message translates to:
  /// **'My exercises'**
  String get myExercises;

  /// No description provided for @noExercisesFound.
  ///
  /// In en, this message translates to:
  /// **'No exercises found'**
  String get noExercisesFound;

  /// No description provided for @yourStats.
  ///
  /// In en, this message translates to:
  /// **'Your Stats'**
  String get yourStats;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noDataYet;

  /// No description provided for @personalRecords.
  ///
  /// In en, this message translates to:
  /// **'Personal Records'**
  String get personalRecords;

  /// No description provided for @couldNotLoadExercises.
  ///
  /// In en, this message translates to:
  /// **'Could not load exercises'**
  String get couldNotLoadExercises;

  /// No description provided for @newExercise.
  ///
  /// In en, this message translates to:
  /// **'New exercise'**
  String get newExercise;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @trainingWorkload.
  ///
  /// In en, this message translates to:
  /// **'Training Workload'**
  String get trainingWorkload;

  /// No description provided for @workoutCalendar.
  ///
  /// In en, this message translates to:
  /// **'Workout Calendar'**
  String get workoutCalendar;

  /// No description provided for @trainingTrends.
  ///
  /// In en, this message translates to:
  /// **'Training Trends'**
  String get trainingTrends;

  /// No description provided for @finishWorkoutForTrends.
  ///
  /// In en, this message translates to:
  /// **'Finish a workout to see trends'**
  String get finishWorkoutForTrends;

  /// No description provided for @noStatsYet.
  ///
  /// In en, this message translates to:
  /// **'No stats yet'**
  String get noStatsYet;

  /// No description provided for @highlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get highlights;

  /// No description provided for @noSessionsYet.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get noSessionsYet;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @recordStartsHere.
  ///
  /// In en, this message translates to:
  /// **'Your record starts here'**
  String get recordStartsHere;

  /// No description provided for @recordStartsBody.
  ///
  /// In en, this message translates to:
  /// **'Complete a working set to unlock mastery, personal records and a progression trail.'**
  String get recordStartsBody;

  /// No description provided for @estimatedOneRm.
  ///
  /// In en, this message translates to:
  /// **'ESTIMATED 1RM'**
  String get estimatedOneRm;

  /// No description provided for @currentPowerMark.
  ///
  /// In en, this message translates to:
  /// **'Current power mark'**
  String get currentPowerMark;

  /// No description provided for @heaviestSet.
  ///
  /// In en, this message translates to:
  /// **'HEAVIEST SET'**
  String get heaviestSet;

  /// No description provided for @sessionsLogged.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions logged'**
  String sessionsLogged(int count);

  /// No description provided for @workingSets.
  ///
  /// In en, this message translates to:
  /// **'WORKING SETS'**
  String get workingSets;

  /// No description provided for @totalReps.
  ///
  /// In en, this message translates to:
  /// **'{count} total reps'**
  String totalReps(int count);

  /// No description provided for @bestSetVolume.
  ///
  /// In en, this message translates to:
  /// **'BEST SET VOLUME'**
  String get bestSetVolume;

  /// No description provided for @peakSingleSetWork.
  ///
  /// In en, this message translates to:
  /// **'Peak single-set work'**
  String get peakSingleSetWork;

  /// No description provided for @masteryLevel.
  ///
  /// In en, this message translates to:
  /// **'MASTERY LEVEL {level}'**
  String masteryLevel(int level);

  /// No description provided for @rankAndLevel.
  ///
  /// In en, this message translates to:
  /// **'RANK {rank} · LEVEL {level}'**
  String rankAndLevel(String rank, int level);

  /// No description provided for @setsToNextLevel.
  ///
  /// In en, this message translates to:
  /// **'{count} working sets to level {level}'**
  String setsToNextLevel(int count, int level);

  /// No description provided for @masteryInitiate.
  ///
  /// In en, this message translates to:
  /// **'Initiate'**
  String get masteryInitiate;

  /// No description provided for @masteryTrained.
  ///
  /// In en, this message translates to:
  /// **'Trained'**
  String get masteryTrained;

  /// No description provided for @masteryProven.
  ///
  /// In en, this message translates to:
  /// **'Proven'**
  String get masteryProven;

  /// No description provided for @masteryVeteran.
  ///
  /// In en, this message translates to:
  /// **'Veteran'**
  String get masteryVeteran;

  /// No description provided for @masteryMaster.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get masteryMaster;

  /// No description provided for @lockedStatsPreview.
  ///
  /// In en, this message translates to:
  /// **'LEVEL 1 · FIRST PR · PROGRESSION TRAIL'**
  String get lockedStatsPreview;

  /// No description provided for @passportRatioSummary.
  ///
  /// In en, this message translates to:
  /// **'{ratio}× cohort median · median of {count} ranked lifts'**
  String passportRatioSummary(String ratio, int count);

  /// No description provided for @passportTierProgress.
  ///
  /// In en, this message translates to:
  /// **'{remaining}× median to {next} · {progress}% through this rank'**
  String passportTierProgress(String remaining, String next, int progress);

  /// No description provided for @exerciseMedianProgress.
  ///
  /// In en, this message translates to:
  /// **'{ratio}× median · next {next}'**
  String exerciseMedianProgress(String ratio, String next);

  /// No description provided for @medianCalibrationPending.
  ///
  /// In en, this message translates to:
  /// **'Median calibration pending'**
  String get medianCalibrationPending;

  /// No description provided for @passportNoLiftsTitle.
  ///
  /// In en, this message translates to:
  /// **'No lifts recorded yet'**
  String get passportNoLiftsTitle;

  /// No description provided for @passportNoLiftsBody.
  ///
  /// In en, this message translates to:
  /// **'Record a benchmark lift to issue your passport. Three ranked movements unlock the overall class.'**
  String get passportNoLiftsBody;

  /// No description provided for @passportPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'PASSPORT ENTRY · PREVIEW'**
  String get passportPreviewTitle;

  /// No description provided for @passportPreviewExercise.
  ///
  /// In en, this message translates to:
  /// **'Bench Press'**
  String get passportPreviewExercise;

  /// No description provided for @passportPreviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your best set · estimated 1RM · cohort position'**
  String get passportPreviewSubtitle;

  /// No description provided for @passportPreviewBody.
  ///
  /// In en, this message translates to:
  /// **'Every entry shows exactly why you earned the class and what separates you from the next one.'**
  String get passportPreviewBody;

  /// No description provided for @passportGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'HOW THE PASSPORT WORKS'**
  String get passportGuideTitle;

  /// No description provided for @strengthConstellation.
  ///
  /// In en, this message translates to:
  /// **'Strength Constellation'**
  String get strengthConstellation;

  /// No description provided for @constellationSignals.
  ///
  /// In en, this message translates to:
  /// **'{active}/{total} SIGNALS'**
  String constellationSignals(int active, int total);

  /// No description provided for @constellationBody.
  ///
  /// In en, this message translates to:
  /// **'Every ranked lift shapes your personal strength signature. Brightness reflects its median class.'**
  String get constellationBody;

  /// No description provided for @constellationEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'The faint coordinates preview the strength signature your first benchmark lifts will reveal.'**
  String get constellationEmptyBody;

  /// No description provided for @passportStepLiftTitle.
  ///
  /// In en, this message translates to:
  /// **'A lift earns an entry'**
  String get passportStepLiftTitle;

  /// No description provided for @passportStepLiftBody.
  ///
  /// In en, this message translates to:
  /// **'Your strongest estimated 1RM is normalized by bodyweight.'**
  String get passportStepLiftBody;

  /// No description provided for @passportStepMedianTitle.
  ///
  /// In en, this message translates to:
  /// **'The middle defines the field'**
  String get passportStepMedianTitle;

  /// No description provided for @passportStepMedianBody.
  ///
  /// In en, this message translates to:
  /// **'Ranks use the cohort median after both extreme deciles are removed.'**
  String get passportStepMedianBody;

  /// No description provided for @passportStepBreadthTitle.
  ///
  /// In en, this message translates to:
  /// **'Breadth earns the passport'**
  String get passportStepBreadthTitle;

  /// No description provided for @passportStepBreadthBody.
  ///
  /// In en, this message translates to:
  /// **'Your overall class is the median of at least three ranked movements.'**
  String get passportStepBreadthBody;

  /// No description provided for @aiSuggest.
  ///
  /// In en, this message translates to:
  /// **'AI SUGGEST'**
  String get aiSuggest;

  /// No description provided for @aiReviewPlan.
  ///
  /// In en, this message translates to:
  /// **'Review this plan against your history and results'**
  String get aiReviewPlan;

  /// No description provided for @aiReviewStagedTitle.
  ///
  /// In en, this message translates to:
  /// **'AI review is staged'**
  String get aiReviewStagedTitle;

  /// No description provided for @aiReviewStagedBody.
  ///
  /// In en, this message translates to:
  /// **'GymControl already collects the workout, recent history, account statistics and measurements securely on the server. Connect the model provider to activate the final analysis step.'**
  String get aiReviewStagedBody;

  /// No description provided for @aiReviewFailed.
  ///
  /// In en, this message translates to:
  /// **'The review could not be generated. Try again when the server is available.'**
  String get aiReviewFailed;

  /// No description provided for @buildWarmup.
  ///
  /// In en, this message translates to:
  /// **'Build warm-up'**
  String get buildWarmup;

  /// No description provided for @previousCompact.
  ///
  /// In en, this message translates to:
  /// **'PREV {value}'**
  String previousCompact(String value);

  /// No description provided for @trainingBrief.
  ///
  /// In en, this message translates to:
  /// **'TRAINING BRIEF'**
  String get trainingBrief;

  /// No description provided for @passportSignal.
  ///
  /// In en, this message translates to:
  /// **'Passport signal'**
  String get passportSignal;

  /// No description provided for @passportFirstBenchmark.
  ///
  /// In en, this message translates to:
  /// **'Log a benchmark set in your next workout. Your normal training can now issue the first passport entry automatically.'**
  String get passportFirstBenchmark;

  /// No description provided for @passportCalibration.
  ///
  /// In en, this message translates to:
  /// **'Passport calibration · {count}/3'**
  String passportCalibration(int count);

  /// No description provided for @passportCalibrationBody.
  ///
  /// In en, this message translates to:
  /// **'Add {count} more benchmark movements to reveal your overall class.'**
  String passportCalibrationBody(int count);

  /// No description provided for @passportClosestPromotion.
  ///
  /// In en, this message translates to:
  /// **'Closest promotion'**
  String get passportClosestPromotion;

  /// No description provided for @passportPromotionBody.
  ///
  /// In en, this message translates to:
  /// **'{exercise} · class {rank} → {next}. Your clearest route forward.'**
  String passportPromotionBody(String exercise, String rank, String next);

  /// No description provided for @passportHighestClass.
  ///
  /// In en, this message translates to:
  /// **'Passport at highest class'**
  String get passportHighestClass;

  /// No description provided for @passportHighestClassBody.
  ///
  /// In en, this message translates to:
  /// **'Your recorded benchmark movements have reached the top issued class.'**
  String get passportHighestClassBody;

  /// No description provided for @workoutComplete.
  ///
  /// In en, this message translates to:
  /// **'Workout complete'**
  String get workoutComplete;

  /// No description provided for @sessionSealed.
  ///
  /// In en, this message translates to:
  /// **'SESSION SEALED'**
  String get sessionSealed;

  /// No description provided for @sessionSealedBody.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device. Your training chain and supported benchmark lifts will sync into your Strength Passport.'**
  String get sessionSealedBody;

  /// No description provided for @setLogged.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{SET LOGGED} other{SETS LOGGED}}'**
  String setLogged(int count);

  /// No description provided for @volumeLifted.
  ///
  /// In en, this message translates to:
  /// **'VOLUME LIFTED'**
  String get volumeLifted;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get done;

  /// No description provided for @missionDebrief.
  ///
  /// In en, this message translates to:
  /// **'MISSION DEBRIEF'**
  String get missionDebrief;

  /// No description provided for @sealed.
  ///
  /// In en, this message translates to:
  /// **'SEALED'**
  String get sealed;

  /// No description provided for @baselineEstablished.
  ///
  /// In en, this message translates to:
  /// **'Baseline established'**
  String get baselineEstablished;

  /// No description provided for @baselineEstablishedBody.
  ///
  /// In en, this message translates to:
  /// **'This session is now the reference point for your next comparison.'**
  String get baselineEstablishedBody;

  /// No description provided for @outputRising.
  ///
  /// In en, this message translates to:
  /// **'Output rising'**
  String get outputRising;

  /// No description provided for @outputRisingBody.
  ///
  /// In en, this message translates to:
  /// **'Working volume is {percent}% above the comparable sets from your previous session.'**
  String outputRisingBody(int percent);

  /// No description provided for @outputSteady.
  ///
  /// In en, this message translates to:
  /// **'Signal stable'**
  String get outputSteady;

  /// No description provided for @outputSteadyBody.
  ///
  /// In en, this message translates to:
  /// **'Your comparable working sets stayed inside a controlled range.'**
  String get outputSteadyBody;

  /// No description provided for @recoverySignal.
  ///
  /// In en, this message translates to:
  /// **'Recovery signal'**
  String get recoverySignal;

  /// No description provided for @recoverySignalBody.
  ///
  /// In en, this message translates to:
  /// **'Volume eased from the previous session. Treat it as context, not a failed streak.'**
  String get recoverySignalBody;

  /// No description provided for @sessionDuration.
  ///
  /// In en, this message translates to:
  /// **'DURATION'**
  String get sessionDuration;

  /// No description provided for @shareRecord.
  ///
  /// In en, this message translates to:
  /// **'SHARE'**
  String get shareRecord;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not prepare the training card'**
  String get shareFailed;

  /// No description provided for @trainingRecord.
  ///
  /// In en, this message translates to:
  /// **'Training Record'**
  String get trainingRecord;

  /// No description provided for @personalRecord.
  ///
  /// In en, this message translates to:
  /// **'Personal Record'**
  String get personalRecord;

  /// No description provided for @strongestSignal.
  ///
  /// In en, this message translates to:
  /// **'STRONGEST SET'**
  String get strongestSignal;

  /// No description provided for @estimatedOneRmShort.
  ///
  /// In en, this message translates to:
  /// **'EST. 1RM'**
  String get estimatedOneRmShort;

  /// No description provided for @passportEntries.
  ///
  /// In en, this message translates to:
  /// **'PASSPORT'**
  String get passportEntries;

  /// No description provided for @signalTrail.
  ///
  /// In en, this message translates to:
  /// **'Signal Trail'**
  String get signalTrail;

  /// No description provided for @signalBaseline.
  ///
  /// In en, this message translates to:
  /// **'Building signal'**
  String get signalBaseline;

  /// No description provided for @signalRising.
  ///
  /// In en, this message translates to:
  /// **'Strength signal rising'**
  String get signalRising;

  /// No description provided for @signalStable.
  ///
  /// In en, this message translates to:
  /// **'Training signal stable'**
  String get signalStable;

  /// No description provided for @signalEasing.
  ///
  /// In en, this message translates to:
  /// **'Load signal eased'**
  String get signalEasing;

  /// No description provided for @signalDelta.
  ///
  /// In en, this message translates to:
  /// **'{percent}% from the first point in this view.'**
  String signalDelta(int percent);

  /// No description provided for @signalPlateauBody.
  ///
  /// In en, this message translates to:
  /// **'Recent points form a plateau — a useful cue to vary load, reps or recovery.'**
  String get signalPlateauBody;

  /// No description provided for @signalBaselineBody.
  ///
  /// In en, this message translates to:
  /// **'More sessions will reveal the direction of this training signal.'**
  String get signalBaselineBody;

  /// No description provided for @notEnoughSignalData.
  ///
  /// In en, this message translates to:
  /// **'Not enough signal data for this period'**
  String get notEnoughSignalData;

  /// No description provided for @recoveryOrbit.
  ///
  /// In en, this message translates to:
  /// **'Recovery Orbit'**
  String get recoveryOrbit;

  /// No description provided for @recoveryOrbitBaseline.
  ///
  /// In en, this message translates to:
  /// **'Awaiting first orbit'**
  String get recoveryOrbitBaseline;

  /// No description provided for @recoveryOrbitBaselineBody.
  ///
  /// In en, this message translates to:
  /// **'Your training rhythm will appear here after the first completed session.'**
  String get recoveryOrbitBaselineBody;

  /// No description provided for @recoveryOrbitRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery window'**
  String get recoveryOrbitRecovery;

  /// No description provided for @recoveryOrbitRecoveryBody.
  ///
  /// In en, this message translates to:
  /// **'Your recent output rose sharply. A quieter day may help consolidate it.'**
  String get recoveryOrbitRecoveryBody;

  /// No description provided for @recoveryOrbitReady.
  ///
  /// In en, this message translates to:
  /// **'Orbit is active'**
  String get recoveryOrbitReady;

  /// No description provided for @recoveryOrbitReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Recent training is close. Keep the next session intentional.'**
  String get recoveryOrbitReadyBody;

  /// No description provided for @recoveryOrbitBalanced.
  ///
  /// In en, this message translates to:
  /// **'Rhythm looks balanced'**
  String get recoveryOrbitBalanced;

  /// No description provided for @recoveryOrbitBalancedBody.
  ///
  /// In en, this message translates to:
  /// **'Training and space between sessions are moving in a measured rhythm.'**
  String get recoveryOrbitBalancedBody;

  /// No description provided for @recoveryOrbitReturning.
  ///
  /// In en, this message translates to:
  /// **'Return vector'**
  String get recoveryOrbitReturning;

  /// No description provided for @recoveryOrbitReturningBody.
  ///
  /// In en, this message translates to:
  /// **'The orbit has gone quiet. Restart with a controlled session, not a test.'**
  String get recoveryOrbitReturningBody;

  /// No description provided for @orbitActiveDays.
  ///
  /// In en, this message translates to:
  /// **'{count}/14 ACTIVE'**
  String orbitActiveDays(int count);

  /// No description provided for @daysSinceTraining.
  ///
  /// In en, this message translates to:
  /// **'DAYS SINCE TRAINING'**
  String get daysSinceTraining;

  /// No description provided for @recoveryOrbitDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'A training-rhythm signal based on logged sessions, not a medical readiness score.'**
  String get recoveryOrbitDisclaimer;

  /// No description provided for @usePreviousSet.
  ///
  /// In en, this message translates to:
  /// **'Use previous set values'**
  String get usePreviousSet;

  /// No description provided for @difficultyNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get difficultyNormal;

  /// No description provided for @difficultyDeload.
  ///
  /// In en, this message translates to:
  /// **'Deload'**
  String get difficultyDeload;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @syncLedger.
  ///
  /// In en, this message translates to:
  /// **'Sync ledger'**
  String get syncLedger;

  /// No description provided for @syncCurrent.
  ///
  /// In en, this message translates to:
  /// **'All changes are safely synced'**
  String get syncCurrent;

  /// No description provided for @syncOfflineSafe.
  ///
  /// In en, this message translates to:
  /// **'Offline · your changes are saved on this device'**
  String get syncOfflineSafe;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'{count} changes awaiting sync'**
  String syncPending(int count);

  /// No description provided for @syncRejected.
  ///
  /// In en, this message translates to:
  /// **'{count} changes need attention · tap to retry'**
  String syncRejected(int count);

  /// No description provided for @offlinePending.
  ///
  /// In en, this message translates to:
  /// **'Offline · {count, plural, =1{1 change} other{{count} changes}} will sync later'**
  String offlinePending(int count);

  /// No description provided for @offlineSaved.
  ///
  /// In en, this message translates to:
  /// **'Offline · changes are saved on this device'**
  String get offlineSaved;

  /// No description provided for @syncingChanges.
  ///
  /// In en, this message translates to:
  /// **'Syncing {count, plural, =1{1 change} other{{count} changes}}…'**
  String syncingChanges(int count);

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @weightUnits.
  ///
  /// In en, this message translates to:
  /// **'Weight units'**
  String get weightUnits;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addNote;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get editNote;

  /// No description provided for @groupWithNext.
  ///
  /// In en, this message translates to:
  /// **'Group with next…'**
  String get groupWithNext;

  /// No description provided for @extendGroup.
  ///
  /// In en, this message translates to:
  /// **'Extend group to next…'**
  String get extendGroup;

  /// No description provided for @removeExerciseGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove exercise group'**
  String get removeExerciseGroup;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @removeExercise.
  ///
  /// In en, this message translates to:
  /// **'Remove exercise'**
  String get removeExercise;

  /// No description provided for @trainingGroup.
  ///
  /// In en, this message translates to:
  /// **'Training group'**
  String get trainingGroup;

  /// No description provided for @trainingGroupBody.
  ///
  /// In en, this message translates to:
  /// **'Grouped exercises advance without starting the rest timer until the round is complete.'**
  String get trainingGroupBody;

  /// No description provided for @superset.
  ///
  /// In en, this message translates to:
  /// **'Superset'**
  String get superset;

  /// No description provided for @circuit.
  ///
  /// In en, this message translates to:
  /// **'Circuit'**
  String get circuit;

  /// No description provided for @intervalBlock.
  ///
  /// In en, this message translates to:
  /// **'Interval block'**
  String get intervalBlock;

  /// No description provided for @exerciseNote.
  ///
  /// In en, this message translates to:
  /// **'Exercise note'**
  String get exerciseNote;

  /// No description provided for @exerciseNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Form cues, pain, target for next time…'**
  String get exerciseNoteHint;

  /// No description provided for @quitWorkoutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Quit workout?'**
  String get quitWorkoutQuestion;

  /// No description provided for @quitWorkoutBody.
  ///
  /// In en, this message translates to:
  /// **'This workout and all checked sets will be discarded.'**
  String get quitWorkoutBody;

  /// No description provided for @keepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get keepGoing;

  /// No description provided for @quit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get quit;

  /// No description provided for @finishWorkoutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Finish workout?'**
  String get finishWorkoutQuestion;

  /// No description provided for @finishWorkoutBody.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} sets are complete. Choose how you want to finish.'**
  String finishWorkoutBody(int done, int total);

  /// No description provided for @finishWithoutSaving.
  ///
  /// In en, this message translates to:
  /// **'Finish without saving'**
  String get finishWithoutSaving;

  /// No description provided for @saveKeepRoutine.
  ///
  /// In en, this message translates to:
  /// **'Save · keep routine'**
  String get saveKeepRoutine;

  /// No description provided for @finishAndSave.
  ///
  /// In en, this message translates to:
  /// **'Finish and save'**
  String get finishAndSave;

  /// No description provided for @saveUpdateRoutine.
  ///
  /// In en, this message translates to:
  /// **'Save · update routine'**
  String get saveUpdateRoutine;

  /// No description provided for @couldNotSaveWorkout.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save workout'**
  String get couldNotSaveWorkout;

  /// No description provided for @setColumn.
  ///
  /// In en, this message translates to:
  /// **'SET'**
  String get setColumn;

  /// No description provided for @setType.
  ///
  /// In en, this message translates to:
  /// **'Set type'**
  String get setType;

  /// No description provided for @progressionTag.
  ///
  /// In en, this message translates to:
  /// **'Progression tag…'**
  String get progressionTag;

  /// No description provided for @progressionValue.
  ///
  /// In en, this message translates to:
  /// **'Progression: {value}'**
  String progressionValue(String value);

  /// No description provided for @setProgressQuestion.
  ///
  /// In en, this message translates to:
  /// **'How did this set progress?'**
  String get setProgressQuestion;

  /// No description provided for @noProgressionTag.
  ///
  /// In en, this message translates to:
  /// **'No progression tag'**
  String get noProgressionTag;

  /// No description provided for @perceivedExertion.
  ///
  /// In en, this message translates to:
  /// **'Rate of perceived exertion'**
  String get perceivedExertion;

  /// No description provided for @perceivedExertionQuestion.
  ///
  /// In en, this message translates to:
  /// **'How hard did this set feel?'**
  String get perceivedExertionQuestion;

  /// No description provided for @clearRpe.
  ///
  /// In en, this message translates to:
  /// **'Clear RPE'**
  String get clearRpe;

  /// No description provided for @startNewWorkoutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Start a new workout?'**
  String get startNewWorkoutQuestion;

  /// No description provided for @activeWorkoutBody.
  ///
  /// In en, this message translates to:
  /// **'You have an active session in progress. Starting this one will discard it.'**
  String get activeWorkoutBody;

  /// No description provided for @resumeActive.
  ///
  /// In en, this message translates to:
  /// **'Resume active'**
  String get resumeActive;

  /// No description provided for @startNew.
  ///
  /// In en, this message translates to:
  /// **'Start new'**
  String get startNew;

  /// No description provided for @configureWorkout.
  ///
  /// In en, this message translates to:
  /// **'Configure workout'**
  String get configureWorkout;

  /// No description provided for @configureWorkoutBody.
  ///
  /// In en, this message translates to:
  /// **'Optional exercises and alternatives can change each session.'**
  String get configureWorkoutBody;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @chooseOne.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE ONE'**
  String get chooseOne;

  /// No description provided for @alternative.
  ///
  /// In en, this message translates to:
  /// **'Alternative'**
  String get alternative;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @copySavedBody.
  ///
  /// In en, this message translates to:
  /// **'A private copy was added to your workouts. Open “Mine” to launch or edit it.'**
  String get copySavedBody;

  /// No description provided for @couldNotSaveCopy.
  ///
  /// In en, this message translates to:
  /// **'Could not save a copy'**
  String get couldNotSaveCopy;

  /// No description provided for @whatWorks.
  ///
  /// In en, this message translates to:
  /// **'What works'**
  String get whatWorks;

  /// No description provided for @watch.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get watch;

  /// No description provided for @nextFocus.
  ///
  /// In en, this message translates to:
  /// **'Next focus'**
  String get nextFocus;

  /// No description provided for @deleteWorkoutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete workout?'**
  String get deleteWorkoutQuestion;

  /// No description provided for @workoutHistory.
  ///
  /// In en, this message translates to:
  /// **'Workout history'**
  String get workoutHistory;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @averageTime.
  ///
  /// In en, this message translates to:
  /// **'Avg time'**
  String get averageTime;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @ranked.
  ///
  /// In en, this message translates to:
  /// **'Ranked'**
  String get ranked;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @hardSets.
  ///
  /// In en, this message translates to:
  /// **'Hard sets'**
  String get hardSets;

  /// No description provided for @longestWorkout.
  ///
  /// In en, this message translates to:
  /// **'Longest workout'**
  String get longestWorkout;

  /// No description provided for @favoriteExercise.
  ///
  /// In en, this message translates to:
  /// **'Favorite exercise'**
  String get favoriteExercise;

  /// No description provided for @strongestBodyweight.
  ///
  /// In en, this message translates to:
  /// **'Strongest (vs bodyweight)'**
  String get strongestBodyweight;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @imageUrl.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get imageUrl;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @bodyMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Body Measurements'**
  String get bodyMeasurements;

  /// No description provided for @deleteMeasurementQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete measurement?'**
  String get deleteMeasurementQuestion;

  /// No description provided for @deleteMeasurementBody.
  ///
  /// In en, this message translates to:
  /// **'The entry from {date} will be removed.'**
  String deleteMeasurementBody(String date);

  /// No description provided for @couldNotLoadRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not load · Retry'**
  String get couldNotLoadRetry;

  /// No description provided for @saveMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Save measurement'**
  String get saveMeasurement;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get termsOfUse;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @logoutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutQuestion;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountCaption.
  ///
  /// In en, this message translates to:
  /// **'Permanently deletes your workouts, exercise history and profile. This cannot be undone.'**
  String get deleteAccountCaption;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account, workouts, exercise history and profile. This cannot be undone.'**
  String get deleteAccountBody;

  /// No description provided for @couldNotDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Could not delete account'**
  String get couldNotDeleteAccount;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @deleteFolder.
  ///
  /// In en, this message translates to:
  /// **'Delete folder'**
  String get deleteFolder;

  /// No description provided for @deleteFolderQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String deleteFolderQuestion(String name);

  /// No description provided for @moveWorkout.
  ///
  /// In en, this message translates to:
  /// **'Move “{name}”'**
  String moveWorkout(String name);

  /// No description provided for @defaultFolder.
  ///
  /// In en, this message translates to:
  /// **'Default folder'**
  String get defaultFolder;

  /// No description provided for @couldNotSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save changes'**
  String get couldNotSaveChanges;

  /// No description provided for @sortWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Sort workouts'**
  String get sortWorkouts;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get newFolder;

  /// No description provided for @openWorkout.
  ///
  /// In en, this message translates to:
  /// **'Open {name}'**
  String openWorkout(String name);

  /// No description provided for @couldNotVerifyPro.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t verify Pro access'**
  String get couldNotVerifyPro;

  /// No description provided for @warmupSet.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get warmupSet;

  /// No description provided for @warmupSetBody.
  ///
  /// In en, this message translates to:
  /// **'Excluded from working volume'**
  String get warmupSetBody;

  /// No description provided for @workingSet.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get workingSet;

  /// No description provided for @workingSetBody.
  ///
  /// In en, this message translates to:
  /// **'Counts toward volume and PRs'**
  String get workingSetBody;

  /// No description provided for @failureSet.
  ///
  /// In en, this message translates to:
  /// **'Failure'**
  String get failureSet;

  /// No description provided for @failureSetBody.
  ///
  /// In en, this message translates to:
  /// **'Taken to muscular failure'**
  String get failureSetBody;

  /// No description provided for @dropSet.
  ///
  /// In en, this message translates to:
  /// **'Drop set'**
  String get dropSet;

  /// No description provided for @dropSetBody.
  ///
  /// In en, this message translates to:
  /// **'Reduced load without a full rest period'**
  String get dropSetBody;

  /// No description provided for @heavierWeight.
  ///
  /// In en, this message translates to:
  /// **'Heavier weight'**
  String get heavierWeight;

  /// No description provided for @greaterAmplitude.
  ///
  /// In en, this message translates to:
  /// **'Greater amplitude'**
  String get greaterAmplitude;

  /// No description provided for @betterEfficiency.
  ///
  /// In en, this message translates to:
  /// **'Better efficiency'**
  String get betterEfficiency;

  /// No description provided for @meoSet.
  ///
  /// In en, this message translates to:
  /// **'MEO / myo-rep set'**
  String get meoSet;

  /// No description provided for @weightKgLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKgLabel;

  /// No description provided for @heightCmLabel.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get heightCmLabel;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get couldNotOpenLink;

  /// No description provided for @noDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'No diagnostics to send'**
  String get noDiagnostics;

  /// No description provided for @diagnosticsEmpty.
  ///
  /// In en, this message translates to:
  /// **'The local diagnostic buffer is currently empty.'**
  String get diagnosticsEmpty;

  /// No description provided for @sendDiagnosticsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Send diagnostics?'**
  String get sendDiagnosticsQuestion;

  /// No description provided for @sendDiagnosticsBody.
  ///
  /// In en, this message translates to:
  /// **'This sends {count} technical events to GymControl support. Tokens, email, workout contents, comments and stack traces are not included.'**
  String sendDiagnosticsBody(int count);

  /// No description provided for @diagnosticsSent.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics sent'**
  String get diagnosticsSent;

  /// No description provided for @diagnosticsSentBody.
  ///
  /// In en, this message translates to:
  /// **'{count} events sent. Reference: {reference}'**
  String diagnosticsSentBody(int count, String reference);

  /// No description provided for @diagnosticsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send diagnostics'**
  String get diagnosticsFailed;

  /// No description provided for @diagnosticsFailedBody.
  ///
  /// In en, this message translates to:
  /// **'The events remain on this device. Check your connection and try again.'**
  String get diagnosticsFailedBody;

  /// No description provided for @shareDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Share technical diagnostics automatically'**
  String get shareDiagnostics;

  /// No description provided for @diagnosticsPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Helps us detect app errors. Includes only event codes, app version and platform; never email, workout content, tokens or stack traces.'**
  String get diagnosticsPrivacyBody;

  /// No description provided for @exerciseIllustrations.
  ///
  /// In en, this message translates to:
  /// **'Exercise illustrations'**
  String get exerciseIllustrations;

  /// No description provided for @exerciseIllustrationsCredit.
  ///
  /// In en, this message translates to:
  /// **'Muscle-highlight illustrations © Everkinetic, used under the Creative Commons Attribution-ShareAlike license (CC BY-SA).'**
  String get exerciseIllustrationsCredit;

  /// No description provided for @exerciseData.
  ///
  /// In en, this message translates to:
  /// **'Exercise data'**
  String get exerciseData;

  /// No description provided for @exerciseDataCredit.
  ///
  /// In en, this message translates to:
  /// **'Exercise catalog based on the free-exercise-db, released into the public domain under The Unlicense.'**
  String get exerciseDataCredit;

  /// No description provided for @warmupCalculator.
  ///
  /// In en, this message translates to:
  /// **'Warm-up calculator'**
  String get warmupCalculator;

  /// No description provided for @workingKg.
  ///
  /// In en, this message translates to:
  /// **'Working kg'**
  String get workingKg;

  /// No description provided for @barKg.
  ///
  /// In en, this message translates to:
  /// **'Bar kg'**
  String get barKg;

  /// No description provided for @plateCalculator.
  ///
  /// In en, this message translates to:
  /// **'Plate calculator'**
  String get plateCalculator;

  /// No description provided for @totalKg.
  ///
  /// In en, this message translates to:
  /// **'Total kg'**
  String get totalKg;

  /// No description provided for @pickExercise.
  ///
  /// In en, this message translates to:
  /// **'Pick exercise'**
  String get pickExercise;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @anyEquipment.
  ///
  /// In en, this message translates to:
  /// **'Any equipment'**
  String get anyEquipment;

  /// No description provided for @optionalBody.
  ///
  /// In en, this message translates to:
  /// **'Choose whether to include it when starting'**
  String get optionalBody;

  /// No description provided for @alternativePrevious.
  ///
  /// In en, this message translates to:
  /// **'Alternative to previous'**
  String get alternativePrevious;

  /// No description provided for @alternativePreviousBody.
  ///
  /// In en, this message translates to:
  /// **'Pick one of the two when starting'**
  String get alternativePreviousBody;

  /// No description provided for @restSeconds.
  ///
  /// In en, this message translates to:
  /// **'Rest (s)'**
  String get restSeconds;

  /// No description provided for @repsShort.
  ///
  /// In en, this message translates to:
  /// **'reps'**
  String get repsShort;

  /// No description provided for @quickSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick setup'**
  String get quickSetupTitle;

  /// No description provided for @quickSetupBody.
  ///
  /// In en, this message translates to:
  /// **'Optional — helps calculate your strength rank'**
  String get quickSetupBody;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @updateYourWeight.
  ///
  /// In en, this message translates to:
  /// **'Update your weight?'**
  String get updateYourWeight;

  /// No description provided for @weightReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Your weight keeps strength rankings accurate. It takes five seconds.'**
  String get weightReminderBody;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @dontAskAgain.
  ///
  /// In en, this message translates to:
  /// **'Don\'t ask again'**
  String get dontAskAgain;

  /// No description provided for @rankLegend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get rankLegend;

  /// No description provided for @rankElite.
  ///
  /// In en, this message translates to:
  /// **'Elite'**
  String get rankElite;

  /// No description provided for @rankExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get rankExpert;

  /// No description provided for @rankAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get rankAdvanced;

  /// No description provided for @rankIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get rankIntermediate;

  /// No description provided for @rankBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get rankBeginner;

  /// No description provided for @rankNovice.
  ///
  /// In en, this message translates to:
  /// **'Novice'**
  String get rankNovice;

  /// No description provided for @addYourWeight.
  ///
  /// In en, this message translates to:
  /// **'Add your weight'**
  String get addYourWeight;

  /// No description provided for @weightRankAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Required for accurate strength rankings'**
  String get weightRankAccuracy;

  /// No description provided for @rankQuoteE.
  ///
  /// In en, this message translates to:
  /// **'Every champion was once a beginner. Start now.'**
  String get rankQuoteE;

  /// No description provided for @rankQuoteD.
  ///
  /// In en, this message translates to:
  /// **'Consistency beats talent. Keep showing up.'**
  String get rankQuoteD;

  /// No description provided for @rankQuoteC.
  ///
  /// In en, this message translates to:
  /// **'You\'re in the top half. Push harder.'**
  String get rankQuoteC;

  /// No description provided for @rankQuoteB.
  ///
  /// In en, this message translates to:
  /// **'Advanced territory. You\'re doing great.'**
  String get rankQuoteB;

  /// No description provided for @rankQuoteA.
  ///
  /// In en, this message translates to:
  /// **'Expert level. The elite tier awaits.'**
  String get rankQuoteA;

  /// No description provided for @rankQuoteS.
  ///
  /// In en, this message translates to:
  /// **'Elite athlete. One step from legendary.'**
  String get rankQuoteS;

  /// No description provided for @rankQuoteSS.
  ///
  /// In en, this message translates to:
  /// **'You are legendary. Inspire others.'**
  String get rankQuoteSS;

  /// No description provided for @keepTraining.
  ///
  /// In en, this message translates to:
  /// **'Keep training.'**
  String get keepTraining;

  /// No description provided for @recordLift.
  ///
  /// In en, this message translates to:
  /// **'Record lift'**
  String get recordLift;

  /// No description provided for @exercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get exercise;

  /// No description provided for @benchPress.
  ///
  /// In en, this message translates to:
  /// **'Bench press'**
  String get benchPress;

  /// No description provided for @squat.
  ///
  /// In en, this message translates to:
  /// **'Squat'**
  String get squat;

  /// No description provided for @deadlift.
  ///
  /// In en, this message translates to:
  /// **'Deadlift'**
  String get deadlift;

  /// No description provided for @overheadPress.
  ///
  /// In en, this message translates to:
  /// **'Overhead press'**
  String get overheadPress;

  /// No description provided for @barbellRow.
  ///
  /// In en, this message translates to:
  /// **'Barbell row'**
  String get barbellRow;

  /// No description provided for @enterValidWeightReps.
  ///
  /// In en, this message translates to:
  /// **'Enter valid weight and reps'**
  String get enterValidWeightReps;

  /// No description provided for @estimatedOneRmValue.
  ///
  /// In en, this message translates to:
  /// **'Est. 1RM: {value} kg'**
  String estimatedOneRmValue(String value);

  /// No description provided for @savePr.
  ///
  /// In en, this message translates to:
  /// **'Save PR'**
  String get savePr;

  /// No description provided for @bodyMetricsRankBody.
  ///
  /// In en, this message translates to:
  /// **'Used to compute your relative strength score.'**
  String get bodyMetricsRankBody;

  /// No description provided for @topPercent.
  ///
  /// In en, this message translates to:
  /// **'Top {value}%'**
  String topPercent(String value);

  /// No description provided for @liftSummary.
  ///
  /// In en, this message translates to:
  /// **'{weight} kg × {reps} · est. 1RM: {oneRm} kg'**
  String liftSummary(String weight, int reps, String oneRm);

  /// No description provided for @medianMultiple.
  ///
  /// In en, this message translates to:
  /// **'{value}× median'**
  String medianMultiple(String value);

  /// No description provided for @couldNotLoadRankings.
  ///
  /// In en, this message translates to:
  /// **'Could not load strength rankings'**
  String get couldNotLoadRankings;

  /// No description provided for @loadBaseline.
  ///
  /// In en, this message translates to:
  /// **'Building your baseline'**
  String get loadBaseline;

  /// No description provided for @loadIncreased.
  ///
  /// In en, this message translates to:
  /// **'Load increased quickly'**
  String get loadIncreased;

  /// No description provided for @loadTrendingDown.
  ///
  /// In en, this message translates to:
  /// **'Load is trending down'**
  String get loadTrendingDown;

  /// No description provided for @loadSteady.
  ///
  /// In en, this message translates to:
  /// **'Load is progressing steadily'**
  String get loadSteady;

  /// No description provided for @compareLast28Days.
  ///
  /// In en, this message translates to:
  /// **'Last 28 days compared with the previous 28 days'**
  String get compareLast28Days;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @averageRpe.
  ///
  /// In en, this message translates to:
  /// **'Avg RPE'**
  String get averageRpe;

  /// No description provided for @workingVolume.
  ///
  /// In en, this message translates to:
  /// **'Working volume'**
  String get workingVolume;

  /// No description provided for @workoutsPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Workouts per month'**
  String get workoutsPerMonth;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @kgShort.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kgShort;

  /// No description provided for @hourShort.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hourShort;

  /// No description provided for @kmShort.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get kmShort;

  /// No description provided for @liftsUnit.
  ///
  /// In en, this message translates to:
  /// **'lifts'**
  String get liftsUnit;

  /// No description provided for @trainingVolumeChartNote.
  ///
  /// In en, this message translates to:
  /// **'Weight × reps per training day · warm-ups excluded'**
  String get trainingVolumeChartNote;

  /// No description provided for @recordLiftForStats.
  ///
  /// In en, this message translates to:
  /// **'Record a lift in Strength Passport to start\ntracking your strength progress.'**
  String get recordLiftForStats;

  /// No description provided for @rankLabel.
  ///
  /// In en, this message translates to:
  /// **'Rank {rank}'**
  String rankLabel(String rank);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String durationMinutes(int minutes);

  /// No description provided for @proTrainWithoutLimits.
  ///
  /// In en, this message translates to:
  /// **'Train without limits'**
  String get proTrainWithoutLimits;

  /// No description provided for @proDescription.
  ///
  /// In en, this message translates to:
  /// **'Organize unlimited workouts into folders and create more than five personal programs.'**
  String get proDescription;

  /// No description provided for @proUnlimitedWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Unlimited personal workouts'**
  String get proUnlimitedWorkouts;

  /// No description provided for @proCustomFolders.
  ///
  /// In en, this message translates to:
  /// **'Custom workout folders'**
  String get proCustomFolders;

  /// No description provided for @proOrganizeLibrary.
  ///
  /// In en, this message translates to:
  /// **'Rename and organize your library'**
  String get proOrganizeLibrary;

  /// No description provided for @proAiReview.
  ///
  /// In en, this message translates to:
  /// **'AI review of training and progression'**
  String get proAiReview;

  /// No description provided for @proPriceMonthly.
  ///
  /// In en, this message translates to:
  /// **'\$5 / month'**
  String get proPriceMonthly;

  /// No description provided for @proCancelAnytime.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime · No trial'**
  String get proCancelAnytime;

  /// No description provided for @proPurchasesSoon.
  ///
  /// In en, this message translates to:
  /// **'PURCHASES COMING SOON'**
  String get proPurchasesSoon;
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
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
