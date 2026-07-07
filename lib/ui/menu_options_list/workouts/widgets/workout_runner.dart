import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/units/units_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_dialog.dart';
import 'package:gymboss/ui/core/ui/widgets/app_scaffold.dart';
import 'package:gymboss/ui/core/ui/widgets/pressable.dart';
import 'package:gymboss/ui/menu_options_list/exercises/widgets/exercise_mannequin.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/workout_session_controller.dart';

const _diffLabels = {'easy': 'Easy', 'medium': 'Medium', 'hard': 'Hard'};

/// A view over the global [WorkoutSessionController]. Holds no session state of
/// its own (so the session survives minimize/resume) — only the text
/// controllers bound to the session's sets.
class WorkoutRunnerScreen extends StatefulWidget {
  const WorkoutRunnerScreen({super.key});

  @override
  State<WorkoutRunnerScreen> createState() => _WorkoutRunnerScreenState();
}

class _WorkoutRunnerScreenState extends State<WorkoutRunnerScreen> {
  final Map<SessionSet, TextEditingController> _weight = {};
  final Map<SessionSet, TextEditingController> _reps = {};

  @override
  void initState() {
    super.initState();
    final session = context.read<WorkoutSessionController>();
    for (final g in session.groups) {
      for (final s in g.sets) {
        _weight[s] = TextEditingController(text: s.weight)..addListener(() => s.weight = _weight[s]!.text);
        _reps[s] = TextEditingController(text: s.reps)..addListener(() => s.reps = _reps[s]!.text);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _weight.values) {
      c.dispose();
    }
    for (final c in _reps.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _minimize() {
    context.read<WorkoutSessionController>().minimize();
    Navigator.of(context).pop();
  }

  Future<void> _confirmQuit() async {
    final quit = await showAppDialog<bool>(
      context,
      title: 'Quit workout?',
      message: 'Sets you already checked off are kept, but the workout won’t be marked as completed.',
      actions: [
        AppDialogAction('Keep going', onPressed: () => Navigator.pop(context, false)),
        AppDialogAction('Quit', isDestructive: true, onPressed: () => Navigator.pop(context, true)),
      ],
    );
    if (quit == true && mounted) {
      context.read<WorkoutSessionController>().clear();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final session = context.watch<WorkoutSessionController>();
    final units = context.watch<UnitsController>();

    if (!session.isActive) {
      // session was cleared elsewhere; bail out
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return const AppScaffold(child: SizedBox.shrink());
    }

    return AppScaffold(
      child: SafeArea(
        child: session.isFinished
            ? _DoneView(
                workoutName: session.workout?.name ?? '',
                difficulty: session.difficulty,
                sets: session.loggedSets,
                volumeKg: session.loggedVolumeKg,
                onClose: () {
                  session.clear();
                  Navigator.of(context).pop();
                },
              )
            : Stack(
                children: [
                  Column(
                    children: [
                      _header(c, session),
                      Expanded(child: _body(c, session, units)),
                      _finishBar(c, session),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 92,
                    child: IgnorePointer(
                      ignoring: !session.resting,
                      child: AnimatedSlide(
                        offset: session.resting ? Offset.zero : const Offset(0, 0.4),
                        duration: const Duration(milliseconds: 220),
                        curve: const Cubic(0.23, 1, 0.32, 1),
                        child: AnimatedOpacity(
                          opacity: session.resting ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Center(
                            child: _RestPill(
                              secondsLeft: session.restLeft,
                              onSkip: session.skipRest,
                              onAdd: () => session.adjustRest(15),
                              onSub: () => session.adjustRest(-15),
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

  Widget _header(AppColors c, WorkoutSessionController s) {
    final progress = s.totalSets == 0 ? 0.0 : (s.doneSets / s.totalSets).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        children: [
          Row(
            children: [
              Pressable(
                onTap: _minimize,
                child: SizedBox(width: 40, height: 40, child: Icon(CupertinoIcons.chevron_down, size: 22, color: c.textPrimary)),
              ),
              Expanded(
                child: Text(s.workout?.name ?? 'Workout',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.textPrimary, fontFamily: 'Rubik')),
              ),
              Pressable(
                onTap: _confirmQuit,
                child: SizedBox(width: 40, height: 40, child: Icon(CupertinoIcons.xmark, size: 20, color: c.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(children: [
              Container(height: 5, color: c.iconBg),
              FractionallySizedBox(widthFactor: progress, child: Container(height: 5, color: c.accent)),
            ]),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(CupertinoIcons.time, size: 14, color: c.textSecondary),
              const SizedBox(width: 5),
              Text(s.elapsed, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary, fontFamily: 'Rubik')),
              const Spacer(),
              Text('${s.doneSets}/${s.totalSets} sets',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.accent, fontFamily: 'Rubik')),
              const Spacer(),
              Icon(CupertinoIcons.chart_bar_alt_fill, size: 14, color: c.textSecondary),
              const SizedBox(width: 5),
              Text(context.watch<UnitsController>().formatVolume(s.loggedVolumeKg),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary, fontFamily: 'Rubik')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _body(AppColors c, WorkoutSessionController s, UnitsController units) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
      children: [
        for (var gi = 0; gi < s.groups.length; gi++) _exerciseCard(c, s, units, gi + 1, s.groups[gi]),
      ],
    );
  }

  Widget _finishBar(AppColors c, WorkoutSessionController s) {
    final allDone = s.doneSets >= s.totalSets;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(color: c.bg, border: Border(top: BorderSide(color: c.border))),
      child: Pressable(
        onTap: () => s.finish(),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(16)),
          child: Row(
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

  Widget _exerciseCard(AppColors c, WorkoutSessionController session, UnitsController units, int index, SessionExercise g) {
    final doneInEx = g.sets.where((s) => s.done).length;
    final allDone = doneInEx == g.sets.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.border), boxShadow: c.cardShadow),
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
                decoration: BoxDecoration(color: allDone ? c.accent : c.iconBg, borderRadius: BorderRadius.circular(20)),
                child: Text('$doneInEx/${g.sets.length}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: allDone ? c.textOnAccent : c.textSecondary, fontFamily: 'Rubik')),
              ),
            ]),
          ),
          Container(height: 1, color: c.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(children: [for (var i = 0; i < g.sets.length; i++) _setRow(c, session, units, i + 1, g.sets[i])]),
          ),
        ],
      ),
    );
  }

  Widget _setRow(AppColors c, WorkoutSessionController session, UnitsController units, int number, SessionSet s) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: s.done ? c.accent.withValues(alpha: 0.10) : c.iconBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _typeChip(c, session, s),
          const SizedBox(width: 7),
          Container(
            width: 26,
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
          const SizedBox(width: 8),
          Expanded(child: _numField(c, _weight[s]!, s.done, units.label)),
          const SizedBox(width: 8),
          Expanded(child: _numField(c, _reps[s]!, s.done, 'reps')),
          const SizedBox(width: 10),
          Pressable(
            onTap: () => session.toggleSet(s),
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

  Widget _typeChip(AppColors c, WorkoutSessionController session, SessionSet s) {
    late final Color bg;
    late final Color fg;
    late final String label;
    switch (s.type) {
      case 'warmup':
        bg = const Color(0x33F59E0B);
        fg = const Color(0xFFB45309);
        label = 'W';
        break;
      case 'failure':
        bg = c.accent.withValues(alpha: 0.16);
        fg = c.accent;
        label = 'F';
        break;
      default:
        bg = c.card;
        fg = c.textSecondary;
        label = '•';
    }
    return Pressable(
      onTap: () => session.cycleSetType(s),
      child: Container(
        width: 28,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: s.type == 'working' ? c.border : const Color(0x00000000)),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: fg, fontFamily: 'Rubik')),
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
        decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.border)),
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
  final double volumeKg;
  final VoidCallback onClose;
  const _DoneView({
    required this.workoutName,
    required this.difficulty,
    required this.sets,
    required this.volumeKg,
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
            _stat(c, context.watch<UnitsController>().formatVolume(volumeKg), 'VOLUME LIFTED'),
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
