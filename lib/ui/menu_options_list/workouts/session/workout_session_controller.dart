import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gymboss/data/repositories/exercises_repository.dart';
import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';
import 'package:gymboss/ui/core/units/units_controller.dart';

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
  bool done;

  SessionSet({
    required this.exerciseId,
    required this.restSeconds,
    required this.plannedWeightKg,
    required this.plannedReps,
    required this.weight,
    required this.reps,
    this.type = 'working',
    this.progression = '',
    this.done = false,
  });
}

const setTypes = ['warmup', 'working', 'failure'];

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
  final String imageUrl;
  final String imageUrl2;
  final int restSeconds;
  final List<SessionSet> sets;
  SessionExercise({
    required this.exerciseId,
    required this.name,
    required this.muscleGroup,
    this.imageUrl = '',
    this.imageUrl2 = '',
    required this.restSeconds,
    required this.sets,
  });
}

/// A global, app-lived controller for the one active workout session. Holds all
/// runner state so the session survives navigation — the user can minimize the
/// runner, do something else, and resume with everything intact.
class WorkoutSessionController extends ChangeNotifier {
  Workout? _workout;
  String _difficulty = 'medium';
  bool _active = false;
  bool _minimized = false;
  bool _finished = false;

  final List<SessionExercise> _groups = [];
  final Map<int, double> _prKg =
      {}; // exerciseId → previous best working weight
  int _totalSets = 0;
  int _loggedSets = 0;
  double _loggedVolumeKg = 0;
  DateTime? _startedAt;

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
    _minimized = false;
    _active = true;
    _startedAt = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_active && !_finished) notifyListeners();
    });
    notifyListeners();
    _loadPrs();
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

  List<SessionExercise> _build(
    Workout w,
    String difficulty,
    UnitsController units,
  ) {
    final out = <SessionExercise>[];
    for (final ex in w.exercises) {
      final planned = ex.setsFor(difficulty);
      if (planned.isEmpty) continue;
      out.add(
        SessionExercise(
          exerciseId: ex.exerciseId,
          name: ex.name,
          muscleGroup: ex.muscleGroup,
          imageUrl: ex.imageUrl,
          imageUrl2: ex.imageUrl2,
          restSeconds: ex.restSeconds,
          sets: [
            for (final s in planned)
              SessionSet(
                exerciseId: ex.exerciseId,
                restSeconds: ex.restSeconds,
                plannedWeightKg: s.weightKg,
                plannedReps: s.reps,
                weight: s.weightKg == 0 ? '' : _fmt(units.fromKg(s.weightKg)),
                reps: s.reps == 0 ? '' : '${s.reps}',
              ),
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

  /// Toggle a set done/undone. Logs the performed set on completion.
  void toggleSet(SessionSet s) {
    if (s.done) {
      s.done =
          false; // allow correcting a mistaken tap; the log stays (append-only)
      notifyListeners();
      return;
    }
    final w = _units.toKg(double.tryParse(s.weight.trim()) ?? 0);
    final r = int.tryParse(s.reps.trim()) ?? 0;
    if (r <= 0) return;
    HapticFeedback.mediumImpact();
    s.done = true;
    _loggedSets++;
    if (s.type != 'warmup') {
      _loggedVolumeKg += w * r; // warmup excluded from working volume
    }
    notifyListeners();
    _exercises
        .logSet(
          s.exerciseId,
          weightKg: w,
          reps: r,
          setType: s.type,
          progression: s.progression,
        )
        .catchError((_) {});
    _startRest(s.restSeconds);
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
    notifyListeners();
  }

  /// Remove a set from an exercise, keeping counters and volume consistent if
  /// it had already been checked off.
  void removeSet(SessionExercise g, SessionSet s) {
    if (!g.sets.remove(s)) return;
    _totalSets--;
    _uncount(s);
    notifyListeners();
  }

  /// Append a fresh exercise (one empty working set) to the running session.
  void addExercise({
    required int exerciseId,
    required String name,
    required String muscleGroup,
    String imageUrl = '',
    String imageUrl2 = '',
    int restSeconds = 90,
  }) {
    _groups.add(
      SessionExercise(
        exerciseId: exerciseId,
        name: name,
        muscleGroup: muscleGroup,
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
    stopExerciseTimer(); // card indices shifted; avoid a dangling timer panel
    notifyListeners();
  }

  /// Remove an entire exercise and all of its sets from the session.
  void removeExercise(SessionExercise g) {
    if (!_groups.remove(g)) return;
    for (final s in g.sets) {
      _totalSets--;
      _uncount(s);
    }
    stopExerciseTimer();
    notifyListeners();
  }

  /// Roll back the logged-set/volume counters for a set being removed.
  void _uncount(SessionSet s) {
    if (!s.done) return;
    _loggedSets = (_loggedSets - 1).clamp(0, 1 << 30);
    if (s.type != 'warmup') {
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

  // ── Per-exercise timer ───────────────────────────────────────────────────────
  // An independent, user-controlled countdown attached to a single exercise
  // card (identified by [_exTimerKey]). Unlike the rest timer it is started
  // manually and can be paused, resumed and reset — useful for timed holds
  // (planks, stretches) or a controllable rest.
  Timer? _exTimer;
  int? _exTimerKey;
  int _exTimerLeft = 0;
  int _exTimerTotal = 0;
  bool _exTimerRunning = false;

  int? get exTimerKey => _exTimerKey;
  int get exTimerLeft => _exTimerLeft;
  int get exTimerTotal => _exTimerTotal;
  bool get exTimerRunning => _exTimerRunning;

  /// Attach and start a countdown of [seconds] to the exercise card [key].
  /// Starting on a different card moves the timer there.
  void startExerciseTimer(int key, int seconds) {
    final total = seconds.clamp(1, 3600);
    _exTimerKey = key;
    _exTimerTotal = total;
    _exTimerLeft = total;
    _exTimerRunning = true;
    _tickExerciseTimer();
    notifyListeners();
  }

  void pauseExerciseTimer() {
    if (!_exTimerRunning) return;
    _exTimer?.cancel();
    _exTimerRunning = false;
    notifyListeners();
  }

  void resumeExerciseTimer() {
    if (_exTimerRunning || _exTimerKey == null || _exTimerLeft <= 0) return;
    _exTimerRunning = true;
    _tickExerciseTimer();
    notifyListeners();
  }

  /// Reset the countdown back to its configured total (paused).
  void resetExerciseTimer() {
    if (_exTimerKey == null) return;
    _exTimer?.cancel();
    _exTimerLeft = _exTimerTotal;
    _exTimerRunning = false;
    notifyListeners();
  }

  /// Adjust both the running countdown and its reset target by [delta] seconds.
  void adjustExerciseTimer(int delta) {
    if (_exTimerKey == null) return;
    _exTimerTotal = (_exTimerTotal + delta).clamp(1, 3600);
    _exTimerLeft = (_exTimerLeft + delta).clamp(0, 3600);
    notifyListeners();
  }

  /// Detach and stop the exercise timer entirely.
  void stopExerciseTimer() {
    _exTimer?.cancel();
    _exTimer = null;
    _exTimerKey = null;
    _exTimerLeft = 0;
    _exTimerTotal = 0;
    _exTimerRunning = false;
    notifyListeners();
  }

  void _tickExerciseTimer() {
    _exTimer?.cancel();
    _exTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_exTimerLeft <= 1) {
        t.cancel();
        _exTimerLeft = 0;
        _exTimerRunning = false;
        _exerciseTimerDone();
      } else {
        _exTimerLeft--;
        notifyListeners();
      }
    });
  }

  void _exerciseTimerDone() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
    notifyListeners();
  }

  Future<void> finish() async {
    _cancelTimers();
    _resting = false;
    final durationSeconds =
        _startedAt == null
            ? 0
            : DateTime.now().difference(_startedAt!).inSeconds;
    try {
      await _workouts.logRun(
        _workout!.id,
        _difficulty,
        durationSeconds: durationSeconds,
      );
    } catch (_) {}
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
    _workout = null;
    _groups.clear();
    _prKg.clear();
    _loggedSets = 0;
    _loggedVolumeKg = 0;
    _exTimerKey = null;
    _exTimerLeft = 0;
    _exTimerTotal = 0;
    _exTimerRunning = false;
    notifyListeners();
  }

  void _cancelTimers() {
    _restTimer?.cancel();
    _ticker?.cancel();
    _exTimer?.cancel();
    _restTimer = null;
    _ticker = null;
    _exTimer = null;
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}

String _fmt(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
