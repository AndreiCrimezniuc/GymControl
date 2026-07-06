import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:gymboss/data/repositories/exercises_repository.dart';
import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_scaffold.dart';
import 'package:gymboss/ui/core/ui/widgets/pressable.dart';

const _diffLabels = {'easy': 'Easy', 'medium': 'Medium', 'hard': 'Hard'};

/// One planned set to perform, flattened across the workout's exercises.
class _Step {
  final int exerciseId;
  final String name;
  final String imageUrl;
  final int exerciseNo; // 1-based position among exercises
  final int setNo; // 1-based within the exercise
  final int setsInExercise;
  final double plannedWeight;
  final int plannedReps;
  final int restSeconds;
  final bool lastSetOfExercise;

  _Step({
    required this.exerciseId,
    required this.name,
    required this.imageUrl,
    required this.exerciseNo,
    required this.setNo,
    required this.setsInExercise,
    required this.plannedWeight,
    required this.plannedReps,
    required this.restSeconds,
    required this.lastSetOfExercise,
  });
}

class WorkoutRunnerScreen extends StatefulWidget {
  final Workout workout;
  final String difficulty;
  final WorkoutsRepository repo;
  final ExercisesRepository exercises;
  const WorkoutRunnerScreen({
    super.key,
    required this.workout,
    required this.difficulty,
    required this.repo,
    required this.exercises,
  });

  @override
  State<WorkoutRunnerScreen> createState() => _WorkoutRunnerScreenState();
}

class _WorkoutRunnerScreenState extends State<WorkoutRunnerScreen> {
  late final List<_Step> _steps;
  final _weightCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();

  int _current = 0;
  bool _resting = false;
  int _restLeft = 0;
  Timer? _restTimer;

  bool _finishing = false;
  bool _done = false;
  int _loggedSets = 0;
  double _loggedVolume = 0;

  @override
  void initState() {
    super.initState();
    _steps = _buildSteps();
    if (_steps.isEmpty) {
      // nothing to do — log the run and show the summary immediately
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    } else {
      _seedFields();
    }
  }

  List<_Step> _buildSteps() {
    final out = <_Step>[];
    var exNo = 0;
    for (final ex in widget.workout.exercises) {
      final sets = ex.setsFor(widget.difficulty);
      if (sets.isEmpty) continue;
      exNo++;
      for (var i = 0; i < sets.length; i++) {
        out.add(_Step(
          exerciseId: ex.exerciseId,
          name: ex.name,
          imageUrl: ex.imageUrl,
          exerciseNo: exNo,
          setNo: i + 1,
          setsInExercise: sets.length,
          plannedWeight: sets[i].weightKg,
          plannedReps: sets[i].reps,
          restSeconds: ex.restSeconds,
          lastSetOfExercise: i == sets.length - 1,
        ));
      }
    }
    return out;
  }

