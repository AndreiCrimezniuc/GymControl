import 'package:flutter/cupertino.dart';
import 'package:gymboss/data/repositories/exercises_repository.dart';
import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/units/units_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_dialog.dart';
import 'package:gymboss/ui/core/ui/widgets/app_page.dart';
import 'package:gymboss/ui/core/ui/widgets/pressable.dart';
import 'package:gymboss/ui/menu_options_list/exercises/widgets/exercise_mannequin.dart';
import 'package:gymboss/ui/menu_options_list/workouts/widgets/workout_editor.dart';
import 'package:gymboss/ui/menu_options_list/workouts/widgets/workout_runner.dart';

const _diffLabels = {'easy': 'Easy', 'medium': 'Medium', 'hard': 'Hard'};

class WorkoutDetailScreen extends StatefulWidget {
  final String id;
  final WorkoutsRepository repo;
  final ExercisesRepository exercises;
  const WorkoutDetailScreen({super.key, required this.id, required this.repo, required this.exercises});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  Workout? _w;
  WorkoutStats? _stats;
  bool _loading = true;
  String? _error;
  String _difficulty = 'medium';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final w = await widget.repo.get(widget.id);
      final s = await widget.repo.stats(widget.id);
      if (mounted) setState(() { _w = w; _stats = s; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _launch() async {
    await Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(
        builder: (_) => WorkoutRunnerScreen(
          workout: _w!,
          difficulty: _difficulty,
          repo: widget.repo,
          exercises: widget.exercises,
        ),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _saveCopy() async {
    try {
      await widget.repo.copy(_w!.id);
      if (!mounted) return;
      await showAppDialog<void>(
        context,
        title: 'Saved',
        message: 'A private copy was added to your workouts. Open “Mine” to launch or edit it.',
        actions: [AppDialogAction('OK', isDefault: true, onPressed: () => Navigator.pop(context))],
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      _toast('Could not save a copy');
    }
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context, rootNavigator: true).push<bool>(
      CupertinoPageRoute(builder: (_) => WorkoutEditorScreen(repo: widget.repo, exercises: widget.exercises, existing: _w)),
    );
    if (saved == true) _load();
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
        AppDialogAction('Cancel', onPressed: () => Navigator.pop(context, false)),
        AppDialogAction('Delete', isDestructive: true, onPressed: () => Navigator.pop(context, true)),
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
        AppSheetAction('Edit', onPressed: () { Navigator.pop(context); _edit(); }),
        AppSheetAction(w.isPublic ? 'Make private' : 'Publish to library',
            onPressed: () { Navigator.pop(context); _togglePublic(); }),
        AppSheetAction('Delete', isDestructive: true, onPressed: () { Navigator.pop(context); _delete(); }),
      ],
    );
  }

  void _toast(String msg) {
    showAppDialog<void>(
      context,
      title: msg,
      actions: [AppDialogAction('OK', isDefault: true, onPressed: () => Navigator.pop(context))],
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
            child: Icon(CupertinoIcons.ellipsis, size: 22, color: c.textPrimary),
          ),
      ],
      body: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : _error != null || w == null
              ? Center(child: Text('Could not load', style: TextStyle(color: c.textSecondary, fontFamily: 'Rubik')))
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
                  child: Text(w.comment, style: TextStyle(fontSize: 13, color: c.textSecondary, height: 1.5, fontFamily: 'Rubik')),
                ),
              _statsRow(c, w),
              const SizedBox(height: 16),
              _difficultyPicker(c),
              const SizedBox(height: 8),
              _potentialVolumeLine(c),
              const SizedBox(height: 16),
              ...w.exercises.asMap().entries.map((e) => _ExerciseBlock(index: e.key + 1, exercise: e.value, difficulty: _difficulty)),
              if (_stats != null && _stats!.history.isNotEmpty) ...[
                const SizedBox(height: 8),
                _SectionLabel('History'),
                const SizedBox(height: 8),
                ..._stats!.history.take(8).map((h) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Icon(CupertinoIcons.calendar, size: 13, color: c.textSecondary),
                        const SizedBox(width: 8),
                        Text(h.date, style: TextStyle(fontSize: 13, color: c.textPrimary, fontFamily: 'Rubik')),
                        const Spacer(),
                        Text(_diffLabels[h.difficulty] ?? h.difficulty,
                            style: TextStyle(fontSize: 12, color: c.textSecondary, fontFamily: 'Rubik')),
                      ]),
                    )),
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

  Widget _statsRow(AppColors c, Workout w) => Row(children: [
        _StatChip(icon: CupertinoIcons.heart_fill, label: 'Love', value: '${_stats?.loveScore ?? w.loveScore}/10'),
        const SizedBox(width: 10),
        _StatChip(icon: CupertinoIcons.flame, label: 'Done', value: '${_stats?.timesPerformed ?? w.timesPerformed}x'),
        const SizedBox(width: 10),
        _StatChip(icon: CupertinoIcons.square_stack_3d_up, label: 'Exercises', value: '${w.exerciseCount}'),
      ]);

  Widget _difficultyPicker(AppColors c) => CupertinoSlidingSegmentedControl<String>(
        groupValue: _difficulty,
        backgroundColor: c.iconBg,
        thumbColor: c.accent,
        onValueChanged: (v) => setState(() => _difficulty = v ?? 'medium'),
        children: {
          for (final d in workoutDifficulties)
            d: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Text(_diffLabels[d]!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _difficulty == d ? c.textOnAccent : c.textSecondary,
                    fontFamily: 'Rubik',
                  )),
            ),
        },
      );

  Widget _potentialVolumeLine(AppColors c) {
    final vol = _stats?.potentialVolume[_difficulty] ?? 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(CupertinoIcons.chart_bar_alt_fill, size: 14, color: c.textSecondary),
        const SizedBox(width: 6),
        Text('Potential volume: ${(vol / 1000).toStringAsFixed(1)} t',
            style: TextStyle(fontSize: 12, color: c.textSecondary, fontFamily: 'Rubik')),
      ],
    );
  }

  Widget _launchButton(AppColors c) => Pressable(
        onTap: _launch,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(14)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(CupertinoIcons.play_arrow_solid, size: 18, color: c.textOnAccent),
            const SizedBox(width: 8),
            Text('LAUNCH · ${_diffLabels[_difficulty]!.toUpperCase()}',
                style: TextStyle(fontFamily: 'Rubik', fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: c.textOnAccent)),
          ]),
        ),
      );

  Widget _saveCopyButton(AppColors c) => Pressable(
        onTap: _saveCopy,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(14)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(CupertinoIcons.plus_square_on_square, size: 18, color: c.textOnAccent),
            const SizedBox(width: 8),
            Text('SAVE A COPY',
                style: TextStyle(fontFamily: 'Rubik', fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: c.textOnAccent)),
          ]),
        ),
      );
}

