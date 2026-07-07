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
  bool done;

  SessionSet({
    required this.exerciseId,
    required this.restSeconds,
    required this.plannedWeightKg,
    required this.plannedReps,
    required this.weight,
    required this.reps,
    this.type = 'working',
    this.done = false,
  });
}

const setTypes = ['warmup', 'working', 'failure'];

class SessionExercise {
  final String name;
  final String muscleGroup;
  final int restSeconds;
  final List<SessionSet> sets;
  SessionExercise({required this.name, required this.muscleGroup, required this.restSeconds, required this.sets});
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

  int get doneSets => _groups.fold(0, (a, g) => a + g.sets.where((s) => s.done).length);

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
  }

  List<SessionExercise> _build(Workout w, String difficulty, UnitsController units) {
    final out = <SessionExercise>[];
    for (final ex in w.exercises) {
      final planned = ex.setsFor(difficulty);
      if (planned.isEmpty) continue;
      out.add(SessionExercise(
        name: ex.name,
        muscleGroup: ex.muscleGroup,
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
      ));
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
      s.done = false; // allow correcting a mistaken tap; the log stays (append-only)
      notifyListeners();
      return;
    }
    final w = _units.toKg(double.tryParse(s.weight.trim()) ?? 0);
    final r = int.tryParse(s.reps.trim()) ?? 0;
    if (r <= 0) return;
    HapticFeedback.mediumImpact();
    s.done = true;
    _loggedSets++;
    if (s.type != 'warmup') _loggedVolumeKg += w * r; // warmup excluded from working volume
    notifyListeners();
    _exercises.logSet(s.exerciseId, weightKg: w, reps: r, setType: s.type).catchError((_) {});
    _startRest(s.restSeconds);
  }

  /// Cycle a set's type (warmup → working → failure). No-op once logged.
  void cycleSetType(SessionSet s) {
    if (s.done) return;
    final i = setTypes.indexOf(s.type);
    s.type = setTypes[(i + 1) % setTypes.length];
    notifyListeners();
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

  Future<void> finish() async {
    _cancelTimers();
    _resting = false;
    try {
      await _workouts.logRun(_workout!.id, _difficulty);
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
