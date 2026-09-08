import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gymboss/data/repositories/exercises_repository.dart';
import 'package:gymboss/data/repositories/ranking_repository.dart';
import 'package:gymboss/data/repositories/sessions_repository.dart';
import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/domain/models/json_readers.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';
import 'package:gymboss/domain/models/workouts/workout_debrief.dart';
import 'package:gymboss/domain/models/ranking/passport_lift_matcher.dart';
import 'package:gymboss/ui/core/units/units_controller.dart';
import 'package:gymboss/ui/core/input/numeric_limit_formatter.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/workout_calculators.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/workout_live_activity.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One set within an active session. Entered weight/reps are kept as strings so
/// they survive minimize/resume (the runner rebinds controllers to them).
class SessionSet {
  final int exerciseId;
  final int restSeconds;
  final double plannedWeightKg;
  final int plannedReps;
  String weight; // in the display unit
  String reps;
  String type; // warmup | working | failure
  String progression; // '' | weight | amplitude | efficiency | meo | dropset
  double? previousWeightKg;
  int? previousReps;
  double? previousRpe;
  double? rpe;
  bool done;
  final String operationId;

  SessionSet({
    required this.exerciseId,
    required this.restSeconds,
    required this.plannedWeightKg,
    required this.plannedReps,
    required this.weight,
    required this.reps,
    this.type = 'working',
    this.progression = '',
    this.previousWeightKg,
    this.previousReps,
    this.previousRpe,
    this.rpe,
    this.done = false,
    String? operationId,
  }) : operationId = operationId ?? const Uuid().v4();
}

const setTypes = ['warmup', 'working', 'failure', 'dropset'];

/// User-facing metadata lives beside the supported values so adding a type
/// cannot leave the runner picker with a missing label and a runtime `null!`.
const Map<String, ({String name, String description})> setTypeMetadata = {
  'warmup': (name: 'Warm-up', description: 'Excluded from working volume'),
  'working': (name: 'Working', description: 'Counts toward volume & PRs'),
  'failure': (name: 'Failure', description: 'Taken to muscular failure'),
  'dropset': (
    name: 'Drop set',
    description: 'Reduced load without a full rest period',
  ),
};

/// Ways a set can progress beyond simply adding load. Empty = none.
const progressionTypes = [
  'weight',
  'amplitude',
  'efficiency',
  'meo',
  'dropset',
];

class SessionExercise {
  final int exerciseId;
  final String name;
  final String muscleGroup;
  final String exerciseType;
  final String imageUrl;
  final String imageUrl2;
  final int restSeconds;
  final List<SessionSet> sets;
  String note;
  String? trainingGroupId;
  String trainingGroupType;
  SessionExercise({
    required this.exerciseId,
    required this.name,
    required this.muscleGroup,
    this.exerciseType = 'weight_reps',
    this.imageUrl = '',
    this.imageUrl2 = '',
    required this.restSeconds,
    required this.sets,
    this.note = '',
    this.trainingGroupId,
    this.trainingGroupType = '',
  });
}

/// A global, app-lived controller for the one active workout session. Holds all
/// runner state so the session survives navigation — the user can minimize the
/// runner, do something else, and resume with everything intact.
class WorkoutSessionController extends ChangeNotifier {
  static const maxExercises = 75;
  static const maxSetsPerExercise = 100;
  static const maxTotalSets = 500;
  static const _storageKey = 'active_workout_session_v1';
  static const _snapshotVersion = 2;
  Workout? _workout;
  String _difficulty = 'normal'; // 'normal' | 'deload'
  bool _active = false;
  bool _minimized = false;
  bool _finished = false;
  bool _routineChanged = false;

  final List<SessionExercise> _groups = [];
  final Map<int, double> _prKg =
      {}; // exerciseId → previous best working weight
  int _totalSets = 0;
  int _loggedSets = 0;
  double _loggedVolumeKg = 0;
  DateTime? _startedAt;
  String? _sessionId;
  WorkoutDebrief? _debrief;

