import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:gymboss/data/repositories/exercises_repository.dart';
import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/domain/models/exercises/exercise_catalog.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/units/units_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_page.dart';
import 'package:gymboss/ui/menu_options_list/exercises/widgets/muscle_illustration.dart';

const _diffs = ['easy', 'medium', 'hard'];
const _diffLabels = {'easy': 'Easy', 'medium': 'Medium', 'hard': 'Hard'};

class WorkoutEditorScreen extends StatefulWidget {
  final WorkoutsRepository repo;
  final ExercisesRepository exercises;
  final Workout? existing;
  const WorkoutEditorScreen({super.key, required this.repo, required this.exercises, this.existing});

  @override
  State<WorkoutEditorScreen> createState() => _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends State<WorkoutEditorScreen> {
  late final UnitsController _units;
  final _nameCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  final List<_EditExercise> _exercises = [];
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _units = context.read<UnitsController>();
    final w = widget.existing;
    if (w != null) {
      _nameCtrl.text = w.name;
      _commentCtrl.text = w.comment;
      for (final ex in w.exercises) {
        _exercises.add(_EditExercise.fromExercise(ex, _units));
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _commentCtrl.dispose();
    for (final e in _exercises) {
      e.dispose();
    }
    super.dispose();
  }

  Future<void> _addExercise() async {
    final picked = await Navigator.of(context, rootNavigator: true).push<ExerciseCatalogItem>(
      CupertinoPageRoute(builder: (_) => _ExercisePicker(repo: widget.exercises)),
    );
    if (picked != null) {
      setState(() => _exercises.add(_EditExercise.blank(picked)));
    }
  }

  void _move(int i, int delta) {
    final j = i + delta;
    if (j < 0 || j >= _exercises.length) return;
    setState(() {
      final e = _exercises.removeAt(i);
      _exercises.insert(j, e);
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { setState(() => _error = 'Give the workout a name'); return; }
    if (_exercises.isEmpty) { setState(() => _error = 'Add at least one exercise'); return; }

    setState(() { _saving = true; _error = null; });
    final exercises = _exercises.map((e) => e.toDomain(_units)).toList();
    try {
      if (widget.existing != null) {
        await widget.repo.update(widget.existing!.id, name: name, comment: _commentCtrl.text.trim(), exercises: exercises);
      } else {
        await widget.repo.create(name: name, comment: _commentCtrl.text.trim(), exercises: exercises);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPage(
      title: widget.existing != null ? 'Edit workout' : 'New workout',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                _field(c, _nameCtrl, 'NAME', 'Push Day'),
                const SizedBox(height: 12),
                _field(c, _commentCtrl, 'COMMENT', 'Optional notes', maxLines: 2),
                const SizedBox(height: 20),
                Row(children: [
                  Text('EXERCISES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: c.textSecondary, fontFamily: 'Rubik')),
                  const Spacer(),
                  Text('${_exercises.length}', style: TextStyle(fontSize: 12, color: c.textSecondary, fontFamily: 'Rubik')),
                ]),
                const SizedBox(height: 10),
                ..._exercises.asMap().entries.map((e) => _ExerciseEditor(
                      key: ValueKey(e.value),
                      index: e.key,
                      last: e.key == _exercises.length - 1,
                      model: e.value,
                      onRemove: () => setState(() => _exercises.removeAt(e.key)),
                      onUp: () => _move(e.key, -1),
                      onDown: () => _move(e.key, 1),
                    )),
                const SizedBox(height: 6),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _addExercise,
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.accent.withValues(alpha: 0.5)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(CupertinoIcons.add, size: 18, color: c.accent),
                      const SizedBox(width: 6),
                      Text('Add exercise', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.accent, fontFamily: 'Rubik')),
                    ]),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontFamily: 'Rubik')),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _saving ? null : _save,
              child: Container(
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: _saving ? c.iconBg : c.accent, borderRadius: BorderRadius.circular(14)),
                child: _saving
                    ? const CupertinoActivityIndicator()
                    : Text(widget.existing != null ? 'SAVE CHANGES' : 'CREATE WORKOUT',
                        style: TextStyle(fontFamily: 'Rubik', fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: c.textOnAccent)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(AppColors c, TextEditingController ctrl, String label, String placeholder, {int maxLines = 1}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.textSecondary, fontFamily: 'Rubik')),
          const SizedBox(height: 6),
          CupertinoTextField(
            controller: ctrl,
            placeholder: placeholder,
            maxLines: maxLines,
            style: TextStyle(color: c.textPrimary, fontSize: 15, fontFamily: 'Rubik'),
            placeholderStyle: TextStyle(color: c.textSecondary, fontSize: 15),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: c.iconBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.border)),
          ),
        ],
      );
}

