import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/units/units_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_dialog.dart';
import 'package:gymboss/ui/core/ui/widgets/app_scaffold.dart';
import 'package:gymboss/ui/core/ui/widgets/pressable.dart';
import 'package:gymboss/domain/models/exercises/exercise_catalog.dart';
import 'package:gymboss/ui/menu_options_list/exercises/widgets/muscle_illustration.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/workout_session_controller.dart';
import 'package:gymboss/ui/menu_options_list/workouts/widgets/exercise_picker.dart';

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
        _weight[s] = TextEditingController(text: s.weight)
          ..addListener(() => s.weight = _weight[s]!.text);
        _reps[s] = TextEditingController(text: s.reps)
          ..addListener(() => s.reps = _reps[s]!.text);
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

  // Lazily bind text controllers to a set so sets added mid-session get theirs.
  TextEditingController _wc(SessionSet s) => _weight.putIfAbsent(
    s,
    () =>
        TextEditingController(text: s.weight)
          ..addListener(() => s.weight = _weight[s]!.text),
  );
  TextEditingController _rc(SessionSet s) => _reps.putIfAbsent(
    s,
    () =>
        TextEditingController(text: s.reps)
          ..addListener(() => s.reps = _reps[s]!.text),
  );

  void _disposeSetControllers(SessionSet s) {
    _weight.remove(s)?.dispose();
    _reps.remove(s)?.dispose();
  }

  void _minimize() {
    context.read<WorkoutSessionController>().minimize();
    Navigator.of(context).pop();
  }

  Future<void> _addExercise(WorkoutSessionController session) async {
    final picked = await Navigator.of(context, rootNavigator: true)
        .push<ExerciseCatalogItem>(
          CupertinoPageRoute(
            builder: (_) => ExercisePicker(repo: session.exercisesRepo),
          ),
        );
    if (picked == null) return;
    session.addExercise(
      exerciseId: picked.id,
      name: picked.name,
      muscleGroup: picked.muscleGroup,
      imageUrl: picked.imageUrl,
      imageUrl2: picked.imageUrl2,
    );
  }

  Future<void> _confirmRemoveExercise(
    WorkoutSessionController session,
    SessionExercise g,
  ) async {
    HapticFeedback.selectionClick();
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(g.name),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              for (final s in g.sets) {
                _disposeSetControllers(s);
              }
              session.removeExercise(g);
              Navigator.of(ctx).pop();
            },
            child: const Text('Remove exercise'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _confirmQuit() async {
    final quit = await showAppDialog<bool>(
      context,
      title: 'Quit workout?',
      message:
          'Sets you already checked off are kept, but the workout won’t be marked as completed.',
      actions: [
        AppDialogAction(
          'Keep going',
          onPressed: () => Navigator.pop(context, false),
        ),
        AppDialogAction(
          'Quit',
          isDestructive: true,
          onPressed: () => Navigator.pop(context, true),
        ),
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
                        offset: session.resting
                            ? Offset.zero
                            : const Offset(0, 0.4),
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
    final progress = s.totalSets == 0
        ? 0.0
        : (s.doneSets / s.totalSets).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        children: [
          Row(
            children: [
              Pressable(
                onTap: _minimize,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    CupertinoIcons.chevron_down,
                    size: 22,
                    color: c.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  s.workout?.name ?? 'Workout',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                    fontFamily: 'Rubik',
                  ),
                ),
              ),
              Pressable(
                onTap: _confirmQuit,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: 20,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              children: [
                Container(height: 5, color: c.iconBg),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(height: 5, color: c.accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(CupertinoIcons.time, size: 14, color: c.textSecondary),
              const SizedBox(width: 5),
              Text(
                s.elapsed,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                  fontFamily: 'Rubik',
                ),
              ),
              const Spacer(),
              Text(
                '${s.doneSets}/${s.totalSets} sets',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: c.accent,
                  fontFamily: 'Rubik',
                ),
              ),
              const Spacer(),
              Icon(
                CupertinoIcons.chart_bar_alt_fill,
                size: 14,
                color: c.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                context.watch<UnitsController>().formatVolume(s.loggedVolumeKg),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                  fontFamily: 'Rubik',
                ),
              ),
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
        for (var gi = 0; gi < s.groups.length; gi++)
          _exerciseCard(c, s, units, gi + 1, s.groups[gi]),
        _addRowButton(
          c,
          CupertinoIcons.add,
          'Add exercise',
          () => _addExercise(s),
        ),
      ],
    );
  }

  // A dashed, full-width "add" affordance used for both add-set and
  // add-exercise so the two read as the same gesture.
  Widget _addRowButton(
    AppColors c,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: c.accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: c.accent,
                fontFamily: 'Rubik',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _finishBar(AppColors c, WorkoutSessionController s) {
    final allDone = s.doneSets >= s.totalSets;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Pressable(
        onTap: () => s.finish(),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.accent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                allDone
                    ? CupertinoIcons.checkmark_alt
                    : CupertinoIcons.flag_fill,
                size: 18,
                color: c.textOnAccent,
              ),
              const SizedBox(width: 8),
              Text(
                allDone ? 'FINISH · ALL DONE' : 'FINISH WORKOUT',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: c.textOnAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exerciseCard(
    AppColors c,
    WorkoutSessionController session,
    UnitsController units,
    int index,
    SessionExercise g,
  ) {
    final doneInEx = g.sets.where((s) => s.done).length;
    final allDone = doneInEx == g.sets.length;
    final pr = g.sets.isNotEmpty
        ? session.prFor(g.sets.first.exerciseId)
        : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
        boxShadow: c.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: ExerciseVisual(
                    name: g.name,
                    muscleGroup: g.muscleGroup,
                    category: '',
                    imageUrl: g.imageUrl,
                    imageUrl2: g.imageUrl2,
                    radius: 14,
                    figurePadding: 6,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$index. ${g.name}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary,
                          fontFamily: 'Rubik',
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${g.sets.length} sets  ·  rest ${g.restSeconds}s'
                        '${pr != null ? '  ·  PR ${units.format(pr)}${units.label}' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: c.textSecondary,
                          fontFamily: 'Rubik',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _timerToggle(c, session, index, g),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: allDone ? c.accent : c.iconBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$doneInEx/${g.sets.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: allDone ? c.textOnAccent : c.textSecondary,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Pressable(
                  onTap: () => _confirmRemoveExercise(session, g),
                  child: SizedBox(
                    width: 30,
                    height: 34,
                    child: Icon(
                      CupertinoIcons.ellipsis,
                      size: 18,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (session.exTimerKey == index) _exTimerPanel(c, session),
          Container(height: 1, color: c.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              children: [
                for (var i = 0; i < g.sets.length; i++)
                  _setRow(c, session, units, g, i + 1, g.sets[i]),
                const SizedBox(height: 4),
                _addRowButton(
                  c,
                  CupertinoIcons.add,
                  'Add set',
                  () => session.addSet(g),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtClock(int seconds) {
    final m = (seconds ~/ 60).toString();
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // Stopwatch button in the exercise header. Starts a per-exercise countdown
  // (defaulting to the planned rest) or hides the panel when already shown.
  Widget _timerToggle(
    AppColors c,
    WorkoutSessionController session,
    int index,
    SessionExercise g,
  ) {
    final active = session.exTimerKey == index;
    return Pressable(
      onTap: () {
        if (active) {
          session.stopExerciseTimer();
        } else {
          HapticFeedback.selectionClick();
          session.startExerciseTimer(
            index,
            g.restSeconds > 0 ? g.restSeconds : 60,
          );
        }
      },
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? c.accent.withValues(alpha: 0.16) : c.iconBg,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          CupertinoIcons.timer,
          size: 19,
          color: active ? c.accent : c.textSecondary,
        ),
      ),
    );
  }

  Widget _exTimerPanel(AppColors c, WorkoutSessionController session) {
    final left = session.exTimerLeft;
    final total = session.exTimerTotal;
    final running = session.exTimerRunning;
    final progress = total == 0 ? 0.0 : (left / total).clamp(0.0, 1.0);
    final done = left == 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _fmtClock(left),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: done ? c.accent : c.textPrimary,
                  fontFamily: 'Rubik',
                ),
              ),
              const Spacer(),
              _timerCtl(
                c,
                CupertinoIcons.minus,
                () => session.adjustExerciseTimer(-15),
              ),
              const SizedBox(width: 6),
              _timerCtl(
                c,
                CupertinoIcons.add,
                () => session.adjustExerciseTimer(15),
              ),
              const SizedBox(width: 6),
              _timerCtl(
                c,
                CupertinoIcons.arrow_counterclockwise,
                () => session.resetExerciseTimer(),
              ),
              const SizedBox(width: 6),
              // primary start / pause / resume control
              Pressable(
                onTap: () {
                  if (done) {
                    session.resetExerciseTimer();
                    session.resumeExerciseTimer();
                  } else if (running) {
                    session.pauseExerciseTimer();
                  } else {
                    session.resumeExerciseTimer();
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    running
                        ? CupertinoIcons.pause_fill
                        : CupertinoIcons.play_fill,
                    size: 20,
                    color: c.textOnAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              children: [
                Container(height: 4, color: c.iconBg),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(height: 4, color: c.accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timerCtl(AppColors c, IconData icon, VoidCallback onTap) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.iconBg,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, size: 17, color: c.textSecondary),
      ),
    );
  }

  Widget _setRow(
    AppColors c,
    WorkoutSessionController session,
    UnitsController units,
    SessionExercise g,
    int number,
    SessionSet s,
  ) {
    return Dismissible(
      key: ObjectKey(s),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        _disposeSetControllers(s);
        session.removeSet(g, s);
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(right: 18),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: c.accent.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(CupertinoIcons.delete, size: 20, color: c.accent),
      ),
      child: Container(
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
              child: Text(
                '$number',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: s.done ? c.textOnAccent : c.textSecondary,
                  fontFamily: 'Rubik',
                ),
              ),
            ),
            if (s.progression.isNotEmpty) ...[
              const SizedBox(width: 6),
              _progressionBadge(c, s.progression),
            ],
            const SizedBox(width: 8),
            Expanded(child: _numField(c, _wc(s), s.done, units.label)),
            const SizedBox(width: 8),
            Expanded(child: _numField(c, _rc(s), s.done, 'reps')),
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
                child: Icon(
                  CupertinoIcons.check_mark,
                  size: 22,
                  color: s.done ? c.textOnAccent : c.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Compact tag on a set row indicating a non-weight progression.
  Widget _progressionBadge(AppColors c, String progression) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        _progressionBadges[progression] ?? '',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: c.accent,
          fontFamily: 'Rubik',
        ),
      ),
    );
  }

  // Presentation for each set type: a short badge letter plus the explicit name
  // and description shown in the picker so the choice is never cryptic.
  ({Color bg, Color fg, String badge}) _typeVisual(AppColors c, String type) {
    switch (type) {
      case 'warmup':
        return (
          bg: const Color(0x33F59E0B),
          fg: const Color(0xFFB45309),
          badge: 'W',
        );
      case 'failure':
        return (bg: c.accent.withValues(alpha: 0.16), fg: c.accent, badge: 'F');
      default:
        return (bg: c.card, fg: c.textSecondary, badge: '•');
    }
  }

  Widget _typeChip(
    AppColors c,
    WorkoutSessionController session,
    SessionSet s,
  ) {
    final v = _typeVisual(c, s.type);
    return Pressable(
      onTap: s.done ? null : () => _pickSetType(session, s),
      child: Container(
        width: 40,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: v.bg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: s.type == 'working' ? c.border : const Color(0x00000000),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              v.badge,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: v.fg,
                fontFamily: 'Rubik',
              ),
            ),
            if (!s.done)
              Icon(CupertinoIcons.chevron_down, size: 11, color: v.fg),
          ],
        ),
      ),
    );
  }

  // Explicit set-type selector so the type (warm-up / working / failure) is
  // chosen from named options instead of a blind tap-to-cycle.
  static const _typeNames = {
    'warmup': 'Warm-up',
    'working': 'Working',
    'failure': 'Failure',
  };
  static const _typeDescriptions = {
    'warmup': 'Excluded from working volume',
    'working': 'Counts toward volume & PRs',
    'failure': 'Taken to muscular failure',
  };
  static const _progressionNames = {
    'weight': 'Heavier weight',
    'amplitude': 'Greater amplitude',
    'efficiency': 'Better efficiency',
    'meo': 'MEO / myo-rep set',
    'dropset': 'Drop set',
  };
  // Short badge shown on a set row once progress has been tagged.
  static const _progressionBadges = {
    'weight': 'WT',
    'amplitude': 'AMP',
    'efficiency': 'EFF',
    'meo': 'MEO',
    'dropset': 'DROP',
  };

  void _pickSetType(WorkoutSessionController session, SessionSet s) {
    HapticFeedback.selectionClick();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Set type'),
        actions: [
          for (final t in setTypes)
            CupertinoActionSheetAction(
              onPressed: () {
                session.setSetType(s, t);
                Navigator.of(ctx).pop();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (s.type == t) ...[
                    const Icon(CupertinoIcons.check_mark, size: 18),
                    const SizedBox(width: 6),
                  ],
                  Column(
                    children: [
                      Text(
                        _typeNames[t]!,
                        style: TextStyle(
                          fontWeight: s.type == t
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      Text(
                        _typeDescriptions[t]!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _pickProgression(session, s);
            },
            child: Text(
              s.progression.isEmpty
                  ? 'Progression tag…'
                  : 'Progression: ${_progressionNames[s.progression]}',
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  // Tag how the set progressed (amplitude, efficiency, MEO/drop-set, …) beyond
  // just adding load — issue #4.
  void _pickProgression(WorkoutSessionController session, SessionSet s) {
    HapticFeedback.selectionClick();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('How did this set progress?'),
        actions: [
          for (final p in progressionTypes)
            CupertinoActionSheetAction(
              onPressed: () {
                session.setProgression(s, p);
                Navigator.of(ctx).pop();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (s.progression == p) ...[
                    const Icon(CupertinoIcons.check_mark, size: 18),
                    const SizedBox(width: 6),
                  ],
                  Text(_progressionNames[p]!),
                ],
              ),
            ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              session.setProgression(s, '');
              Navigator.of(ctx).pop();
            },
            child: const Text('No progression tag'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Widget _numField(
    AppColors c,
    TextEditingController ctrl,
    bool done,
    String unit,
  ) => CupertinoTextField(
    controller: ctrl,
    readOnly: done,
    placeholder: '0',
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    textAlign: TextAlign.center,
    style: TextStyle(
      color: c.textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w800,
      fontFamily: 'Rubik',
    ),
    placeholderStyle: TextStyle(color: c.textSecondary, fontSize: 16),
    suffix: Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        unit,
        style: TextStyle(
          fontSize: 11,
          color: c.textSecondary,
          fontFamily: 'Rubik',
        ),
      ),
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
  const _RestPill({
    required this.secondsLeft,
    required this.onSkip,
    required this.onAdd,
    required this.onSub,
  });

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
        boxShadow: [
          BoxShadow(
            color: const Color(0x33000000),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
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
            child: Text(
              'Rest $label',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: c.invText,
                fontFamily: 'Rubik',
              ),
            ),
          ),
          const SizedBox(width: 6),
          _round(c, CupertinoIcons.plus, onAdd),
          const SizedBox(width: 8),
          Pressable(
            onTap: onSkip,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: c.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Skip',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: c.textOnAccent,
                  fontFamily: 'Rubik',
                ),
              ),
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
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        shape: BoxShape.circle,
      ),
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
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.checkmark_alt,
              size: 44,
              color: c.accent,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Workout complete',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
              fontFamily: 'Rubik',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$workoutName  ·  ${_diffLabels[difficulty] ?? difficulty}',
            style: TextStyle(
              fontSize: 13,
              color: c.textSecondary,
              fontFamily: 'Rubik',
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              _stat(c, '$sets', sets == 1 ? 'SET LOGGED' : 'SETS LOGGED'),
              const SizedBox(width: 12),
              _stat(
                c,
                context.watch<UnitsController>().formatVolume(volumeKg),
                'VOLUME LIFTED',
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: Pressable(
              onTap: onClose,
              child: Container(
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'DONE',
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: c.textOnAccent,
                  ),
                ),
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
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
              fontFamily: 'Rubik',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.5,
              color: c.textSecondary,
              fontFamily: 'Rubik',
            ),
          ),
        ],
      ),
    ),
  );
}