  bool _resting = false;
  int _restLeft = 0;
  Timer? _restTimer;
  Timer? _ticker;
  Timer? _persistDebounce;
  String? _lastSnapshot;

  late ExercisesRepository _exercises;
  late RankingRepository _ranking;
  late SessionsRepository _sessions;
  late WorkoutsRepository _workouts;
  late UnitsController _units;

  // ── getters ────────────────────────────────────────────────────────────────
  bool get isActive => _active;
  bool get isMinimized => _minimized;
  bool get isFinished => _finished;
  bool get routineChanged => _routineChanged;
  Workout? get workout => _workout;
  String get difficulty => _difficulty;
  List<SessionExercise> get groups => _groups;
  int get totalSets => _totalSets;
  int get loggedSets => _loggedSets;
  double get loggedVolumeKg => _loggedVolumeKg;
  bool get resting => _resting;
  int get restLeft => _restLeft;
  WorkoutDebrief? get debrief => _debrief;

  int get doneSets =>
      _groups.fold(0, (a, g) => a + g.sets.where((s) => s.done).length);

  /// The catalog repository bound at [start]; used by the runner's live
  /// "add exercise" picker.
  ExercisesRepository get exercisesRepo => _exercises;

  /// Previous best working weight (kg) for an exercise, if loaded.
  double? prFor(int exerciseId) {
    final v = _prKg[exerciseId];
    return (v != null && v > 0) ? v : null;
  }

