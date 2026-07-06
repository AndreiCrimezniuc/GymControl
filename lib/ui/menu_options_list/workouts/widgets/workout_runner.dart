import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:gymboss/data/repositories/exercises_repository.dart';
import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_scaffold.dart';
import 'package:gymboss/ui/core/ui/widgets/pressable.dart';
import 'package:gymboss/ui/menu_options_list/exercises/widgets/muscle_illustration.dart';

const _diffLabels = {'easy': 'Easy', 'medium': 'Medium', 'hard': 'Hard'};

/// One set the user performs: planned target + the actual weight/reps they log.
class _SetEntry {
  final int exerciseId;
  final int restSeconds;
  final double plannedWeight;
  final int plannedReps;
  final TextEditingController weight;
  final TextEditingController reps;
  bool done = false;

  _SetEntry({
    required this.exerciseId,
    required this.restSeconds,
    required this.plannedWeight,
    required this.plannedReps,
  })  : weight = TextEditingController(text: plannedWeight == 0 ? '' : _fmt(plannedWeight)),
        reps = TextEditingController(text: plannedReps == 0 ? '' : '$plannedReps');

  void dispose() {
    weight.dispose();
    reps.dispose();
  }
}

class _ExGroup {
  final String name;
  final String muscleGroup;
  final int restSeconds;
  final List<_SetEntry> sets;
  _ExGroup({required this.name, required this.muscleGroup, required this.restSeconds, required this.sets});
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
  late final List<_ExGroup> _groups;
  late final int _totalSets;

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
    _groups = _build();
    _totalSets = _groups.fold(0, (a, g) => a + g.sets.length);
  }

  List<_ExGroup> _build() {
    final out = <_ExGroup>[];
    for (final ex in widget.workout.exercises) {
      final planned = ex.setsFor(widget.difficulty);
      if (planned.isEmpty) continue;
      out.add(_ExGroup(
        name: ex.name,
        muscleGroup: ex.muscleGroup,
        restSeconds: ex.restSeconds,
        sets: [
          for (final s in planned)
            _SetEntry(
              exerciseId: ex.exerciseId,
              restSeconds: ex.restSeconds,
              plannedWeight: s.weightKg,
              plannedReps: s.reps,
            ),
        ],
      ));
    }
    return out;
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    for (final g in _groups) {
      for (final s in g.sets) {
        s.dispose();
      }
    }
    super.dispose();
  }

  int get _doneSets => _groups.fold(0, (a, g) => a + g.sets.where((s) => s.done).length);

  Future<void> _toggleSet(_SetEntry s) async {
    if (s.done) {
      setState(() => s.done = false); // allow correcting a mistaken tap; the log stays (append-only)
      return;
    }
    final w = double.tryParse(s.weight.text.trim()) ?? 0;
    final r = int.tryParse(s.reps.text.trim()) ?? 0;
    if (r <= 0) return; // need reps to count the set
    setState(() {
      s.done = true;
      _loggedSets++;
      _loggedVolume += w * r;
    });
    try {
      await widget.exercises.logSet(s.exerciseId, weightKg: w, reps: r);
    } catch (_) {}
    _startRest(s.restSeconds);
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    if (seconds <= 0) return;
    setState(() {
      _resting = true;
      _restLeft = seconds;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_restLeft <= 1) {
        t.cancel();
        setState(() => _resting = false);
      } else {
        setState(() => _restLeft--);
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() => _resting = false);
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
        content: const Text('Sets you already checked off are kept, but the workout won’t be marked as completed.'),
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
            : Stack(
                children: [
                  Column(
                    children: [
                      _header(c),
                      Expanded(child: _body(c)),
                    ],
                  ),
                  // Floating rest pill: pinned to the screen, independent of scroll.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 20,
                    child: IgnorePointer(
                      ignoring: !_resting,
                      child: AnimatedOpacity(
                        opacity: _resting ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Center(child: _RestPill(secondsLeft: _restLeft, onSkip: _skipRest)),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _header(AppColors c) {
    final progress = _totalSets == 0 ? 0.0 : (_doneSets / _totalSets).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Pressable(
                onTap: _confirmQuit,
                child: SizedBox(width: 40, height: 40, child: Icon(CupertinoIcons.xmark, size: 22, color: c.textPrimary)),
              ),
              Expanded(
                child: Text(widget.workout.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.textPrimary, fontFamily: 'Rubik')),
              ),
              SizedBox(
                width: 40,
                child: Text('$_doneSets/$_totalSets',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.accent, fontFamily: 'Rubik')),
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

  Widget _body(AppColors c) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        for (var gi = 0; gi < _groups.length; gi++) _exerciseCard(c, gi + 1, _groups[gi]),
        const SizedBox(height: 8),
        Pressable(
          onTap: _finishing ? null : _finish,
          child: Container(
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: _finishing ? c.iconBg : c.accent, borderRadius: BorderRadius.circular(14)),
            child: _finishing
                ? const CupertinoActivityIndicator()
                : Text(_doneSets >= _totalSets ? 'FINISH · ALL DONE' : 'FINISH WORKOUT',
                    style: TextStyle(fontFamily: 'Rubik', fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: c.textOnAccent)),
          ),
        ),
      ],
    );
  }

  Widget _exerciseCard(AppColors c, int index, _ExGroup g) {
    final doneInEx = g.sets.where((s) => s.done).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            SizedBox(width: 40, height: 40, child: MuscleIllustration.fromMuscle(g.muscleGroup)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$index. ${g.name}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary, fontFamily: 'Rubik')),
                  const SizedBox(height: 2),
                  Text('$doneInEx / ${g.sets.length} sets  ·  rest ${g.restSeconds}s',
                      style: TextStyle(fontSize: 11, color: c.textSecondary, fontFamily: 'Rubik')),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 12),
          // column header
          Row(children: [
            SizedBox(width: 30, child: Text('SET', style: _hdr(c))),
            const Spacer(),
            SizedBox(width: 84, child: Text('KG', textAlign: TextAlign.center, style: _hdr(c))),
            const SizedBox(width: 8),
            SizedBox(width: 84, child: Text('REPS', textAlign: TextAlign.center, style: _hdr(c))),
            const SizedBox(width: 8),
            const SizedBox(width: 36),
          ]),
          const SizedBox(height: 6),
          for (var i = 0; i < g.sets.length; i++) _setRow(c, i + 1, g.sets[i]),
        ],
      ),
    );
  }

  Widget _setRow(AppColors c, int number, _SetEntry s) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('$number',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: s.done ? c.accent : c.textSecondary, fontFamily: 'Rubik')),
          ),
          const Spacer(),
          SizedBox(width: 84, child: _numField(c, s.weight, s.done, 'kg')),
          const SizedBox(width: 8),
          SizedBox(width: 84, child: _numField(c, s.reps, s.done, 'reps')),
          const SizedBox(width: 8),
          Pressable(
            onTap: () => _toggleSet(s),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: s.done ? c.accent : c.iconBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: s.done ? c.accent : c.border),
              ),
              child: Icon(CupertinoIcons.check_mark, size: 20, color: s.done ? c.textOnAccent : c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numField(AppColors c, TextEditingController ctrl, bool done, String hint) => CupertinoTextField(
        controller: ctrl,
        readOnly: done,
        placeholder: hint,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: TextStyle(color: done ? c.textSecondary : c.textPrimary, fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Rubik'),
        placeholderStyle: TextStyle(color: c.textSecondary, fontSize: 13),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: done ? c.card : c.iconBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.border),
        ),
      );

  TextStyle _hdr(AppColors c) =>
      TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: c.textSecondary, fontFamily: 'Rubik');
}

class _RestPill extends StatelessWidget {
  final int secondsLeft;
  final VoidCallback onSkip;
  const _RestPill({required this.secondsLeft, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mm = secondsLeft ~/ 60;
    final ss = secondsLeft % 60;
    final label = mm > 0 ? '$mm:${ss.toString().padLeft(2, '0')}' : '${ss}s';
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
      decoration: BoxDecoration(
        color: c.invBg,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: const Color(0x33000000), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.timer, size: 18, color: c.invText),
          const SizedBox(width: 8),
          Text('Rest  $label',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.invText, fontFamily: 'Rubik')),
          const SizedBox(width: 12),
          Pressable(
            onTap: onSkip,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(20)),
              child: Text('Skip',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.textOnAccent, fontFamily: 'Rubik')),
            ),
          ),
        ],
      ),
    );
  }
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
            width: 84,
            height: 84,
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

String _fmt(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
