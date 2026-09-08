// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionBodyMetrics => 'Body Metrics';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get sectionAccount => 'Account';

  @override
  String get sectionApp => 'App';

  @override
  String get sectionLanguage => 'Language';

  @override
  String get labelWeight => 'Weight';

  @override
  String get labelHeight => 'Height';

  @override
  String get labelDarkMode => 'Dark Mode';

  @override
  String get labelAccentColor => 'Accent Color';

  @override
  String get accentBlue => 'Cobalt';

  @override
  String get accentRed => 'Red';

  @override
  String get accentPurple => 'Purple';

  @override
  String get accentGreen => 'Green';

  @override
  String get labelNotifications => 'Notifications';

  @override
  String get labelAbout => 'About';

  @override
  String get labelReenableWeightReminders => 'Re-enable weight reminders';

  @override
  String get labelLanguage => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Russian';

  @override
  String get logOut => 'Log Out';

  @override
  String get signIn => 'Sign In';

  @override
  String get createAccount => 'Create Account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get passwordMin => 'Password (min 8 chars)';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get continueGoogle => 'Continue with Google';

  @override
  String get or => 'or';

  @override
  String get noAccount => 'Don\'t have an account? ';

  @override
  String get register => 'Register';

  @override
  String get alreadyAccount => 'Already have an account? ';

  @override
  String get explore => 'Explore';

  @override
  String get weekStreak => 'WEEK STREAK';

  @override
  String get nextGoal => 'NEXT GOAL';

  @override
  String get routines => 'ROUTINES';

  @override
  String get workouts => 'Workouts';

  @override
  String get workoutsSubtitle => 'Programs and routines';

  @override
  String get progress => 'Progress';

  @override
  String get progressSubtitle => 'History and personal records';

  @override
  String get strengthPassport => 'Strength Passport';

  @override
  String get strengthPassportSubtitle => 'Your median-ranked strength identity';

  @override
  String get exercises => 'Exercises';

  @override
  String get exercisesSubtitle => 'Movement library';

  @override
  String get settingsSubtitle => 'Preferences and account';

  @override
  String get startWorkout => 'Start workout';

  @override
  String get rankedLifts => 'RANKED LIFTS';

  @override
  String get bodyweight => 'BODYWEIGHT';

  @override
  String get bestLift => 'BEST LIFT';

  @override
  String get medianRankedNote => 'Median-ranked · extreme results excluded';

  @override
  String get passportLocked => 'Record 3+ exercises\nto issue your passport';

  @override
  String get resumeWorkout => 'Resume active workout';

  @override
  String get chooseWorkout => 'Choose a workout';

  @override
  String resumeSummary(String elapsed, int done, int total) {
    return '$elapsed · $done/$total sets · tap to resume';
  }

  @override
  String get repetitions => 'Repetitions';

  @override
  String weightField(String unit) {
    return 'Weight in $unit';
  }

  @override
  String get restoringSession => 'Restoring your session…';

  @override
  String get gettingReady => 'Getting things ready…';

  @override
  String get takingLonger => 'This is taking longer than expected.';

  @override
  String get tryAgain => 'Try again';

  @override
  String mineCount(int count) {
    return 'Mine ($count)';
  }

  @override
  String libraryCount(int count) {
    return 'Library ($count)';
  }

  @override
  String get library => 'Library';

  @override
  String get allWorkouts => 'All workouts';

  @override
  String get searchWorkouts => 'Search all workouts';

  @override
  String get noWorkoutsFound => 'No workouts found';

  @override
  String get noWorkoutsYet => 'No workouts yet';

  @override
  String get libraryEmpty => 'Library is empty';

  @override
  String get createWorkout => 'Create workout';

  @override
  String get couldNotLoadWorkouts => 'Could not load workouts';

  @override
  String get retry => 'Retry';

  @override
  String get sortExercises => 'Sort exercises';

  @override
  String searchExercises(int count) {
    return 'Search $count exercises';
  }

  @override
  String get catalog => 'Catalog';

  @override
  String get myExercises => 'My exercises';

  @override
  String get noExercisesFound => 'No exercises found';

  @override
  String get yourStats => 'Your Stats';

  @override
  String get noDataYet => 'No data yet';

  @override
  String get personalRecords => 'Personal Records';

  @override
  String get couldNotLoadExercises => 'Could not load exercises';

  @override
  String get newExercise => 'New exercise';

  @override
  String get statistics => 'Statistics';

  @override
  String get trainingWorkload => 'Training Workload';

  @override
  String get workoutCalendar => 'Workout Calendar';

  @override
  String get trainingTrends => 'Training Trends';

  @override
  String get finishWorkoutForTrends => 'Finish a workout to see trends';

  @override
  String get noStatsYet => 'No stats yet';

  @override
  String get highlights => 'Highlights';

  @override
  String get noSessionsYet => 'No sessions yet';

  @override
  String get all => 'All';

  @override
  String get recordStartsHere => 'Your record starts here';

  @override
  String get recordStartsBody =>
      'Complete a working set to unlock mastery, personal records and a progression trail.';

  @override
  String get estimatedOneRm => 'ESTIMATED 1RM';

  @override
  String get currentPowerMark => 'Current power mark';

  @override
  String get heaviestSet => 'HEAVIEST SET';

  @override
  String sessionsLogged(int count) {
    return '$count sessions logged';
  }

  @override
  String get workingSets => 'WORKING SETS';

  @override
  String totalReps(int count) {
    return '$count total reps';
  }

  @override
  String get bestSetVolume => 'BEST SET VOLUME';

  @override
  String get peakSingleSetWork => 'Peak single-set work';

  @override
  String masteryLevel(int level) {
    return 'MASTERY LEVEL $level';
  }

  @override
  String rankAndLevel(String rank, int level) {
    return 'RANK $rank · LEVEL $level';
  }

  @override
  String setsToNextLevel(int count, int level) {
    return '$count working sets to level $level';
  }

  @override
  String get masteryInitiate => 'Initiate';

  @override
  String get masteryTrained => 'Trained';

  @override
  String get masteryProven => 'Proven';

  @override
  String get masteryVeteran => 'Veteran';

  @override
  String get masteryMaster => 'Master';

  @override
  String get lockedStatsPreview => 'LEVEL 1 · FIRST PR · PROGRESSION TRAIL';

  @override
  String passportRatioSummary(String ratio, int count) {
    return '$ratio× cohort median · median of $count ranked lifts';
  }

  @override
  String passportTierProgress(String remaining, String next, int progress) {
    return '$remaining× median to $next · $progress% through this rank';
  }

  @override
  String exerciseMedianProgress(String ratio, String next) {
    return '$ratio× median · next $next';
  }

  @override
  String get medianCalibrationPending => 'Median calibration pending';

  @override
  String get passportNoLiftsTitle => 'No lifts recorded yet';

  @override
  String get passportNoLiftsBody =>
      'Record a benchmark lift to issue your passport. Three ranked movements unlock the overall class.';

  @override
  String get passportPreviewTitle => 'PASSPORT ENTRY · PREVIEW';

  @override
  String get passportPreviewExercise => 'Bench Press';

  @override
  String get passportPreviewSubtitle =>
      'Your best set · estimated 1RM · cohort position';

  @override
  String get passportPreviewBody =>
      'Every entry shows exactly why you earned the class and what separates you from the next one.';

  @override
  String get passportGuideTitle => 'HOW THE PASSPORT WORKS';

  @override
  String get strengthConstellation => 'Strength Constellation';

  @override
  String constellationSignals(int active, int total) {
    return '$active/$total SIGNALS';
  }

  @override
  String get constellationBody =>
      'Every ranked lift shapes your personal strength signature. Brightness reflects its median class.';

  @override
  String get constellationEmptyBody =>
      'The faint coordinates preview the strength signature your first benchmark lifts will reveal.';

  @override
  String get passportStepLiftTitle => 'A lift earns an entry';

  @override
  String get passportStepLiftBody =>
      'Your strongest estimated 1RM is normalized by bodyweight.';

  @override
  String get passportStepMedianTitle => 'The middle defines the field';

  @override
  String get passportStepMedianBody =>
      'Ranks use the cohort median after both extreme deciles are removed.';

  @override
  String get passportStepBreadthTitle => 'Breadth earns the passport';

  @override
  String get passportStepBreadthBody =>
      'Your overall class is the median of at least three ranked movements.';

  @override
  String get aiSuggest => 'AI SUGGEST';

  @override
  String get aiReviewPlan =>
      'Review this plan against your history and results';

  @override
  String get aiReviewStagedTitle => 'AI review is staged';

  @override
  String get aiReviewStagedBody =>
      'GymControl already collects the workout, recent history, account statistics and measurements securely on the server. Connect the model provider to activate the final analysis step.';

  @override
  String get aiReviewFailed =>
      'The review could not be generated. Try again when the server is available.';

  @override
  String get buildWarmup => 'Build warm-up';

  @override
  String previousCompact(String value) {
    return 'PREV $value';
  }

  @override
  String get trainingBrief => 'TRAINING BRIEF';

  @override
  String get passportSignal => 'Passport signal';

  @override
  String get passportFirstBenchmark =>
      'Log a benchmark set in your next workout. Your normal training can now issue the first passport entry automatically.';

  @override
  String passportCalibration(int count) {
    return 'Passport calibration · $count/3';
  }

  @override
  String passportCalibrationBody(int count) {
    return 'Add $count more benchmark movements to reveal your overall class.';
  }

  @override
  String get passportClosestPromotion => 'Closest promotion';

  @override
  String passportPromotionBody(String exercise, String rank, String next) {
    return '$exercise · class $rank → $next. Your clearest route forward.';
  }

  @override
  String get passportHighestClass => 'Passport at highest class';

  @override
  String get passportHighestClassBody =>
      'Your recorded benchmark movements have reached the top issued class.';

  @override
  String get workoutComplete => 'Workout complete';

  @override
  String get sessionSealed => 'SESSION SEALED';

  @override
  String get sessionSealedBody =>
      'Saved on this device. Weekly streak and supported benchmark lifts will sync into your Strength Passport.';

  @override
  String setLogged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'SETS LOGGED',
      one: 'SET LOGGED',
    );
    return '$_temp0';
  }

  @override
  String get volumeLifted => 'VOLUME LIFTED';

  @override
  String get done => 'DONE';

  @override
  String get missionDebrief => 'MISSION DEBRIEF';

  @override
  String get sealed => 'SEALED';

  @override
  String get baselineEstablished => 'Baseline established';

  @override
  String get baselineEstablishedBody =>
      'This session is now the reference point for your next comparison.';

  @override
  String get outputRising => 'Output rising';

  @override
  String outputRisingBody(int percent) {
    return 'Working volume is $percent% above the comparable sets from your previous session.';
  }

  @override
  String get outputSteady => 'Signal stable';

  @override
  String get outputSteadyBody =>
      'Your comparable working sets stayed inside a controlled range.';

  @override
  String get recoverySignal => 'Recovery signal';

  @override
  String get recoverySignalBody =>
      'Volume eased from the previous session. Treat it as context, not a failed streak.';

  @override
  String get sessionDuration => 'DURATION';

  @override
  String get shareRecord => 'SHARE';

  @override
  String get shareFailed => 'Could not prepare the training card';

  @override
  String get trainingRecord => 'Training Record';

  @override
  String get personalRecord => 'Personal Record';

  @override
  String get strongestSignal => 'STRONGEST SET';

  @override
  String get estimatedOneRmShort => 'EST. 1RM';

  @override
  String get passportEntries => 'PASSPORT';

  @override
  String get signalTrail => 'Signal Trail';

  @override
  String get signalBaseline => 'Building signal';

  @override
  String get signalRising => 'Strength signal rising';

  @override
  String get signalStable => 'Training signal stable';

  @override
  String get signalEasing => 'Load signal eased';

  @override
  String signalDelta(int percent) {
    return '$percent% from the first point in this view.';
  }

  @override
  String get signalPlateauBody =>
      'Recent points form a plateau — a useful cue to vary load, reps or recovery.';

  @override
  String get signalBaselineBody =>
      'More sessions will reveal the direction of this training signal.';

  @override
  String get notEnoughSignalData => 'Not enough signal data for this period';

  @override
  String get recoveryOrbit => 'Recovery Orbit';

  @override
  String get recoveryOrbitBaseline => 'Awaiting first orbit';

  @override
  String get recoveryOrbitBaselineBody =>
      'Your training rhythm will appear here after the first completed session.';

  @override
  String get recoveryOrbitRecovery => 'Recovery window';

  @override
  String get recoveryOrbitRecoveryBody =>
      'Your recent output rose sharply. A quieter day may help consolidate it.';

  @override
  String get recoveryOrbitReady => 'Orbit is active';

  @override
  String get recoveryOrbitReadyBody =>
      'Recent training is close. Keep the next session intentional.';

  @override
  String get recoveryOrbitBalanced => 'Rhythm looks balanced';

  @override
  String get recoveryOrbitBalancedBody =>
      'Training and space between sessions are moving in a measured rhythm.';

  @override
  String get recoveryOrbitReturning => 'Return vector';

  @override
  String get recoveryOrbitReturningBody =>
      'The orbit has gone quiet. Restart with a controlled session, not a test.';

  @override
  String orbitActiveDays(int count) {
    return '$count/14 ACTIVE';
  }

  @override
  String get daysSinceTraining => 'DAYS SINCE TRAINING';

  @override
  String get recoveryOrbitDisclaimer =>
      'A training-rhythm signal based on logged sessions, not a medical readiness score.';

  @override
  String get usePreviousSet => 'Use previous set values';

  @override
  String get difficultyNormal => 'Normal';

  @override
  String get difficultyDeload => 'Deload';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get syncLedger => 'Sync ledger';

  @override
  String get syncCurrent => 'All changes are safely synced';

  @override
  String get syncOfflineSafe =>
      'Offline · your changes are saved on this device';

  @override
  String syncPending(int count) {
    return '$count changes awaiting sync';
  }

  @override
  String syncRejected(int count) {
    return '$count changes need attention · tap to retry';
  }

  @override
  String offlinePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes',
      one: '1 change',
    );
    return 'Offline · $_temp0 will sync later';
  }

  @override
  String get offlineSaved => 'Offline · changes are saved on this device';

  @override
  String syncingChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes',
      one: '1 change',
    );
    return 'Syncing $_temp0…';
  }

  @override
  String get notSet => 'Not set';

  @override
  String get weightUnits => 'Weight units';

  @override
  String get addNote => 'Add note';

  @override
  String get editNote => 'Edit note';

  @override
  String get groupWithNext => 'Group with next…';

  @override
  String get extendGroup => 'Extend group to next…';

  @override
  String get removeExerciseGroup => 'Remove exercise group';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get removeExercise => 'Remove exercise';

  @override
  String get trainingGroup => 'Training group';

  @override
  String get trainingGroupBody =>
      'Grouped exercises advance without starting the rest timer until the round is complete.';

  @override
  String get superset => 'Superset';

  @override
  String get circuit => 'Circuit';

  @override
  String get intervalBlock => 'Interval block';

  @override
  String get exerciseNote => 'Exercise note';

  @override
  String get exerciseNoteHint => 'Form cues, pain, target for next time…';

  @override
  String get quitWorkoutQuestion => 'Quit workout?';

  @override
  String get quitWorkoutBody =>
      'This workout and all checked sets will be discarded.';

  @override
  String get keepGoing => 'Keep going';

  @override
  String get quit => 'Quit';

  @override
  String get finishWorkoutQuestion => 'Finish workout?';

  @override
  String finishWorkoutBody(int done, int total) {
    return '$done of $total sets are complete. Choose how you want to finish.';
  }

  @override
  String get finishWithoutSaving => 'Finish without saving';

  @override
  String get saveKeepRoutine => 'Save · keep routine';

  @override
  String get finishAndSave => 'Finish and save';

  @override
  String get saveUpdateRoutine => 'Save · update routine';

  @override
  String get couldNotSaveWorkout => 'Couldn’t save workout';

  @override
  String get setColumn => 'SET';

  @override
  String get setType => 'Set type';

  @override
  String get progressionTag => 'Progression tag…';

  @override
  String progressionValue(String value) {
    return 'Progression: $value';
  }

  @override
  String get setProgressQuestion => 'How did this set progress?';

  @override
  String get noProgressionTag => 'No progression tag';

  @override
  String get perceivedExertion => 'Rate of perceived exertion';

  @override
  String get perceivedExertionQuestion => 'How hard did this set feel?';

  @override
  String get clearRpe => 'Clear RPE';

  @override
  String get startNewWorkoutQuestion => 'Start a new workout?';

  @override
  String get activeWorkoutBody =>
      'You have an active session in progress. Starting this one will discard it.';

  @override
  String get resumeActive => 'Resume active';

  @override
  String get startNew => 'Start new';

  @override
  String get configureWorkout => 'Configure workout';

  @override
  String get configureWorkoutBody =>
      'Optional exercises and alternatives can change each session.';

  @override
  String get optional => 'Optional';

  @override
  String get chooseOne => 'CHOOSE ONE';

  @override
  String get alternative => 'Alternative';

  @override
  String get saved => 'Saved';

  @override
  String get copySavedBody =>
      'A private copy was added to your workouts. Open “Mine” to launch or edit it.';

  @override
  String get couldNotSaveCopy => 'Could not save a copy';

  @override
  String get whatWorks => 'What works';

  @override
  String get watch => 'Watch';

  @override
  String get nextFocus => 'Next focus';

  @override
  String get deleteWorkoutQuestion => 'Delete workout?';

  @override
  String get workoutHistory => 'Workout history';

  @override
  String get volume => 'Volume';

  @override
  String get averageTime => 'Avg time';

  @override
  String get streak => 'Streak';

  @override
  String get ranked => 'Ranked';

  @override
  String get sessions => 'Sessions';

  @override
  String get time => 'Time';

  @override
  String get hardSets => 'Hard sets';

  @override
  String get longestWorkout => 'Longest workout';

  @override
  String get favoriteExercise => 'Favorite exercise';

  @override
  String get strongestBodyweight => 'Strongest (vs bodyweight)';

  @override
  String get name => 'Name';

  @override
  String get imageUrl => 'Image URL';

  @override
  String get description => 'Description';

  @override
  String get bodyMeasurements => 'Body Measurements';

  @override
  String get deleteMeasurementQuestion => 'Delete measurement?';

  @override
  String deleteMeasurementBody(String date) {
    return 'The entry from $date will be removed.';
  }

  @override
  String get couldNotLoadRetry => 'Could not load · Retry';

  @override
  String get saveMeasurement => 'Save measurement';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get termsOfUse => 'Terms of use';

  @override
  String get support => 'Support';

  @override
  String get logoutQuestion => 'Are you sure you want to log out?';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountCaption =>
      'Permanently deletes your workouts, exercise history and profile. This cannot be undone.';

  @override
  String get deleteAccountBody =>
      'This will permanently delete your account, workouts, exercise history and profile. This cannot be undone.';

  @override
  String get couldNotDeleteAccount => 'Could not delete account';

  @override
  String get rename => 'Rename';

  @override
  String get deleteFolder => 'Delete folder';

  @override
  String deleteFolderQuestion(String name) {
    return 'Delete “$name”?';
  }

  @override
  String moveWorkout(String name) {
    return 'Move “$name”';
  }

  @override
  String get defaultFolder => 'Default folder';

  @override
  String get couldNotSaveChanges => 'Couldn’t save changes';

  @override
  String get sortWorkouts => 'Sort workouts';

  @override
  String get newFolder => 'New folder';

  @override
  String openWorkout(String name) {
    return 'Open $name';
  }

  @override
  String get couldNotVerifyPro => 'Couldn’t verify Pro access';

  @override
  String get warmupSet => 'Warm-up';

  @override
  String get warmupSetBody => 'Excluded from working volume';

  @override
  String get workingSet => 'Working';

  @override
  String get workingSetBody => 'Counts toward volume and PRs';

  @override
  String get failureSet => 'Failure';

  @override
  String get failureSetBody => 'Taken to muscular failure';

  @override
  String get dropSet => 'Drop set';

  @override
  String get dropSetBody => 'Reduced load without a full rest period';

  @override
  String get heavierWeight => 'Heavier weight';

  @override
  String get greaterAmplitude => 'Greater amplitude';

  @override
  String get betterEfficiency => 'Better efficiency';

  @override
  String get meoSet => 'MEO / myo-rep set';

  @override
  String get weightKgLabel => 'Weight (kg)';

  @override
  String get heightCmLabel => 'Height (cm)';

  @override
  String get couldNotOpenLink => 'Could not open link';

  @override
  String get noDiagnostics => 'No diagnostics to send';

  @override
  String get diagnosticsEmpty =>
      'The local diagnostic buffer is currently empty.';

  @override
  String get sendDiagnosticsQuestion => 'Send diagnostics?';

  @override
  String sendDiagnosticsBody(int count) {
    return 'This sends $count technical events to GymControl support. Tokens, email, workout contents, comments and stack traces are not included.';
  }

  @override
  String get diagnosticsSent => 'Diagnostics sent';

  @override
  String diagnosticsSentBody(int count, String reference) {
    return '$count events sent. Reference: $reference';
  }

  @override
  String get diagnosticsFailed => 'Could not send diagnostics';

  @override
  String get diagnosticsFailedBody =>
      'The events remain on this device. Check your connection and try again.';

  @override
  String get shareDiagnostics => 'Share technical diagnostics automatically';

  @override
  String get diagnosticsPrivacyBody =>
      'Helps us detect app errors. Includes only event codes, app version and platform; never email, workout content, tokens or stack traces.';

  @override
  String get exerciseIllustrations => 'Exercise illustrations';

  @override
  String get exerciseIllustrationsCredit =>
      'Muscle-highlight illustrations © Everkinetic, used under the Creative Commons Attribution-ShareAlike license (CC BY-SA).';

  @override
  String get exerciseData => 'Exercise data';

  @override
  String get exerciseDataCredit =>
      'Exercise catalog based on the free-exercise-db, released into the public domain under The Unlicense.';

  @override
  String get warmupCalculator => 'Warm-up calculator';

  @override
  String get workingKg => 'Working kg';

  @override
  String get barKg => 'Bar kg';

  @override
  String get plateCalculator => 'Plate calculator';

  @override
  String get totalKg => 'Total kg';

  @override
  String get pickExercise => 'Pick exercise';

  @override
  String get recent => 'Recent';

  @override
  String get favorites => 'Favorites';

  @override
  String get anyEquipment => 'Any equipment';

  @override
  String get optionalBody => 'Choose whether to include it when starting';

  @override
  String get alternativePrevious => 'Alternative to previous';

  @override
  String get alternativePreviousBody => 'Pick one of the two when starting';

  @override
  String get restSeconds => 'Rest (s)';

  @override
  String get repsShort => 'reps';
}