  void _seedFields() {
    final s = _steps[_current];
    _weightCtrl.text = s.plannedWeight == 0 ? '' : s.plannedWeight.toStringAsFixed(s.plannedWeight % 1 == 0 ? 0 : 1);
    _repsCtrl.text = s.plannedReps == 0 ? '' : '${s.plannedReps}';
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  Future<void> _logCurrentSet() async {
    final step = _steps[_current];
    final w = double.tryParse(_weightCtrl.text.trim()) ?? 0;
    final r = int.tryParse(_repsCtrl.text.trim()) ?? 0;
    if (r <= 0) {
      _seedFields();
      return;
    }
    // best-effort logging; a network hiccup shouldn't block the workout
    try {
      await widget.exercises.logSet(step.exerciseId, weightKg: w, reps: r);
    } catch (_) {}
    _loggedSets++;
    _loggedVolume += w * r;

    if (_current >= _steps.length - 1) {
      _finish();
      return;
    }
    _startRest(step.restSeconds);
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    if (seconds <= 0) {
      _advance();
      return;
    }
    setState(() { _resting = true; _restLeft = seconds; });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_restLeft <= 1) {
        t.cancel();
        _advance();
      } else {
        setState(() => _restLeft--);
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    _advance();
  }

  void _advance() {
    if (!mounted) return;
    setState(() {
      _resting = false;
      _current++;
    });
    _seedFields();
  }

  Future<void> _finish() async {
    setState(() => _finishing = true);
    try {
      await widget.repo.logRun(widget.workout.id, widget.difficulty);
    } catch (_) {}
    if (mounted) setState(() { _finishing = false; _done = true; });
  }

  Future<void> _confirmQuit() async {
    if (_done) { Navigator.of(context).pop(); return; }
    final quit = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Quit workout?'),
        content: const Text('Sets you already logged are kept, but the workout won’t be marked as completed.'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(context, false), child: const Text('Keep going')),
          CupertinoDialogAction(isDestructiveAction: true, onPressed: () => Navigator.pop(context, true), child: const Text('Quit')),
        ],
      ),
    );
    if (quit == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppScaffold(
      child: SafeArea(
        child: _done
            ? _DoneView(
                workoutName: widget.workout.name,
                difficulty: widget.difficulty,
                sets: _loggedSets,
                volume: _loggedVolume,
                onClose: () => Navigator.of(context).pop(),
              )
            : Column(
                children: [
                  _header(c),
                  Expanded(
                    child: _finishing
                        ? const Center(child: CupertinoActivityIndicator())
                        : _resting
                            ? _restView(c)
                            : _activeView(c),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _header(AppColors c) {
    final total = _steps.length;
    final progress = total == 0 ? 0.0 : (_current / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _confirmQuit,
                child: Padding(padding: const EdgeInsets.all(6), child: Icon(CupertinoIcons.xmark, size: 22, color: c.textPrimary)),
              ),
              Expanded(
                child: Text(widget.workout.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.textPrimary, fontFamily: 'Rubik')),
              ),
              SizedBox(
                width: 34,
                child: Text(_diffLabels[widget.difficulty] ?? '',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.accent, fontFamily: 'Rubik')),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(children: [
              Container(height: 5, color: c.iconBg),
              FractionallySizedBox(widthFactor: progress, child: Container(height: 5, color: c.accent)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _activeView(AppColors c) {
    final s = _steps[_current];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        Text('EXERCISE ${s.exerciseNo} / ${widget.workout.exerciseCount}',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: c.textSecondary, fontFamily: 'Rubik')),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 16 / 10,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: c.iconBg,
              child: s.imageUrl.isEmpty
                  ? Center(child: Icon(CupertinoIcons.photo, size: 40, color: c.textSecondary))
                  : Image.network(s.imageUrl, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Center(child: Icon(CupertinoIcons.photo, size: 40, color: c.textSecondary))),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(s.name,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.textPrimary, fontFamily: 'Rubik')),
        const SizedBox(height: 4),
        Text('Set ${s.setNo} of ${s.setsInExercise}   ·   target ${_fmt(s.plannedWeight)} kg × ${s.plannedReps}',
            style: TextStyle(fontSize: 13, color: c.textSecondary, fontFamily: 'Rubik')),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: _bigField(c, _weightCtrl, 'WEIGHT (KG)')),
          const SizedBox(width: 14),
          Expanded(child: _bigField(c, _repsCtrl, 'REPS')),
        ]),
        const SizedBox(height: 24),
        Pressable(
          onTap: _logCurrentSet,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(14)),
            child: Text(
              _current >= _steps.length - 1 ? 'LOG SET · FINISH' : 'LOG SET',
              style: TextStyle(fontFamily: 'Rubik', fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: c.textOnAccent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _restView(AppColors c) {
    final s = _current + 1 < _steps.length ? _steps[_current + 1] : null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('REST', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 3, color: c.textSecondary, fontFamily: 'Rubik')),
        const SizedBox(height: 12),
        Text('$_restLeft',
            style: TextStyle(fontSize: 76, fontWeight: FontWeight.w800, color: c.accent, fontFamily: 'Rubik', height: 1)),
        const SizedBox(height: 4),
        Text('seconds', style: TextStyle(fontSize: 13, color: c.textSecondary, fontFamily: 'Rubik')),
        if (s != null) ...[
          const SizedBox(height: 28),
          Text('NEXT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: c.textSecondary, fontFamily: 'Rubik')),
          const SizedBox(height: 4),
          Text('${s.name}  ·  set ${s.setNo}/${s.setsInExercise}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary, fontFamily: 'Rubik')),
        ],
        const SizedBox(height: 32),
        CupertinoButton(
          onPressed: _skipRest,
          child: Text('Skip rest', style: TextStyle(color: c.accent, fontWeight: FontWeight.w700, fontFamily: 'Rubik')),
        ),
      ],
    );
  }

  Widget _bigField(AppColors c, TextEditingController ctrl, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.textSecondary, fontFamily: 'Rubik')),
          const SizedBox(height: 6),
          CupertinoTextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, fontFamily: 'Rubik'),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
          ),
        ],
      );

  String _fmt(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
}

class _DoneView extends StatelessWidget {
  final String workoutName;
  final String difficulty;
  final int sets;
  final double volume;
  final VoidCallback onClose;
  const _DoneView({
    required this.workoutName,
    required this.difficulty,
    required this.sets,
    required this.volume,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 84, height: 84,
            decoration: BoxDecoration(color: c.accent.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(CupertinoIcons.checkmark_alt, size: 44, color: c.accent),
          ),
          const SizedBox(height: 20),
          Text('Workout complete', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.textPrimary, fontFamily: 'Rubik')),
          const SizedBox(height: 6),
          Text('$workoutName  ·  ${_diffLabels[difficulty] ?? difficulty}',
              style: TextStyle(fontSize: 13, color: c.textSecondary, fontFamily: 'Rubik')),
          const SizedBox(height: 28),
          Row(children: [
            _stat(c, '$sets', sets == 1 ? 'SET LOGGED' : 'SETS LOGGED'),
            const SizedBox(width: 12),
            _stat(c, '${(volume / 1000).toStringAsFixed(1)} t', 'VOLUME LIFTED'),
          ]),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: Pressable(
              onTap: onClose,
              child: Container(
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(14)),
                child: Text('DONE',
                    style: TextStyle(fontFamily: 'Rubik', fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 2, color: c.textOnAccent)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(AppColors c, String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
          child: Column(children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: c.textPrimary, fontFamily: 'Rubik')),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, letterSpacing: 0.5, color: c.textSecondary, fontFamily: 'Rubik')),
          ]),
        ),
      );
}
