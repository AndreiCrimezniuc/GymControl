import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gymboss/data/repositories/exercises_repository.dart';
import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/domain/models/exercises/exercise_catalog.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';
import 'package:gymboss/ui/menu_options_list/exercises/widgets/exercises.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/units/units_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_dialog.dart';
import 'package:gymboss/ui/core/ui/widgets/app_page.dart';
import 'package:gymboss/ui/core/ui/widgets/pressable.dart';
import 'package:gymboss/ui/menu_options_list/exercises/widgets/exercise_mannequin.dart';
import 'package:gymboss/ui/menu_options_list/exercises/widgets/muscle_illustration.dart';
import 'package:gymboss/ui/menu_options_list/workouts/widgets/workout_editor.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/workout_session_controller.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/aerobic_runner.dart';
import 'package:gymboss/ui/menu_options_list/workouts/widgets/workout_runner.dart';

const _modes = ['normal', 'deload'];
const _diffLabels = {'normal': 'Normal', 'deload': 'Deload'};

class WorkoutDetailScreen extends StatefulWidget {
  final String id;
  final WorkoutsRepository repo;
  final ExercisesRepository exercises;
  const WorkoutDetailScreen({
    super.key,
    required this.id,
    required this.repo,
    required this.exercises,
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  Workout? _w;
  WorkoutStats? _stats;
  bool _loading = true;
  String? _error;
  String _difficulty = 'normal'; // 'normal' | 'deload'

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final w = await widget.repo.get(widget.id);
      final s = await widget.repo.stats(widget.id);
      if (mounted) {
        setState(() {
          _w = w;
          _stats = s;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _launch() async {
    final session = context.read<WorkoutSessionController>();
    if (session.isActive && !session.isFinished) {
      final replace = await showAppDialog<bool>(
        context,
        title: 'Start a new workout?',
        message:
            'You have an active session in progress. Starting this one will discard it.',
        actions: [
          AppDialogAction(
            'Keep active',
            onPressed: () => Navigator.pop(context, false),
          ),
          AppDialogAction(
            'Start new',
            isDestructive: true,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      );
      if (!mounted || replace != true) return;
    }
    // Aerobic workouts use the stopwatch/laps runner instead of the set logger.
    if (_w!.type == 'aerobic') {
      await Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(
          builder: (_) => AerobicRunnerScreen(
            workoutId: _w!.id,
            workoutName: _w!.name,
            repo: widget.repo,
          ),
        ),
      );
      if (mounted) _load();
      return;
    }
    session.start(
      workout: _w!,
      difficulty: _difficulty,
      exercises: widget.exercises,
      workouts: widget.repo,
      units: context.read<UnitsController>(),
    );
    await Navigator.of(
      context,
      rootNavigator: true,
    ).push(CupertinoPageRoute(builder: (_) => const WorkoutRunnerScreen()));
    if (mounted) _load();
  }

  Future<void> _saveCopy() async {
    try {
      await widget.repo.copy(_w!.id);
      if (!mounted) return;
      await showAppDialog<void>(
        context,
        title: 'Saved',
        message:
            'A private copy was added to your workouts. Open “Mine” to launch or edit it.',
        actions: [
          AppDialogAction(
            'OK',
            isDefault: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      _toast('Could not save a copy');
    }
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context, rootNavigator: true).push<bool>(
      CupertinoPageRoute(
        builder: (_) => WorkoutEditorScreen(
          repo: widget.repo,
          exercises: widget.exercises,
          existing: _w,
        ),
      ),
    );
    if (saved == true) _load();
  }

  void _openRunDetail(String date, String difficulty) {
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(
        builder: (_) => _RunDetailScreen(
          workoutId: _w!.id,
          date: date,
          difficulty: difficulty,
          repo: widget.repo,
        ),
      ),
    );
  }

  void _openExerciseStats(WorkoutExercise ex) {
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(
        builder: (_) => ExerciseDetailScreen(
          entry: ExerciseCatalogItem(
            id: ex.exerciseId,
            name: ex.name,
            muscleGroup: ex.muscleGroup,
            equipment: '',
            category: '',
            level: '',
            force: '',
            imageUrl: ex.imageUrl,
            imageUrl2: '',
            instructions: '',
          ),
          repo: widget.exercises,
        ),
      ),
    );
  }

  Future<void> _togglePublic() async {
    final w = _w!;
    try {
      await widget.repo.setVisibility(w.id, w.isPublic ? 'private' : 'public');
      _load();
    } catch (_) {
      _toast('Could not change visibility');
    }
  }

  Future<void> _delete() async {
    final ok = await showAppDialog<bool>(
      context,
      title: 'Delete workout?',
      message: '“${_w!.name}” will be permanently removed.',
      actions: [
        AppDialogAction(
          'Cancel',
          onPressed: () => Navigator.pop(context, false),
        ),
        AppDialogAction(
          'Delete',
          isDestructive: true,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
    if (ok != true) return;
    try {
      await widget.repo.delete(_w!.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      _toast('Could not delete');
    }
  }

  void _menu() {
    final w = _w!;
    showAppActionSheet(
      context,
      actions: [
        AppSheetAction(
          'Edit',
          onPressed: () {
            Navigator.pop(context);
            _edit();
          },
        ),
        AppSheetAction(
          w.isPublic ? 'Make private' : 'Publish to library',
          onPressed: () {
            Navigator.pop(context);
            _togglePublic();
          },
        ),
        AppSheetAction(
          'Delete',
          isDestructive: true,
          onPressed: () {
            Navigator.pop(context);
            _delete();
          },
        ),
      ],
    );
  }

  void _toast(String msg) {
    showAppDialog<void>(
      context,
      title: msg,
      actions: [
        AppDialogAction(
          'OK',
          isDefault: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final w = _w;
    return AppPage(
      title: w?.name ?? 'Workout',
      actions: [
        if (w != null && w.owned)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _menu,
            child: Icon(
              CupertinoIcons.ellipsis,
              size: 22,
              color: c.textPrimary,
            ),
          ),
      ],
      body: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : _error != null || w == null
          ? Center(
              child: Text(
                'Could not load',
                style: TextStyle(color: c.textSecondary, fontFamily: 'Rubik'),
              ),
            )
          : _buildBody(c, w),
    );
  }

  Widget _buildBody(AppColors c, Workout w) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              if (w.comment.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    w.comment,
                    style: TextStyle(
                      fontSize: 13,
                      color: c.textSecondary,
                      height: 1.5,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ),
              _statsRow(c, w),
              const SizedBox(height: 16),
              // Normal/Deload + planned volume only apply to strength workouts.
              if (w.type != 'aerobic') ...[
                _difficultyPicker(c),
                const SizedBox(height: 8),
                _potentialVolumeLine(c),
                const SizedBox(height: 16),
              ],
              ...w.exercises.asMap().entries.map(
                (e) => _ExerciseBlock(
                  index: e.key + 1,
                  exercise: e.value,
                  deloadScale: _difficulty == 'deload'
                      ? (_w?.deloadFactor ?? 0.70)
                      : 1.0,
                  onTap: () => _openExerciseStats(e.value),
                ),
              ),
              if (_stats != null && _stats!.history.isNotEmpty) ...[
                const SizedBox(height: 8),
                _SectionLabel('History'),
                const SizedBox(height: 8),
                ..._stats!.history
                    .take(12)
                    .map(
                      (h) => Pressable(
                        onTap: () => _openRunDetail(h.date, h.difficulty),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: c.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: c.border),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.calendar,
                                size: 14,
                                color: c.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                h.date,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: c.textPrimary,
                                  fontFamily: 'Rubik',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _diffLabels[h.difficulty] ?? h.difficulty,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: c.textSecondary,
                                  fontFamily: 'Rubik',
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                CupertinoIcons.chevron_right,
                                size: 14,
                                color: c.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
          child: w.owned ? _launchButton(c) : _saveCopyButton(c),
        ),
      ],
    );
  }

  Widget _statsRow(AppColors c, Workout w) => Row(
    children: [
      _StatChip(
        icon: CupertinoIcons.heart_fill,
        label: 'Love',
        value: '${_stats?.loveScore ?? w.loveScore}/10',
      ),
      const SizedBox(width: 10),
      _StatChip(
        icon: CupertinoIcons.flame,
        label: 'Done',
        value: '${_stats?.timesPerformed ?? w.timesPerformed}x',
      ),
      const SizedBox(width: 10),
      _StatChip(
        icon: CupertinoIcons.square_stack_3d_up,
        label: 'Exercises',
        value: '${w.exerciseCount}',
      ),
    ],
  );

  Widget _difficultyPicker(AppColors c) =>
      CupertinoSlidingSegmentedControl<String>(
        groupValue: _difficulty,
        backgroundColor: c.iconBg,
        thumbColor: c.accent,
        onValueChanged: (v) {
          HapticFeedback.selectionClick();
          setState(() => _difficulty = v ?? 'normal');
        },
        children: {
          for (final d in _modes)
            d: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Text(
                _diffLabels[d]!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _difficulty == d ? c.textOnAccent : c.textSecondary,
                  fontFamily: 'Rubik',
                ),
              ),
            ),
        },
      );

  Widget _potentialVolumeLine(AppColors c) {
    // The stored plan lives under the legacy 'medium' key; Deload scales it.
    final base = _stats?.potentialVolume['medium'] ?? 0;
    final vol = _difficulty == 'deload'
        ? base * (_w?.deloadFactor ?? 0.70)
        : base;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          CupertinoIcons.chart_bar_alt_fill,
          size: 14,
          color: c.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          'Potential volume: ${context.units.formatVolume(vol)}',
          style: TextStyle(
            fontSize: 12,
            color: c.textSecondary,
            fontFamily: 'Rubik',
          ),
        ),
      ],
    );
  }

  Widget _launchButton(AppColors c) => Pressable(
    onTap: _launch,
    child: Container(
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.accent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.play_arrow_solid,
            size: 18,
            color: c.textOnAccent,
          ),
          const SizedBox(width: 8),
          Text(
            'LAUNCH · ${_diffLabels[_difficulty]!.toUpperCase()}',
            style: TextStyle(
              fontFamily: 'Rubik',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: c.textOnAccent,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _saveCopyButton(AppColors c) => Pressable(
    onTap: _saveCopy,
    child: Container(
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.accent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.plus_square_on_square,
            size: 18,
            color: c.textOnAccent,
          ),
          const SizedBox(width: 8),
          Text(
            'SAVE A COPY',
            style: TextStyle(
              fontFamily: 'Rubik',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: c.textOnAccent,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ExerciseBlock extends StatelessWidget {
  final int index;
  final WorkoutExercise exercise;
  final double deloadScale; // 1.0 = Normal, <1 = Deload preview
  final VoidCallback onTap;
  const _ExerciseBlock({
    required this.index,
    required this.exercise,
    required this.deloadScale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final units = context.units;
    final medium = exercise.setsFor('medium');
    final sets = medium.isNotEmpty ? medium : exercise.sets;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: ExerciseVisual(
                    name: exercise.name,
                    muscleGroup: exercise.muscleGroup,
                    category: '',
                    imageUrl: exercise.imageUrl,
                    imageUrl2: exercise.imageUrl2,
                    radius: 10,
                    figurePadding: 4,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$index. ${exercise.name}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                          fontFamily: 'Rubik',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rest ${exercise.restSeconds}s',
                        style: TextStyle(
                          fontSize: 11,
                          color: c.textSecondary,
                          fontFamily: 'Rubik',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (sets.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sets.asMap().entries.map((e) {
                  final s = e.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: c.iconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${units.format(s.weightKg * deloadScale)}${units.label} × ${s.reps}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                        fontFamily: 'Rubik',
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (exercise.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                exercise.comment,
                style: TextStyle(
                  fontSize: 12,
                  color: c.textSecondary,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Rubik',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: c.accent),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
                fontFamily: 'Rubik',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
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
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      fontFamily: 'Rubik',
      color: context.colors.textPrimary,
    ),
  );
}

const _runDiffLabels = {'easy': 'Easy', 'medium': 'Medium', 'hard': 'Hard'};

/// Shows what a past session actually was: the sets logged on that date for the
/// workout's exercises, grouped by exercise, with total working volume.
class _RunDetailScreen extends StatefulWidget {
  final String workoutId;
  final String date;
  final String difficulty;
  final WorkoutsRepository repo;
  const _RunDetailScreen({
    required this.workoutId,
    required this.date,
    required this.difficulty,
    required this.repo,
  });

  @override
  State<_RunDetailScreen> createState() => _RunDetailScreenState();
}

class _RunDetailScreenState extends State<_RunDetailScreen> {
  List<PerformedExerciseLog>? _items;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await widget.repo.runDetail(widget.workoutId, widget.date);
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final units = context.units;
    final items = _items ?? [];
    final totalVol = items.fold<double>(0, (a, e) => a + e.volumeKg);
    return AppPage(
      title: widget.date,
      body: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : items.isEmpty
          ? Center(
              child: Text(
                'No logged sets for this session',
                style: TextStyle(color: c.textSecondary, fontFamily: 'Rubik'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                Row(
                  children: [
                    _summaryTile(
                      c,
                      _runDiffLabels[widget.difficulty] ?? widget.difficulty,
                      'DIFFICULTY',
                    ),
                    const SizedBox(width: 10),
                    _summaryTile(c, units.formatVolume(totalVol), 'VOLUME'),
                  ],
                ),
                const SizedBox(height: 16),
                ...items.map((e) => _exerciseTile(c, units, e)),
              ],
            ),
    );
  }

  Widget _summaryTile(AppColors c, String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
              fontFamily: 'Rubik',
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: c.textSecondary,
              fontFamily: 'Rubik',
            ),
          ),
        ],
      ),
    ),
  );

  Widget _exerciseTile(AppColors c, dynamic units, PerformedExerciseLog e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: ExerciseMannequin(
                  pattern: patternFor(
                    name: e.name,
                    muscle: e.muscleGroup,
                    equipment: '',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                    fontFamily: 'Rubik',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: e.sets.map<Widget>((s) {
              final warm = s.setType == 'warmup';
              final fail = s.setType == 'failure';
              final prefix = warm ? 'W ' : (fail ? 'F ' : '');
              const progLabels = {
                'weight': 'WT',
                'amplitude': 'AMP',
                'efficiency': 'EFF',
                'meo': 'MEO',
                'dropset': 'DROP',
              };
              final progSuffix = progLabels[s.progression] != null
                  ? '  · ${progLabels[s.progression]}'
                  : '';
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: warm
                      ? c.iconBg
                      : (fail ? c.accent.withValues(alpha: 0.12) : c.iconBg),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$prefix${units.format(s.weightKg)}${units.label} × ${s.reps}$progSuffix',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: warm
                        ? c.textSecondary
                        : (fail ? c.accent : c.textPrimary),
                    fontFamily: 'Rubik',
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
