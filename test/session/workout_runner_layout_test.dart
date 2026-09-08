import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymboss/data/local/local_store.dart';
import 'package:gymboss/data/repositories/exercises_repository.dart';
import 'package:gymboss/data/repositories/ranking_repository.dart';
import 'package:gymboss/data/repositories/sessions_repository.dart';
import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/data/services/auth/auth_service.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/services/auth/token_storage.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';
import 'package:gymboss/l10n/app_localizations.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/units/units_controller.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/workout_session_controller.dart';
import 'package:gymboss/ui/menu_options_list/workouts/widgets/workout_runner.dart';

void main() {
  final store = LocalStore.instance;

  setUpAll(() async {
    final directory = Directory.systemTemp.createTempSync(
      'gymboss_runner_layout',
    );
    await store.init(path: directory.path);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(const {});
    await store.clear();
  });

  testWidgets('previous value and RPE stay on one narrow-phone set row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final client = AuthenticatedClient(
      storage: TokenStorage(),
      authService: AuthService(),
      inner: MockClient((_) async => throw StateError('network is disabled')),
    );
    final exercises = ExercisesRepository(
      client: client,
      isOnline: () async => false,
    );
    final workouts = WorkoutsRepository(
      client: client,
      isOnline: () async => false,
    );
    final sessions = SessionsRepository(
      client: client,
      isOnline: () async => false,
    );
    final ranking = RankingRepository(
      client: client,
      isOnline: () async => false,
    );
    final units = UnitsController();
    final session = WorkoutSessionController();
    final theme = ThemeController();
    session.start(
      workout: const Workout(
        id: 'w1',
        name: 'Strength session',
        comment: '',
        visibility: 'private',
        owned: true,
        shareCode: '',
        exerciseCount: 1,
        timesPerformed: 0,
        exercises: [
          WorkoutExercise(
            exerciseId: 7,
            name: 'Bench Press',
            imageUrl: '',
            muscleGroup: 'Chest',
            restSeconds: 90,
            comment: '',
            sets: [WorkoutSet(difficulty: 'medium', weightKg: 82.5, reps: 5)],
          ),
        ],
      ),
      difficulty: 'normal',
      exercises: exercises,
      ranking: ranking,
      sessions: sessions,
      workouts: workouts,
      units: units,
    );
    session.groups.single.sets.single
      ..previousWeightKg = 80
      ..previousReps = 5
      ..progression = 'amplitude'
      ..rpe = 8.5;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: theme),
          ChangeNotifierProvider.value(value: units),
          ChangeNotifierProvider.value(value: session),
        ],
        child: const CupertinoApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WorkoutRunnerScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('PREV 80'), findsOneWidget);
    expect(find.text('8.5'), findsOneWidget);
    expect(tester.takeException(), isNull);

    session.clear();
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
    units.dispose();
    theme.dispose();
    client.dispose();
  });
}
