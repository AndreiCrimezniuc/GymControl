import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gymboss/data/repositories/exercises_repository.dart';
import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';
import 'package:gymboss/ui/core/units/units_controller.dart';
import 'package:gymboss/ui/core/input/numeric_limit_formatter.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/workout_calculators.dart';
import 'package:uuid/uuid.dart';

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
  int? rir;
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
    this.rir,
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

  bool _resting = false;
  int _restLeft = 0;
  Timer? _restTimer;
  Timer? _ticker;

  late ExercisesRepository _exercises;
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

  // ── lifecycle ────────────────────────────────────────────────────────────────
  void start({
    required Workout workout,
    required String difficulty,
    required ExercisesRepository exercises,
    required WorkoutsRepository workouts,
    required UnitsController units,
  }) {
    _cancelTimers();
    _exercises = exercises;
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
    _routineChanged = false;
    _minimized = false;
    _active = true;
    _startedAt = DateTime.now();
    _sessionId = const Uuid().v4();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_active && !_finished) notifyListeners();
    });
    notifyListeners();
    _loadPrs();
    _loadPreviousValues();
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
      final planned =
          ex.setsFor('medium').isNotEmpty ? ex.setsFor('medium') : ex.sets;
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

  void setEffort(SessionSet s, {double? rpe, int? rir}) {
    if (s.done) return;
    s.rpe = rpe;
    s.rir = rir;
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
    exercise.note = note.trim();
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
    notifyListeners();
  }

  void adjustRest(int delta) {
    _restLeft = (_restLeft + delta).clamp(0, 3600);
    notifyListeners();
  }

  void skipRest() {
    _restTimer?.cancel();
    _resting = false;
    notifyListeners();
  }

  Future<void> finish({required bool save}) async {
    _cancelTimers();
    _resting = false;
    if (!save) {
      clear();
      return;
    }
    final durationSeconds =
        _startedAt == null
            ? 0
            : DateTime.now().difference(_startedAt!).inSeconds;
    for (final group in _groups) {
      for (final set in group.sets.where((set) => set.done)) {
        await _exercises.logSet(
          set.exerciseId,
          weightKg: _units.toKg(clampWorkoutDecimal(set.weight)),
          reps: clampWorkoutInteger(set.reps),
          setType: set.type,
          progression: set.progression,
          rpe: set.rpe,
          rir: set.rir,
          operationId: set.operationId,
          sessionId: _sessionId,
        );
      }
    }
    await _workouts.logRun(
      _workout!.id,
      _difficulty,
      durationSeconds: durationSeconds,
      sessionId: _sessionId,
    );
    HapticFeedback.heavyImpact();
    _finished = true;
    _minimized = false;
    notifyListeners();
  }

  /// Fully clears the session (after the summary is dismissed, or on quit).
  void clear() {
    _cancelTimers();
    _active = false;
    _minimized = false;
    _finished = false;
    _routineChanged = false;
    _workout = null;
    _sessionId = null;
    _groups.clear();
    _prKg.clear();
    _loggedSets = 0;
    _loggedVolumeKg = 0;
    notifyListeners();
  }

  void _cancelTimers() {
    _restTimer?.cancel();
    _ticker?.cancel();
    _restTimer = null;
    _ticker = null;
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}

String _fmt(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