class _ExerciseBlock extends StatelessWidget {
  final int index;
  final WorkoutExercise exercise;
  final String difficulty;
  const _ExerciseBlock({required this.index, required this.exercise, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final units = context.units;
    final sets = exercise.setsFor(difficulty);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            SizedBox(
              width: 44,
              height: 44,
              child: ExerciseMannequin(
                pattern: patternFor(name: exercise.name, muscle: exercise.muscleGroup, equipment: ''),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$index. ${exercise.name}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary, fontFamily: 'Rubik')),
                  const SizedBox(height: 2),
                  Text('Rest ${exercise.restSeconds}s',
                      style: TextStyle(fontSize: 11, color: c.textSecondary, fontFamily: 'Rubik')),
                ],
              ),
            ),
          ]),
          if (sets.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sets.asMap().entries.map((e) {
                final s = e.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: c.iconBg, borderRadius: BorderRadius.circular(8)),
                  child: Text('${units.format(s.weightKg)}${units.label} × ${s.reps}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textPrimary, fontFamily: 'Rubik')),
                );
              }).toList(),
            ),
          ],
          if (exercise.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(exercise.comment,
                style: TextStyle(fontSize: 12, color: c.textSecondary, fontStyle: FontStyle.italic, fontFamily: 'Rubik')),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border)),
        child: Column(children: [
          Icon(icon, size: 16, color: c.accent),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.textPrimary, fontFamily: 'Rubik')),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9, letterSpacing: 0.5, color: c.textSecondary, fontFamily: 'Rubik')),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Rubik', color: context.colors.textPrimary));
}
