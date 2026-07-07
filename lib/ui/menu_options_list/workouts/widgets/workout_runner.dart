import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gymboss/data/repositories/exercises_repository.dart';
import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/units/units_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_dialog.dart';
import 'package:gymboss/ui/core/ui/widgets/app_scaffold.dart';
import 'package:gymboss/ui/core/ui/widgets/pressable.dart';
import 'package:gymboss/ui/menu_options_list/exercises/widgets/exercise_mannequin.dart';

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
    required String weightText,
  })  : weight = TextEditingController(text: weightText),
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
  late final UnitsController _units;
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
    _units = context.read<UnitsController>();
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
              weightText: s.weightKg == 0 ? '' : _fmt(_units.fromKg(s.weightKg)),
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
    final w = _units.toKg(double.tryParse(s.weight.text.trim()) ?? 0);
    final r = int.tryParse(s.reps.text.trim()) ?? 0;
    if (r <= 0) return; // need reps to count the set
    HapticFeedback.mediumImpact();
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
        _restDone();
      } else {
        setState(() => _restLeft--);
      }
    });
  }

  void _restDone() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
    if (mounted) setState(() => _resting = false);
  }

  void _adjustRest(int delta) {
    setState(() => _restLeft = (_restLeft + delta).clamp(0, 3600));
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
    HapticFeedback.heavyImpact();
    if (mounted) setState(() { _finishing = false; _done = true; });
  }

  Future<void> _confirmQuit() async {
    if (_done) { Navigator.of(context).pop(); return; }
    final quit = await showAppDialog<bool>(
      context,
      title: 'Quit workout?',
      message: 'Sets you already checked off are kept, but the workout won’t be marked as completed.',
      actions: [
        AppDialogAction('Keep going', onPressed: () => Navigator.pop(context, false)),
        AppDialogAction('Quit', isDestructive: true, onPressed: () => Navigator.pop(context, true)),
      ],
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
                      _finishBar(c),
                    ],
                  ),
                  // Floating rest pill: pinned to the screen, independent of
                  // scroll, hovering just above the finish bar.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 92,
                    child: IgnorePointer(
                      ignoring: !_resting,
                      child: AnimatedSlide(
                        offset: _resting ? Offset.zero : const Offset(0, 0.4),
                        duration: const Duration(milliseconds: 220),
                        curve: const Cubic(0.23, 1, 0.32, 1),
                        child: AnimatedOpacity(
                          opacity: _resting ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Center(
                          child: _RestPill(
                            secondsLeft: _restLeft,
                            onSkip: _skipRest,
                            onAdd: () => _adjustRest(15),
                            onSub: () => _adjustRest(-15),
                          ),
                        ),
                        ),
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
      children: [
        for (var gi = 0; gi < _groups.length; gi++) _exerciseCard(c, gi + 1, _groups[gi]),
      ],
    );
  }

  Widget _finishBar(AppColors c) {
    final allDone = _doneSets >= _totalSets;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Pressable(
        onTap: _finishing ? null : _finish,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _finishing ? c.iconBg : c.accent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: _finishing
              ? const CupertinoActivityIndicator()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(allDone ? CupertinoIcons.checkmark_alt : CupertinoIcons.flag_fill, size: 18, color: c.textOnAccent),
                    const SizedBox(width: 8),
                    Text(allDone ? 'FINISH · ALL DONE' : 'FINISH WORKOUT',
                        style: TextStyle(fontFamily: 'Rubik', fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1, color: c.textOnAccent)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _exerciseCard(AppColors c, int index, _ExGroup g) {
    final doneInEx = g.sets.where((s) => s.done).length;
    final allDone = doneInEx == g.sets.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: c.iconBg, borderRadius: BorderRadius.circular(14)),
                child: ExerciseMannequin(pattern: patternFor(name: g.name, muscle: g.muscleGroup, equipment: '')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$index. ${g.name}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.textPrimary, fontFamily: 'Rubik')),
                    const SizedBox(height: 3),
                    Text('${g.sets.length} sets  ·  rest ${g.restSeconds}s',
                        style: TextStyle(fontSize: 12, color: c.textSecondary, fontFamily: 'Rubik')),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: allDone ? c.accent : c.iconBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$doneInEx/${g.sets.length}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: allDone ? c.textOnAccent : c.textSecondary, fontFamily: 'Rubik')),
              ),
            ]),
          ),
          Container(height: 1, color: c.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(children: [for (var i = 0; i < g.sets.length; i++) _setRow(c, i + 1, g.sets[i])]),
          ),
        ],
      ),
    );
  }

  Widget _setRow(AppColors c, int number, _SetEntry s) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: s.done ? c.accent.withValues(alpha: 0.10) : c.iconBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: s.done ? c.accent : c.card,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: s.done ? c.accent : c.border),
            ),
            child: Text('$number',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: s.done ? c.textOnAccent : c.textSecondary, fontFamily: 'Rubik')),
          ),
          const SizedBox(width: 10),
          Expanded(child: _numField(c, s.weight, s.done, _units.label)),
          const SizedBox(width: 8),
          Expanded(child: _numField(c, s.reps, s.done, 'reps')),
          const SizedBox(width: 10),
          Pressable(
            onTap: () => _toggleSet(s),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: s.done ? c.accent : c.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: s.done ? c.accent : c.border),
              ),
              child: Icon(CupertinoIcons.check_mark, size: 22, color: s.done ? c.textOnAccent : c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numField(AppColors c, TextEditingController ctrl, bool done, String unit) => CupertinoTextField(
        controller: ctrl,
        readOnly: done,
        placeholder: '0',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Rubik'),
        placeholderStyle: TextStyle(color: c.textSecondary, fontSize: 16),
        suffix: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text(unit, style: TextStyle(fontSize: 11, color: c.textSecondary, fontFamily: 'Rubik')),
        ),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border),
        ),
      );
}

class _RestPill extends StatelessWidget {
  final int secondsLeft;
  final VoidCallback onSkip;
  final VoidCallback onAdd;
  final VoidCallback onSub;
  const _RestPill({required this.secondsLeft, required this.onSkip, required this.onAdd, required this.onSub});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mm = secondsLeft ~/ 60;
    final ss = secondsLeft % 60;
    final label = mm > 0 ? '$mm:${ss.toString().padLeft(2, '0')}' : '${ss}s';
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: c.invBg,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: const Color(0x33000000), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _round(c, CupertinoIcons.minus, onSub),
          const SizedBox(width: 8),
          Icon(CupertinoIcons.timer, size: 17, color: c.invText),
          const SizedBox(width: 6),
          SizedBox(
            width: 62,
            child: Text('Rest $label',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.invText, fontFamily: 'Rubik')),
          ),
          const SizedBox(width: 6),
          _round(c, CupertinoIcons.plus, onAdd),
          const SizedBox(width: 8),
          Pressable(
            onTap: onSkip,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(20)),
              child: Text('Skip',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.textOnAccent, fontFamily: 'Rubik')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _round(AppColors c, IconData icon, VoidCallback onTap) => Pressable(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: const Color(0x22FFFFFF), shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: c.invText),
        ),
      );
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
