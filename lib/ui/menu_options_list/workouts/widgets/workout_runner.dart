import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/app_design.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/input/numeric_limit_formatter.dart';
import 'package:gymboss/ui/core/units/units_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_dialog.dart';
import 'package:gymboss/ui/core/ui/widgets/app_scaffold.dart';
import 'package:gymboss/ui/core/ui/widgets/pressable.dart';
import 'package:gymboss/domain/models/exercises/exercise_catalog.dart';
import 'package:gymboss/ui/menu_options_list/exercises/widgets/muscle_illustration.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/workout_session_controller.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/workout_calculators.dart';
import 'package:gymboss/ui/menu_options_list/workouts/widgets/exercise_picker.dart';

const _diffLabels = {'normal': 'Normal', 'deload': 'Deload'};

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
  bool _finishing = false;

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
    final picked = await Navigator.of(
      context,
      rootNavigator: true,
    ).push<ExerciseCatalogItem>(
      CupertinoPageRoute(
        builder:
            (_) => ExercisePicker(
              repo: session.exercisesRepo,
              excludedIds:
                  session.groups
                      .expand((group) => group.sets)
                      .map((set) => set.exerciseId)
                      .toSet(),
            ),
      ),
    );
    if (picked == null) return;
    session.addExercise(
      exerciseId: picked.id,
      name: picked.name,
      muscleGroup: picked.muscleGroup,
      exerciseType: picked.exerciseType,
      imageUrl: picked.imageUrl,
      imageUrl2: picked.imageUrl2,
    );
  }

  Future<void> _confirmRemoveExercise(
    WorkoutSessionController session,
    SessionExercise g,
  ) async {
    HapticFeedback.selectionClick();
    final i = session.groups.indexOf(g);
    final canUp = i > 0;
    final canDown = i >= 0 && i < session.groups.length - 1;
    await showCupertinoModalPopup<void>(
      context: context,
      builder:
          (ctx) => CupertinoActionSheet(
            title: Text(g.name),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _editExerciseNote(session, g);
                },
                child: Text(g.note.isEmpty ? 'Add note' : 'Edit note'),
              ),
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final sets = await showWarmupCalculator(
                    context,
                    initialWeight:
                        g.sets.isEmpty ? 0 : g.sets.first.plannedWeightKg,
                  );
                  if (sets != null) session.prependWarmupSets(g, sets);
                },
                child: const Text('Warm-up calculator'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  showPlateCalculator(
                    context,
                    initialWeight:
                        g.sets.isEmpty ? 0 : g.sets.first.plannedWeightKg,
                  );
                },
                child: const Text('Plate calculator'),
              ),
              if (session.canGroupWithNext(g))
                CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _pickTrainingGroup(session, g);
                  },
                  child: Text(
                    g.trainingGroupId == null
                        ? 'Group with next…'
                        : 'Extend group to next…',
                  ),
                ),
              if (g.trainingGroupId != null)
                CupertinoActionSheetAction(
                  isDestructiveAction: true,
                  onPressed: () {
                    session.ungroup(g);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Remove exercise group'),
                ),
              if (canUp)
                CupertinoActionSheetAction(
                  onPressed: () {
                    session.moveExercise(g, -1);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Move up'),
                ),
              if (canDown)
                CupertinoActionSheetAction(
                  onPressed: () {
                    session.moveExercise(g, 1);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Move down'),
                ),
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

  Future<void> _pickTrainingGroup(
    WorkoutSessionController session,
    SessionExercise exercise,
  ) async {
    final type = await showCupertinoModalPopup<String>(
      context: context,
      builder:
          (ctx) => CupertinoActionSheet(
            title: const Text('Training group'),
            message: const Text(
              'Grouped exercises advance without starting the rest timer until the round is complete.',
            ),
            actions: [
              for (final item in const [
                ('superset', 'Superset'),
                ('circuit', 'Circuit'),
                ('interval', 'Interval block'),
              ])
                CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(ctx, item.$1),
                  child: Text(item.$2),
                ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ),
    );
    if (type != null) session.groupWithNext(exercise, type);
  }

  Future<void> _editExerciseNote(
    WorkoutSessionController session,
    SessionExercise exercise,
  ) async {
    final controller = TextEditingController(text: exercise.note);
    final note = await showCupertinoDialog<String>(
      context: context,
      builder:
          (ctx) => CupertinoAlertDialog(
            title: const Text('Exercise note'),
            content: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: CupertinoTextField(
                controller: controller,
                autofocus: true,
                minLines: 2,
                maxLines: 5,
                placeholder: 'Form cues, pain, target for next time…',
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(ctx).pop(controller.text),
                child: const Text('Save'),
              ),
            ],
          ),
    );
    controller.dispose();
    if (note != null) session.setExerciseNote(exercise, note);
  }

  Future<void> _confirmQuit() async {
    final quit = await showAppDialog<bool>(
      context,
      title: 'Quit workout?',
      message: 'This workout and all checked sets will be discarded.',
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

  Future<void> _confirmFinish(WorkoutSessionController session) async {
    final choice = await showAppDialog<String>(
      context,
      title: 'Finish workout?',
      message:
          '${session.doneSets} of ${session.totalSets} sets are complete. Choose how you want to finish.',
      actions: [
        AppDialogAction(
          'Finish without saving',
          isDestructive: true,
          onPressed: () => Navigator.pop(context, 'discard'),
        ),
        AppDialogAction(
          session.routineChanged ? 'Save · keep routine' : 'Finish and save',
          onPressed: () => Navigator.pop(context, 'save'),
        ),
        if (session.routineChanged)
          AppDialogAction(
            'Save · update routine',
            onPressed: () => Navigator.pop(context, 'update'),
          ),
      ],
    );
    if (choice == null || !mounted) return;
    final save = choice != 'discard';
    setState(() => _finishing = true);
    try {
      if (choice == 'update') await session.updateRoutineFromSession();
      await session.finish(save: save);
      if (!save && mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        await showAppDialog<void>(
          context,
          title: 'Couldn’t save workout',
          message: error.toString().replaceFirst('Exception: ', ''),
          actions: [
            AppDialogAction('OK', onPressed: () => Navigator.pop(context)),
          ],
        );
      }
    } finally {
      if (mounted) setState(() => _finishing = false);
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
        child:
            session.isFinished
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
                          offset:
                              session.resting
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
    final progress =
        s.totalSets == 0 ? 0.0 : (s.doneSets / s.totalSets).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        color: c.card.withValues(alpha: c.usesLightForeground ? 0.42 : 0.58),
        border: Border(
          bottom: BorderSide(color: c.border, width: AppDesign.hairline),
        ),
      ),
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
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.25,
                    color: c.textPrimary,
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
                // Fills smoothly as sets are completed — a quiet, satisfying beat.
                AnimatedFractionallySizedBox(
                  widthFactor: progress,
                  duration: const Duration(milliseconds: 420),
                  curve: const Cubic(0.23, 1, 0.32, 1),
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
                ),
              ),
              const Spacer(),
              Text(
                '${s.doneSets}/${s.totalSets} sets',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: c.accent,
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 108),
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

  // Editing controls use a quiet glass surface, matching the reference UI.
  Widget _addRowButton(
    AppColors c,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(AppDesign.radiusControl),
          border: Border.all(color: c.border, width: AppDesign.hairline),
          boxShadow: c.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: c.textPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
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
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 12),
      decoration: BoxDecoration(
        color: c.card.withValues(alpha: c.usesLightForeground ? 0.46 : 0.62),
        border: Border(
          top: BorderSide(color: c.border, width: AppDesign.hairline),
        ),
      ),
      child: Pressable(
        onTap: _finishing ? null : () => _confirmFinish(s),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.invBg,
            borderRadius: BorderRadius.circular(AppDesign.radiusControl),
            boxShadow: c.cardShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                allDone
                    ? CupertinoIcons.checkmark_alt
                    : CupertinoIcons.flag_fill,
                size: 18,
                color: c.invText,
              ),
              const SizedBox(width: 8),
              Text(
                allDone ? 'Finish · all done' : 'Finish workout',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: c.invText,
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
    final pr =
        g.sets.isNotEmpty ? session.prFor(g.sets.first.exerciseId) : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppDesign.radiusCard),
        border: Border.all(color: c.border, width: AppDesign.hairline),
        boxShadow: c.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (g.trainingGroupId != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: c.accent,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(19),
                ),
              ),
              child: Text(
                g.trainingGroupType.toUpperCase(),
                style: TextStyle(
                  color: c.textOnAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: c.iconBg.withValues(
                alpha: c.usesLightForeground ? 0.52 : 0.62,
              ),
              borderRadius:
                  g.trainingGroupId == null
                      ? const BorderRadius.vertical(top: Radius.circular(19))
                      : BorderRadius.zero,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: ExerciseVisual(
                    name: g.name,
                    muscleGroup: g.muscleGroup,
                    category: '',
                    imageUrl: g.imageUrl,
                    imageUrl2: g.imageUrl2,
                    radius: 11,
                    figurePadding: 5,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Rest ${g.restSeconds}s'
                        '${pr != null ? '  ·  PR ${units.format(pr)}${units.label}' : ''}',
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: c.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
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
          if (g.note.isNotEmpty)
            Pressable(
              onTap: () => _editExerciseNote(session, g),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                color: c.iconBg.withValues(alpha: 0.6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      CupertinoIcons.pencil_outline,
                      size: 15,
                      color: c.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        g.note,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Container(height: 1, color: c.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 54, 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 73,
                        child: Text('SET', style: _columnLabelStyle(c)),
                      ),
                      if (_showPrimary(g.exerciseType)) ...[
                        Expanded(
                          child: Text(
                            _primaryLabel(g.exerciseType, units),
                            textAlign: TextAlign.center,
                            style: _columnLabelStyle(c),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          _secondaryLabel(g.exerciseType),
                          textAlign: TextAlign.center,
                          style: _columnLabelStyle(c),
                        ),
                      ),
                    ],
                  ),
                ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: const Cubic(0.23, 1, 0.32, 1),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: BoxDecoration(
          color: s.done ? c.accent.withValues(alpha: 0.10) : c.iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
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
                    ),
                  ),
                ),
                if (s.progression.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _progressionBadge(c, s.progression),
                ],
                const SizedBox(width: 8),
                if (_showPrimary(g.exerciseType)) ...[
                  Expanded(
                    child: _numField(
                      c,
                      _wc(s),
                      s.done,
                      _primaryUnit(g.exerciseType, units),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: _numField(
                    c,
                    _rc(s),
                    s.done,
                    _secondaryUnit(g.exerciseType),
                  ),
                ),
                const SizedBox(width: 10),
                Pressable(
                  onTap: () => session.toggleSet(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: const Cubic(0.23, 1, 0.32, 1),
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: s.done ? c.accent : c.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: s.done ? c.accent : c.border),
                    ),
                    child: AnimatedScale(
                      scale: s.done ? 1.0 : 0.82,
                      duration: const Duration(milliseconds: 200),
                      curve:
                          s.done
                              ? const Cubic(
                                0.34,
                                1.56,
                                0.64,
                                1,
                              ) // gentle overshoot pop
                              : const Cubic(0.23, 1, 0.32, 1),
                      child: Icon(
                        CupertinoIcons.check_mark,
                        size: 20,
                        color: s.done ? c.textOnAccent : c.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                if (s.previousReps != null)
                  Expanded(
                    child: Pressable(
                      onTap:
                          s.done
                              ? null
                              : () {
                                session.usePrevious(s);
                                _wc(s).text = s.weight;
                                _rc(s).text = s.reps;
                                HapticFeedback.selectionClick();
                              },
                      child: Text(
                        _previousLabel(g.exerciseType, units, s),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: c.accentSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  const Spacer(),
                Pressable(
                  onTap: s.done ? null : () => _pickEffort(session, s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: c.border),
                    ),
                    child: Text(
                      s.rpe != null
                          ? 'RPE ${s.rpe}'
                          : s.rir != null
                          ? 'RIR ${s.rir}'
                          : 'RPE / RIR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _columnLabelStyle(AppColors c) => TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.8,
    color: c.textSecondary,
  );

  bool _showPrimary(String type) =>
      type == 'weight_reps' ||
      type == 'bodyweight_reps' ||
      type == 'distance_duration';

  String _primaryLabel(String type, UnitsController units) => switch (type) {
    'bodyweight_reps' => 'ADDED ${units.label.toUpperCase()}',
    'distance_duration' => 'DISTANCE KM',
    'reps_only' => '',
    'duration' => '',
    _ => units.label.toUpperCase(),
  };

  String _secondaryLabel(String type) => switch (type) {
    'duration' || 'distance_duration' => 'SECONDS',
    _ => 'REPS',
  };

  String _primaryUnit(String type, UnitsController units) =>
      type == 'distance_duration' ? 'km' : units.label;

  String _secondaryUnit(String type) =>
      type == 'duration' || type == 'distance_duration' ? 'sec' : 'reps';

  String _previousLabel(String type, UnitsController units, SessionSet set) {
    final effort = set.previousRpe != null ? '  @ ${set.previousRpe} RPE' : '';
    return switch (type) {
      'reps_only' => 'Previous  ${set.previousReps} reps$effort',
      'duration' => 'Previous  ${set.previousReps} sec$effort',
      'distance_duration' =>
        'Previous  ${set.previousWeightKg ?? 0} km · ${set.previousReps} sec$effort',
      _ =>
        'Previous  ${units.format(set.previousWeightKg ?? 0)}${units.label} × ${set.previousReps}$effort',
    };
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
      case 'dropset':
        return (
          bg: const Color(0x332563EB),
          fg: const Color(0xFF2563EB),
          badge: 'D',
        );
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
    _showPickerSheet(
      title: 'Set type',
      rows: [
        for (final t in setTypes)
          _PickerRow(
            title: setTypeMetadata[t]!.name,
            subtitle: setTypeMetadata[t]!.description,
            badge: _typeVisual(context.colors, t).badge,
            badgeBg: _typeVisual(context.colors, t).bg,
            badgeFg: _typeVisual(context.colors, t).fg,
            selected: s.type == t,
            onTap: () => session.setSetType(s, t),
          ),
      ],
      footer: _PickerRow(
        title:
            s.progression.isEmpty
                ? 'Progression tag…'
                : 'Progression: ${_progressionNames[s.progression]}',
        icon: CupertinoIcons.arrow_up_right,
        onTap: () => _pickProgression(session, s),
        keepOpenAfterTap: true,
      ),
    );
  }

  // Tag how the set progressed (amplitude, efficiency, MEO/drop-set, …) beyond
  // just adding load — issue #4.
  void _pickProgression(WorkoutSessionController session, SessionSet s) {
    HapticFeedback.selectionClick();
    _showPickerSheet(
      title: 'How did this set progress?',
      rows: [
        for (final p in progressionTypes)
          _PickerRow(
            title: _progressionNames[p]!,
            badge: _progressionBadges[p],
            selected: s.progression == p,
            onTap: () => session.setProgression(s, p),
          ),
        _PickerRow(
          title: 'No progression tag',
          destructive: true,
          selected: s.progression.isEmpty,
          onTap: () => session.setProgression(s, ''),
        ),
      ],
    );
  }

  Future<void> _pickEffort(
    WorkoutSessionController session,
    SessionSet s,
  ) async {
    HapticFeedback.selectionClick();
    final mode = await showCupertinoModalPopup<String>(
      context: context,
      builder:
          (ctx) => CupertinoActionSheet(
            title: const Text('Effort'),
            message: const Text(
              'RPE measures effort from 6–10. RIR records estimated reps left.',
            ),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(ctx, 'rpe'),
                child: const Text('Log RPE'),
              ),
              CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(ctx, 'rir'),
                child: const Text('Log RIR'),
              ),
              if (s.rpe != null || s.rir != null)
                CupertinoActionSheetAction(
                  isDestructiveAction: true,
                  onPressed: () => Navigator.pop(ctx, 'clear'),
                  child: const Text('Clear effort'),
                ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ),
    );
    if (!mounted || mode == null) return;
    if (mode == 'clear') {
      session.setEffort(s);
      return;
    }
    if (mode == 'rpe') {
      final value = await showCupertinoModalPopup<double>(
        context: context,
        builder:
            (ctx) => CupertinoActionSheet(
              title: const Text('Rate of perceived exertion'),
              actions: [
                for (final value in const [6, 7, 8, 8.5, 9, 9.5, 10])
                  CupertinoActionSheetAction(
                    onPressed: () => Navigator.pop(ctx, value.toDouble()),
                    child: Text('$value RPE'),
                  ),
              ],
              cancelButton: CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ),
      );
      if (value != null) session.setEffort(s, rpe: value);
      return;
    }
    final value = await showCupertinoModalPopup<int>(
      context: context,
      builder:
          (ctx) => CupertinoActionSheet(
            title: const Text('Reps in reserve'),
            actions: [
              for (final value in const [0, 1, 2, 3, 4, 5])
                CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(ctx, value),
                  child: Text('$value RIR'),
                ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ),
    );
    if (value != null) session.setEffort(s, rir: value);
  }

  // A themed bottom-sheet picker (grab handle, app surface, tap-to-select rows)
  // used for set type and progression — stylistically part of the product
  // rather than the stock iOS action sheet.
  void _showPickerSheet({
    required String title,
    required List<_PickerRow> rows,
    _PickerRow? footer,
  }) {
    final c = context.colors;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        Widget row(_PickerRow r) => Pressable(
          onTap: () {
            r.onTap();
            if (!r.keepOpenAfterTap) Navigator.of(ctx).pop();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: c.iconBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: r.selected ? c.accent : c.border,
                width: r.selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                if (r.badge != null)
                  Container(
                    width: 40,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: r.badgeBg ?? c.card,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      r.badge!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: r.badgeFg ?? c.textSecondary,
                      ),
                    ),
                  )
                else if (r.icon != null)
                  Icon(r.icon, size: 20, color: c.textSecondary),
                if (r.badge != null || r.icon != null)
                  const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              r.selected ? FontWeight.w700 : FontWeight.w600,
                          color: r.destructive ? c.accent : c.textPrimary,
                        ),
                      ),
                      if (r.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          r.subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (r.selected)
                  Icon(CupertinoIcons.check_mark, size: 18, color: c.accent),
              ],
            ),
          ),
        );

        return Container(
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(top: BorderSide(color: c.border)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                ...rows.map(row),
                if (footer != null) ...[
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: c.border,
                  ),
                  row(footer),
                ],
              ],
            ),
          ),
        );
      },
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
    inputFormatters: [NumericLimitFormatter(allowDecimal: unit != 'reps')],
    textAlign: TextAlign.center,
    style: TextStyle(
      color: c.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w800,
    ),
    placeholderStyle: TextStyle(color: c.textSecondary, fontSize: 15),
    suffix: Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(unit, style: TextStyle(fontSize: 11, color: c.textSecondary)),
    ),
    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 7),
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
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$workoutName  ·  ${_diffLabels[difficulty] ?? difficulty}',
            style: TextStyle(fontSize: 13, color: c.textSecondary),
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
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.5,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}

// A single option in the themed picker sheet (set type / progression).
class _PickerRow {
  final String title;
  final String? subtitle;
  final String? badge;
  final Color? badgeBg;
  final Color? badgeFg;
  final IconData? icon;
  final bool selected;
  final bool destructive;
  final bool keepOpenAfterTap;
  final VoidCallback onTap;

  const _PickerRow({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.badge,
    this.badgeBg,
    this.badgeFg,
    this.icon,
    this.selected = false,
    this.destructive = false,
    this.keepOpenAfterTap = false,
  });
}