// ── Per-exercise editor ─────────────────────────────────────────────────────

class _ExerciseEditor extends StatelessWidget {
  final int index;
  final bool last;
  final _EditExercise model;
  final VoidCallback onRemove;
  final VoidCallback onUp;
  final VoidCallback onDown;
  const _ExerciseEditor({
    super.key,
    required this.index,
    required this.last,
    required this.model,
    required this.onRemove,
    required this.onUp,
    required this.onDown,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final unit = context.units.label;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('${index + 1}. ${model.name}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary, fontFamily: 'Rubik')),
            ),
            _iconBtn(c, CupertinoIcons.chevron_up, index == 0 ? null : onUp),
            _iconBtn(c, CupertinoIcons.chevron_down, last ? null : onDown),
            _iconBtn(c, CupertinoIcons.delete, onRemove, danger: true),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _MiniField(label: 'Sets', controller: model.setsCtrl, width: 60),
            const SizedBox(width: 10),
            _MiniField(label: 'Rest (s)', controller: model.restCtrl, width: 78),
          ]),
          const SizedBox(height: 10),
          // per-difficulty weight × reps
          ..._diffs.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  SizedBox(
                    width: 64,
                    child: Text(_diffLabels[d]!,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textSecondary, fontFamily: 'Rubik')),
                  ),
                  Expanded(child: _MiniField(label: unit, controller: model.weight[d]!, dense: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _MiniField(label: 'reps', controller: model.reps[d]!, dense: true)),
                ]),
              )),
          const SizedBox(height: 4),
          CupertinoTextField(
            controller: model.commentCtrl,
            placeholder: 'Note for this exercise (optional)',
            style: TextStyle(color: c.textPrimary, fontSize: 13, fontFamily: 'Rubik'),
            placeholderStyle: TextStyle(color: c.textSecondary, fontSize: 13),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: c.iconBg, borderRadius: BorderRadius.circular(8)),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(AppColors c, IconData icon, VoidCallback? onTap, {bool danger = false}) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Icon(icon, size: 18, color: onTap == null ? c.border : (danger ? c.accent : c.textSecondary)),
        ),
      );
}

class _MiniField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final double? width;
  final bool dense;
  const _MiniField({required this.label, required this.controller, this.width, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final field = CupertinoTextField(
      controller: controller,
      placeholder: label,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: TextStyle(color: c.textPrimary, fontSize: 14, fontFamily: 'Rubik'),
      placeholderStyle: TextStyle(color: c.textSecondary, fontSize: 13),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: dense ? 8 : 10),
      decoration: BoxDecoration(color: c.iconBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border)),
    );
    if (width != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: c.textSecondary, fontFamily: 'Rubik')),
          const SizedBox(height: 4),
          SizedBox(width: width, child: field),
        ],
      );
    }
    return field;
  }
}

// ── Editor model ────────────────────────────────────────────────────────────

class _EditExercise {
  final int exerciseId;
  final String name;
  final String imageUrl;
  final String muscleGroup;
  final setsCtrl = TextEditingController(text: '3');
  final restCtrl = TextEditingController(text: '90');
  final commentCtrl = TextEditingController();
  final Map<String, TextEditingController> weight = {for (final d in _diffs) d: TextEditingController()};
  final Map<String, TextEditingController> reps = {for (final d in _diffs) d: TextEditingController()};