  String get elapsed {
    if (_startedAt == null) return '00:00';
    final d = DateTime.now().difference(_startedAt!);
    final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  /// Rehydrates an interrupted workout after dependencies are ready. Invalid
  /// or obsolete snapshots are discarded instead of blocking app startup.
  Future<bool> restore({
    required ExercisesRepository exercises,
    required RankingRepository ranking,
    required SessionsRepository sessions,
    required WorkoutsRepository workouts,
    required UnitsController units,
  }) async {
    await units.ready;
    _exercises = exercises;
    _ranking = ranking;
    _sessions = sessions;
    _workouts = workouts;
    _units = units;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return false;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['version'] != _snapshotVersion || data['active'] != true) {
        throw const FormatException();
      }
      _workout = Workout.fromJson(
        Map<String, dynamic>.from(data['workout'] as Map),
      );
      _difficulty = data['difficulty'] as String? ?? 'normal';
      _sessionId = data['session_id'] as String?;
      final startedAt = DateTime.tryParse(jsonString(data['started_at']));
      final now = DateTime.now();
      if (startedAt == null ||
          startedAt.isAfter(now.add(const Duration(minutes: 5))) ||
          now.difference(startedAt) > const Duration(hours: 48)) {
        throw const FormatException('stale or invalid active workout');
      }
      _startedAt = startedAt;
      _routineChanged = data['routine_changed'] as bool? ?? false;
      _minimized = true;
      _finished = false;
      _debrief = null;
      _active = true;
      _groups
        ..clear()
        ..addAll(
          jsonObjectList(data['groups'], _exerciseFromJson, maxItems: 75),
        );
      _recalculate();
      final restUntilRaw = data['rest_until'] is String
          ? data['rest_until'] as String
          : null;
      int? restoredRestSeconds;
      if (restUntilRaw != null) {
        final restUntil = DateTime.tryParse(restUntilRaw);
        final remaining = restUntil?.difference(DateTime.now()).inSeconds ?? 0;
        if (remaining > 0) {
          restoredRestSeconds = remaining;
          _startRest(remaining);
        }
      }
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_active && !_finished) notifyListeners();
      });
      _lastSnapshot = _snapshot();
      unawaited(
        WorkoutLiveActivity.start(
          workoutName: _workout!.name,
          totalSets: _totalSets,
          completedSets: _loggedSets,
          startedAt: _startedAt!,
          restSeconds: restoredRestSeconds,
        ),
      );
      notifyListeners();
      _loadPrs();
      return true;
    } catch (_) {
      await prefs.remove(_storageKey);
      clear();
      return false;
    }
  }

  // ── lifecycle ────────────────────────────────────────────────────────────────
  void start({
    required Workout workout,
    required String difficulty,
    required ExercisesRepository exercises,
    required RankingRepository ranking,
    required SessionsRepository sessions,
    required WorkoutsRepository workouts,
    required UnitsController units,
  }) {
    _cancelTimers();
    _exercises = exercises;
    _ranking = ranking;
    _sessions = sessions;
    _workouts = workouts;
    _units = units;
    _workout = workout;
    _difficulty = difficulty;
    _groups
      ..clear()
      ..addAll(_build(workout, difficulty, units));
    _totalSets = _groups.fold(0, (a, g) => a + g.sets.length);
    _loggedSets = 0;
    _loggedVolumeKg = 0;
    _resting = false;
    _finished = false;
    _debrief = null;
    _routineChanged = false;
    _minimized = false;
    _active = true;
    _startedAt = DateTime.now();
    _sessionId = const Uuid().v4();
    unawaited(
      WorkoutLiveActivity.start(
        workoutName: workout.name,
        totalSets: _totalSets,
        completedSets: 0,
        startedAt: _startedAt!,
      ),
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_active && !_finished) notifyListeners();
    });
    notifyListeners();
    _loadPrs();
    _loadPreviousValues();
    _schedulePersist();
  }

  void _loadPrs() {
    _prKg.clear();
    final ids = <int>{
      for (final g in _groups)
        for (final s in g.sets) s.exerciseId,
    };
    for (final id in ids) {
      _exercises
          .getStats(id)
          .then((stats) {
            _prKg[id] = stats.maxWeightKg;
            if (_active) notifyListeners();
          })
          .catchError((_) {});
    }
  }

  void _loadPreviousValues() {
    for (final group in _groups) {
      _exercises
          .getHistory(group.exerciseId)
          .then((history) {
            if (history.isEmpty) return;
            final previous = history.first.sets;
            for (var i = 0; i < group.sets.length && i < previous.length; i++) {
              final source = previous[i];
              final target = group.sets[i];
              target.previousWeightKg = source.weightKg;
              target.previousReps = source.reps;
              target.previousRpe = source.rpe;
            }
            if (_active) notifyListeners();
          })
          .catchError((_) {});
    }
  }

  List<SessionExercise> _build(
    Workout w,
    String mode, // 'normal' | 'deload'
    UnitsController units,
  ) {
    // Deload runs the Normal plan at deloadFactor of the weight (reps unchanged).
    final scale = mode == 'deload' ? w.deloadFactor : 1.0;
    final out = <SessionExercise>[];
    for (final ex in w.exercises) {
      // The plan is stored under the legacy 'medium' grade; fall back to any
      // sets so older data still loads.
      final planned = ex.setsFor('medium').isNotEmpty
          ? ex.setsFor('medium')
          : ex.sets;
      if (planned.isEmpty) continue;
      out.add(
        SessionExercise(
          exerciseId: ex.exerciseId,
          name: ex.name,
          muscleGroup: ex.muscleGroup,
          exerciseType: ex.exerciseType,
          imageUrl: ex.imageUrl,
          imageUrl2: ex.imageUrl2,
          restSeconds: ex.restSeconds,
          note: ex.comment,
          trainingGroupId: ex.trainingGroupId,
          trainingGroupType: ex.trainingGroupType,
          sets: [
            for (final s in planned)
              () {
                final w0 = s.weightKg * scale;
                return SessionSet(
                  exerciseId: ex.exerciseId,
                  restSeconds: ex.restSeconds,
                  plannedWeightKg: w0,
                  plannedReps: s.reps,
                  weight: w0 == 0 ? '' : _fmt(units.fromKg(w0)),
                  reps: s.reps == 0 ? '' : '${s.reps}',
                  type: s.setType,
                );
              }(),
          ],
        ),
      );
    }
    return out;
  }

  void minimize() {
    _minimized = true;
    notifyListeners();
  }

  void resume() {
    _minimized = false;
    notifyListeners();
  }

  /// Toggle a set done/undone. Persistence is deferred until the user
  /// explicitly chooses to save the finished workout.
  void toggleSet(SessionSet s) {
    if (s.done) {
      _uncount(s);
      s.done = false;
      unawaited(_updateLiveActivity());
      notifyListeners();
      return;
    }
    final w = _units.toKg(clampWorkoutDecimal(s.weight));
    final r = clampWorkoutInteger(s.reps);
    if (r <= 0) return;
    final exercise = _groups.firstWhere((group) => group.sets.contains(s));
    HapticFeedback.mediumImpact();
    s.done = true;
    _loggedSets++;
    if (s.type != 'warmup' && _countsVolume(exercise.exerciseType)) {
      _loggedVolumeKg += w * r; // warmup excluded from working volume
    }
    notifyListeners();
    unawaited(_updateLiveActivity());
    if (_shouldStartRest(s)) _startRest(s.restSeconds);
  }

  bool _countsVolume(String exerciseType) =>
      exerciseType == 'weight_reps' || exerciseType == 'bodyweight_reps';

  bool _shouldStartRest(SessionSet set) {
    final exercise = _groups.cast<SessionExercise?>().firstWhere(
      (group) => group!.sets.contains(set),
      orElse: () => null,
    );
    if (exercise?.trainingGroupId == null) return true;
    final setIndex = exercise!.sets.indexOf(set);
    final group = _groups.where(
      (item) => item.trainingGroupId == exercise.trainingGroupId,
    );
    return !group.any(
      (item) =>
          item != exercise &&
          setIndex < item.sets.length &&
          !item.sets[setIndex].done,
    );
  }

  /// Cycle a set's type (warmup → working → failure). No-op once logged.
  void cycleSetType(SessionSet s) {
    if (s.done) return;
    final i = setTypes.indexOf(s.type);
    s.type = setTypes[(i + 1) % setTypes.length];
    notifyListeners();
  }

  /// Explicitly set a set's type from the selector. Ignores unknown values and
  /// no-ops once the set has been logged.
  void setSetType(SessionSet s, String type) {
    if (s.done || !setTypes.contains(type) || s.type == type) return;
    s.type = type;
    notifyListeners();
  }

  /// Tag (or clear, with '') how a set progressed. No-op once logged.
  void setProgression(SessionSet s, String progression) {
    if (s.done) return;
    if (progression.isNotEmpty && !progressionTypes.contains(progression)) {
      return;
    }
    if (s.progression == progression) return;
    s.progression = progression;
    notifyListeners();
  }

  void setEffort(SessionSet s, {double? rpe}) {
    if (s.done) return;
    if (rpe != null && (!rpe.isFinite || rpe < 6 || rpe > 10)) return;
    s.rpe = rpe;
    notifyListeners();
  }

  void usePrevious(SessionSet s) {
    if (s.done || s.previousReps == null) return;
    if (s.previousWeightKg != null) {
      s.weight = _fmt(_units.fromKg(s.previousWeightKg!));
    }
    s.reps = '${s.previousReps}';
    s.rpe = s.previousRpe;
    notifyListeners();
  }

  void setExerciseNote(SessionExercise exercise, String note) {
    exercise.note = String.fromCharCodes(note.trim().runes.take(1000));
    _routineChanged = true;
    notifyListeners();
  }

  bool canGroupWithNext(SessionExercise exercise) {
    final index = _groups.indexOf(exercise);
    return index >= 0 && index < _groups.length - 1;
  }

  void groupWithNext(SessionExercise exercise, String type) {
    if (!const {'superset', 'circuit', 'interval'}.contains(type)) return;
    final index = _groups.indexOf(exercise);
    if (index < 0 || index >= _groups.length - 1) return;
    final next = _groups[index + 1];
    final id =
        exercise.trainingGroupId ?? next.trainingGroupId ?? const Uuid().v4();
    exercise
      ..trainingGroupId = id
      ..trainingGroupType = type;
    next
      ..trainingGroupId = id
      ..trainingGroupType = type;
    _routineChanged = true;
    notifyListeners();
  }

  void ungroup(SessionExercise exercise) {
    final id = exercise.trainingGroupId;
    if (id == null) return;
    for (final item in _groups.where((item) => item.trainingGroupId == id)) {
      item
        ..trainingGroupId = null
        ..trainingGroupType = '';
    }
    _routineChanged = true;
    notifyListeners();
  }

  // ── Live edits during a session ──────────────────────────────────────────────

  /// Append a new (empty) set to an exercise, seeded from its last set.
  void addSet(SessionExercise g) {
    if (g.sets.length >= maxSetsPerExercise || _totalSets >= maxTotalSets) {
      return;
    }
    final last = g.sets.isNotEmpty ? g.sets.last : null;
    g.sets.add(
      SessionSet(
        exerciseId: g.exerciseId,
        restSeconds: g.restSeconds,
        plannedWeightKg: last?.plannedWeightKg ?? 0,
        plannedReps: last?.plannedReps ?? 0,
        weight: last?.weight ?? '',
        reps: last?.reps ?? '',
      ),
    );
    _totalSets++;
    _routineChanged = true;
    notifyListeners();
  }

  void prependWarmupSets(SessionExercise group, List<WarmupSetPlan> plans) {
    if (plans.isEmpty) return;
    final available = [
      maxSetsPerExercise - group.sets.length,
      maxTotalSets - _totalSets,
    ].reduce((a, b) => a < b ? a : b);
    if (available <= 0) return;
    plans = plans.take(available).toList();
    group.sets.insertAll(0, [
      for (final plan in plans)
        SessionSet(
          exerciseId: group.exerciseId,
          restSeconds: group.restSeconds,
          plannedWeightKg: plan.weight,
          plannedReps: plan.reps,
          weight: _fmt(_units.fromKg(plan.weight)),
          reps: '${plan.reps}',
          type: 'warmup',
        ),
    ]);
    _totalSets += plans.length;
    _routineChanged = true;
    notifyListeners();
  }

  /// Remove a set from an exercise, keeping counters and volume consistent if
  /// it had already been checked off.
  void removeSet(SessionExercise g, SessionSet s) {
    if (!g.sets.remove(s)) return;
    _totalSets--;
    _uncount(s);
    _routineChanged = true;
    notifyListeners();
  }

  /// Append a fresh exercise (one empty working set) to the running session.
  void addExercise({
    required int exerciseId,
    required String name,
    required String muscleGroup,
    String exerciseType = 'weight_reps',
    String imageUrl = '',
    String imageUrl2 = '',
    int restSeconds = 90,
  }) {
    if (_groups.length >= maxExercises || _totalSets >= maxTotalSets) return;
    _groups.add(
      SessionExercise(
        exerciseId: exerciseId,
        name: name,
        muscleGroup: muscleGroup,
        exerciseType: exerciseType,
        imageUrl: imageUrl,
        imageUrl2: imageUrl2,
        restSeconds: restSeconds,
        sets: [
          SessionSet(
            exerciseId: exerciseId,
            restSeconds: restSeconds,
            plannedWeightKg: 0,
            plannedReps: 0,
            weight: '',
            reps: '',
          ),
        ],
      ),
    );
    _totalSets++;
    _routineChanged = true;
    notifyListeners();
  }

  /// Move an exercise up (delta -1) or down (delta +1) in the session order.
  void moveExercise(SessionExercise g, int delta) {
    final i = _groups.indexOf(g);
    final j = i + delta;
    if (i < 0 || j < 0 || j >= _groups.length) return;
    _groups.removeAt(i);
    _groups.insert(j, g);
    _routineChanged = true;
    notifyListeners();
  }

  /// Remove an entire exercise and all of its sets from the session.
  void removeExercise(SessionExercise g) {
    if (!_groups.remove(g)) return;
    for (final s in g.sets) {
      _totalSets--;
      _uncount(s);
    }
    _routineChanged = true;
    notifyListeners();
  }

  Future<void> updateRoutineFromSession() async {
    final workout = _workout;
    if (workout == null || !_routineChanged) return;
    final exercises = [
      for (final group in _groups)
        WorkoutExercise(
          exerciseId: group.exerciseId,
          name: group.name,
          imageUrl: group.imageUrl,
          imageUrl2: group.imageUrl2,
          muscleGroup: group.muscleGroup,
          exerciseType: group.exerciseType,
          trainingGroupId: group.trainingGroupId,
          trainingGroupType: group.trainingGroupType,
          restSeconds: group.restSeconds,
          comment: group.note,
          sets: [
            for (final set in group.sets)
              WorkoutSet(
                difficulty: 'medium',
                weightKg: _units.toKg(clampWorkoutDecimal(set.weight)),
                reps: clampWorkoutInteger(set.reps),
                setType: set.type,
              ),
          ],
        ),
    ];
    _workout = await _workouts.update(
      workout.id,
      name: workout.name,
      comment: workout.comment,
      exercises: exercises,
      deloadFactor: workout.deloadFactor,
      type: workout.type,
    );
    _routineChanged = false;
    notifyListeners();
  }

  /// Roll back the logged-set/volume counters for a set being removed.
  void _uncount(SessionSet s) {
    if (!s.done) return;
    _loggedSets = (_loggedSets - 1).clamp(0, 1 << 30);
    final exercise = _groups.cast<SessionExercise?>().firstWhere(
      (group) => group!.sets.contains(s),
      orElse: () => null,
    );
    if (s.type != 'warmup' &&
        exercise != null &&
        _countsVolume(exercise.exerciseType)) {
      final w = _units.toKg(double.tryParse(s.weight.trim()) ?? 0);
      final r = int.tryParse(s.reps.trim()) ?? 0;
      _loggedVolumeKg = (_loggedVolumeKg - w * r).clamp(0, double.infinity);
    }
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    if (seconds <= 0) return;
    _resting = true;
    _restLeft = seconds;
    unawaited(_updateLiveActivity(restSeconds: seconds));
    notifyListeners();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restLeft <= 1) {
        t.cancel();
        _restDone();
      } else {
        _restLeft--;
        notifyListeners();
      }
    });
  }

  void _restDone() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
    _resting = false;
    unawaited(_updateLiveActivity());
    notifyListeners();
  }

  void adjustRest(int delta) {
    _restLeft = (_restLeft + delta).clamp(0, 3600);
    unawaited(_updateLiveActivity(restSeconds: _restLeft));
    notifyListeners();
  }

  void skipRest() {
    _restTimer?.cancel();
    _resting = false;
    unawaited(_updateLiveActivity());
    notifyListeners();
  }

  Future<void> finish({required bool save}) async {
    _cancelTimers();
    _resting = false;
    // Keep local and system state ordered. ActivityKit survives our process;
    // removing the local snapshot before this completes can produce an orphan
    // timer in Dynamic Island if iOS suspends the app between both operations.
    await WorkoutLiveActivity.end();
    if (!save) {
      clear(endLiveActivity: false);
      return;
    }
    final durationSeconds = _startedAt == null
        ? 0
        : DateTime.now().difference(_startedAt!).inSeconds;
    _debrief = _buildDebrief(durationSeconds);
    for (final group in _groups) {
      for (final set in group.sets.where((set) => set.done)) {
        await _exercises.logSet(
          set.exerciseId,
          weightKg: _units.toKg(clampWorkoutDecimal(set.weight)),
          reps: clampWorkoutInteger(set.reps),
          setType: set.type,
          progression: set.progression,
          rpe: set.rpe,
          durationSeconds:
              group.exerciseType == 'duration' ||
                  group.exerciseType == 'distance_duration'
              ? clampWorkoutInteger(set.reps)
              : 0,
          distanceKm: group.exerciseType == 'distance_duration'
              ? clampWorkoutDecimal(set.weight)
              : 0,
          operationId: set.operationId,
          sessionId: _sessionId,
          workoutId: _workout!.id,
          workoutName: _workout!.name,
          performedAt: _startedAt,
        );
      }
    }
    await _recordPassportBenchmarks();
    await _workouts.logRun(
      _workout!.id,
      _difficulty,
      durationSeconds: durationSeconds,
      sessionId: _sessionId,
      performedAt: _startedAt,
    );
    await _sessions.recordSession(performedAt: _startedAt);
    HapticFeedback.heavyImpact();
    _finished = true;
    _minimized = false;
    _lastSnapshot = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }

  /// Sends one best working set per supported benchmark to the passport. The
  /// ranking repository and backend both de-duplicate PRs, so normal workout
  /// logging becomes the only input the athlete needs to maintain.
  Future<void> _recordPassportBenchmarks() async {
    for (final group in _groups) {
      final passportId = passportExerciseIdForName(group.name);
      if (passportId == null) continue;
      SessionSet? best;
      var bestEstimate = 0.0;
      for (final set in group.sets.where(
        (set) => set.done && set.type != 'warmup',
      )) {
        final weightKg = _units.toKg(double.tryParse(set.weight) ?? 0);
        final reps = int.tryParse(set.reps) ?? 0;
        if (weightKg <= 0 || reps <= 0) continue;
        final estimate = weightKg * (1 + reps / 30);
        if (estimate > bestEstimate) {
          bestEstimate = estimate;
          best = set;
        }
      }
      if (best == null) continue;
      await _ranking.recordLift(
        exerciseId: passportId,
        weightKg: _units.toKg(double.parse(best.weight)),
        reps: int.parse(best.reps),
      );
    }
  }

  WorkoutDebrief _buildDebrief(int durationSeconds) {
    return WorkoutDebrief.calculate(
      durationSeconds: durationSeconds,
      sets: [
        for (final group in _groups)
          for (final set in group.sets.where((item) => item.done))
            DebriefSetSnapshot(
              exerciseName: group.name,
              weightKg: _units.toKg(double.tryParse(set.weight) ?? 0),
              reps: int.tryParse(set.reps) ?? 0,
              setType: set.type,
              previousWeightKg: set.previousWeightKg,
              previousReps: set.previousReps,
              previousBestWeightKg: _prKg[group.exerciseId],
              countsWeight: _countsVolume(group.exerciseType),
              passportBenchmark: passportExerciseIdForName(group.name) != null,
            ),
      ],
    );
  }

  /// Fully clears the session (after the summary is dismissed, or on quit).
  Future<void> discard() async {
    await WorkoutLiveActivity.end();
    clear(endLiveActivity: false);
  }

  void clear({bool endLiveActivity = true}) {
    if (endLiveActivity) unawaited(WorkoutLiveActivity.end());
    _cancelTimers();
    _active = false;
    _minimized = false;
    _finished = false;
    _routineChanged = false;
    _debrief = null;
    _workout = null;
    _sessionId = null;
    _groups.clear();
    _prKg.clear();
    _loggedSets = 0;
    _loggedVolumeKg = 0;
    _lastSnapshot = null;
    _persistDebounce?.cancel();
    unawaited(
      SharedPreferences.getInstance().then(
        (prefs) => prefs.remove(_storageKey),
      ),
    );
    notifyListeners();
  }

  /// Called by text fields whose model values are updated directly.
  void checkpoint() => _schedulePersist();

  void _recalculate() {
    _totalSets = _groups.fold(0, (sum, group) => sum + group.sets.length);
    _loggedSets = 0;
    _loggedVolumeKg = 0;
    for (final group in _groups) {
      for (final set in group.sets.where((item) => item.done)) {
        _loggedSets++;
        if (set.type != 'warmup' && _countsVolume(group.exerciseType)) {
          _loggedVolumeKg +=
              _units.toKg(double.tryParse(set.weight) ?? 0) *
              (int.tryParse(set.reps) ?? 0);
        }
      }
    }
  }

  SessionExercise _exerciseFromJson(
    Map<String, dynamic> data,
  ) => SessionExercise(
    exerciseId: jsonInt(data['exercise_id']),
    name: jsonString(data['name']),
    muscleGroup: jsonString(data['muscle_group']),
    exerciseType: jsonString(data['exercise_type'], 'weight_reps'),
    imageUrl: jsonString(data['image_url']),
    imageUrl2: jsonString(data['image_url2']),
    restSeconds: jsonInt(
      data['rest_seconds'],
      fallback: 90,
      min: 0,
      max: 86400,
    ),
    note: jsonString(data['note']),
    trainingGroupId: jsonNullableString(data['training_group_id']),
    trainingGroupType: jsonString(data['training_group_type']),
    sets: jsonObjectList(data['sets'], (set) {
      return SessionSet(
        exerciseId: jsonInt(set['exercise_id']),
        restSeconds: jsonInt(
          set['rest_seconds'],
          fallback: 90,
          min: 0,
          max: 86400,
        ),
        plannedWeightKg: jsonDouble(
          set['planned_weight_kg'],
          min: 0,
          max: 2000,
        ),
        plannedReps: jsonInt(set['planned_reps'], min: 0, max: 10000),
        weight: jsonString(set['weight']),
        reps: jsonString(set['reps']),
        type: jsonString(set['type'], 'working'),
        progression: jsonString(set['progression']),
        previousWeightKg: jsonNullableDouble(
          set['previous_weight_kg'],
          min: 0,
          max: 2000,
        ),
        previousReps: jsonNullableInt(set['previous_reps'], min: 0, max: 10000),
        previousRpe: jsonNullableDouble(set['previous_rpe'], min: 0, max: 10),
        rpe: jsonNullableDouble(set['rpe'], min: 0, max: 10),
        done: jsonBool(set['done']),
        operationId: jsonNullableString(set['operation_id']),
      );
    }, maxItems: 100),
  );

  String _snapshot() => jsonEncode({
    'version': _snapshotVersion,
    'active': _active,
    'workout': _workout?.toJson(),
    'difficulty': _difficulty,
    'session_id': _sessionId,
    'started_at': _startedAt?.toIso8601String(),
    'routine_changed': _routineChanged,
    'rest_until': _resting
        ? DateTime.now().add(Duration(seconds: _restLeft)).toIso8601String()
        : null,
    'groups': _groups
        .map(
          (group) => {
            'exercise_id': group.exerciseId,
            'name': group.name,
            'muscle_group': group.muscleGroup,
            'exercise_type': group.exerciseType,
            'image_url': group.imageUrl,
            'image_url2': group.imageUrl2,
            'rest_seconds': group.restSeconds,
            'note': group.note,
            'training_group_id': group.trainingGroupId,
            'training_group_type': group.trainingGroupType,
            'sets': group.sets
                .map(
                  (set) => {
                    'exercise_id': set.exerciseId,
                    'rest_seconds': set.restSeconds,
                    'planned_weight_kg': set.plannedWeightKg,
                    'planned_reps': set.plannedReps,
                    'weight': set.weight,
                    'reps': set.reps,
                    'type': set.type,
                    'progression': set.progression,
                    'previous_weight_kg': set.previousWeightKg,
                    'previous_reps': set.previousReps,
                    'previous_rpe': set.previousRpe,
                    'rpe': set.rpe,
                    'done': set.done,
                    'operation_id': set.operationId,
                  },
                )
                .toList(),
          },
        )
        .toList(),
  });

  void _schedulePersist() {
    if (!_active || _finished || _workout == null) return;
    final snapshot = _snapshot();
    if (snapshot == _lastSnapshot) return;
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 250), () async {
      final latest = _snapshot();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, latest);
      _lastSnapshot = latest;
    });
  }

  @override
  void notifyListeners() {
    _schedulePersist();
    super.notifyListeners();
  }

  void _cancelTimers() {
    _restTimer?.cancel();
    _ticker?.cancel();
    _restTimer = null;
    _ticker = null;
  }

  Future<void> _updateLiveActivity({int? restSeconds}) =>
      WorkoutLiveActivity.update(
        completedSets: _loggedSets,
        totalSets: _totalSets,
        restSeconds: restSeconds,
      );

  @override
  void dispose() {
    _persistDebounce?.cancel();
    _cancelTimers();
    super.dispose();
  }
}

String _fmt(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