  _EditExercise({required this.exerciseId, required this.name, required this.imageUrl, required this.muscleGroup});

  factory _EditExercise.blank(ExerciseCatalogItem item) => _EditExercise(
        exerciseId: item.id,
        name: item.name,
        imageUrl: item.imageUrl,
        muscleGroup: item.muscleGroup,
      );

  factory _EditExercise.fromExercise(WorkoutExercise ex, UnitsController units) {
    final m = _EditExercise(
      exerciseId: ex.exerciseId,
      name: ex.name,
      imageUrl: ex.imageUrl,
      muscleGroup: ex.muscleGroup,
    );
    m.restCtrl.text = '${ex.restSeconds}';
    m.commentCtrl.text = ex.comment;
    var maxCount = 0;
    for (final d in _diffs) {
      final sets = ex.setsFor(d);
      if (sets.length > maxCount) maxCount = sets.length;
      if (sets.isNotEmpty) {
        final w = units.fromKg(sets.first.weightKg);
        m.weight[d]!.text = w == 0 ? '' : w.toStringAsFixed(w % 1 == 0 ? 0 : 1);
        m.reps[d]!.text = sets.first.reps == 0 ? '' : '${sets.first.reps}';
      }
    }
    m.setsCtrl.text = '${maxCount == 0 ? 3 : maxCount}';
    return m;
  }

  WorkoutExercise toDomain(UnitsController units) {
    final count = int.tryParse(setsCtrl.text.trim()) ?? 1;
    final rest = int.tryParse(restCtrl.text.trim()) ?? 90;
    final n = count < 1 ? 1 : count;
    final sets = <WorkoutSet>[];
    for (final d in _diffs) {
      final w = units.toKg(double.tryParse(weight[d]!.text.trim()) ?? 0);
      final r = int.tryParse(reps[d]!.text.trim()) ?? 0;
      for (var i = 0; i < n; i++) {
        sets.add(WorkoutSet(difficulty: d, weightKg: w, reps: r));
      }
    }
    return WorkoutExercise(
      exerciseId: exerciseId,
      name: name,
      imageUrl: imageUrl,
      muscleGroup: muscleGroup,
      restSeconds: rest,
      comment: commentCtrl.text.trim(),
      sets: sets,
    );
  }

  void dispose() {
    setsCtrl.dispose();
    restCtrl.dispose();
    commentCtrl.dispose();
    for (final c in weight.values) {
      c.dispose();
    }
    for (final c in reps.values) {
      c.dispose();
    }
  }
}

// ── Exercise picker ─────────────────────────────────────────────────────────

class _ExercisePicker extends StatefulWidget {
  final ExercisesRepository repo;
  const _ExercisePicker({required this.repo});

  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
  bool _loading = true;
  List<ExerciseCatalogItem> _all = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await widget.repo.getCatalog();
      if (mounted) setState(() { _all = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final filtered = _query.isEmpty
        ? _all
        : _all.where((e) => e.name.toLowerCase().contains(_query.toLowerCase())).toList();
    return AppPage(
      title: 'Pick exercise',
      body: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                  child: CupertinoSearchTextField(
                    placeholder: 'Search ${_all.length} exercises',
                    backgroundColor: c.card,
                    style: TextStyle(color: c.textPrimary, fontFamily: 'Rubik'),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final e = filtered[i];
                      return GestureDetector(
                        onTap: () => Navigator.of(context).pop(e),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border)),
                          child: Row(children: [
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: ExerciseVisual(
                                name: e.name,
                                muscleGroup: e.muscleGroup,
                                equipment: e.equipment,
                                category: e.category,
                                imageUrl: e.imageUrl,
                                radius: 10,
                                figurePadding: 5,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.name,
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary, fontFamily: 'Rubik')),
                                  Text(e.muscleGroup, style: TextStyle(fontSize: 12, color: c.textSecondary, fontFamily: 'Rubik')),
                                ],
                              ),
                            ),
                            Icon(CupertinoIcons.add_circled, size: 20, color: c.accent),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
