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
import 'package:gymboss/ui/menu_options_list/workouts/widgets/exercise_picker.dart';

class WorkoutEditorScreen extends StatefulWidget {
  final WorkoutsRepository repo;
  final ExercisesRepository exercises;
  final Workout? existing;
  const WorkoutEditorScreen({
    super.key,
    required this.repo,
    required this.exercises,
    this.existing,
  });

  @override
  State<WorkoutEditorScreen> createState() => _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends State<WorkoutEditorScreen> {
  late final UnitsController _units;
  final _nameCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  // Deload weight as a percentage of Normal (default 70%).
  final _deloadCtrl = TextEditingController(text: '70');
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
      _deloadCtrl.text = '${(w.deloadFactor * 100).round()}';
      for (final ex in w.exercises) {
        _exercises.add(_EditExercise.fromExercise(ex, _units));
      }
    }
  }

  double get _deloadFactor {
    final pct = double.tryParse(_deloadCtrl.text.trim()) ?? 70;
    final f = pct / 100.0;
    if (f <= 0 || f > 1) return 0.70;
    return f;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _commentCtrl.dispose();
    _deloadCtrl.dispose();
    for (final e in _exercises) {
      e.dispose();
    }
    super.dispose();
  }

  Future<void> _addExercise() async {
    final picked = await Navigator.of(context, rootNavigator: true)
        .push<ExerciseCatalogItem>(
          CupertinoPageRoute(
            builder: (_) => ExercisePicker(repo: widget.exercises),
          ),
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
    if (name.isEmpty) {
      setState(() => _error = 'Give the workout a name');
      return;
    }
    if (_exercises.isEmpty) {
      setState(() => _error = 'Add at least one exercise');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final exercises = _exercises.map((e) => e.toDomain(_units)).toList();
    try {
      if (widget.existing != null) {
        await widget.repo.update(
          widget.existing!.id,
          name: name,
          comment: _commentCtrl.text.trim(),
          exercises: exercises,
          deloadFactor: _deloadFactor,
        );
      } else {
        await widget.repo.create(
          name: name,
          comment: _commentCtrl.text.trim(),
          exercises: exercises,
          deloadFactor: _deloadFactor,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _saving = false;
        });
      }
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
                _field(
                  c,
                  _commentCtrl,
                  'COMMENT',
                  'Optional notes',
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: _field(c, _deloadCtrl, 'DELOAD %', '70')),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Deload (разгрузочная) runs at this % of the Normal '
                          'weight. Reps stay the same.',
                          style: TextStyle(
                            fontSize: 11,
                            color: c.textSecondary,
                            fontFamily: 'Rubik',
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'EXERCISES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: c.textSecondary,
                        fontFamily: 'Rubik',
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_exercises.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: c.textSecondary,
                        fontFamily: 'Rubik',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ..._exercises.asMap().entries.map(
                  (e) => _ExerciseEditor(
                    key: ValueKey(e.value),
                    index: e.key,
                    last: e.key == _exercises.length - 1,
                    model: e.value,
                    onRemove: () => setState(() => _exercises.removeAt(e.key)),
                    onUp: () => _move(e.key, -1),
                    onDown: () => _move(e.key, 1),
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _addExercise,
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: c.accent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.add, size: 18, color: c.accent),
                        const SizedBox(width: 6),
                        Text(
                          'Add exercise',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: c.accent,
                            fontFamily: 'Rubik',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFEF4444),
                      fontFamily: 'Rubik',
                    ),
                  ),
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
                decoration: BoxDecoration(
                  color: _saving ? c.iconBg : c.accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _saving
                    ? const CupertinoActivityIndicator()
                    : Text(
                        widget.existing != null
                            ? 'SAVE CHANGES'
                            : 'CREATE WORKOUT',
                        style: TextStyle(
                          fontFamily: 'Rubik',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
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

  Widget _field(
    AppColors c,
    TextEditingController ctrl,
    String label,
    String placeholder, {
    int maxLines = 1,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: c.textSecondary,
          fontFamily: 'Rubik',
        ),
      ),
      const SizedBox(height: 6),
      CupertinoTextField(
        controller: ctrl,
        placeholder: placeholder,
        maxLines: maxLines,
        style: TextStyle(
          color: c.textPrimary,
          fontSize: 15,
          fontFamily: 'Rubik',
        ),
        placeholderStyle: TextStyle(color: c.textSecondary, fontSize: 15),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.iconBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border),
        ),
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
              Expanded(
                child: Text(
                  '${index + 1}. ${model.name}',
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
              _iconBtn(c, CupertinoIcons.chevron_up, index == 0 ? null : onUp),
              _iconBtn(c, CupertinoIcons.chevron_down, last ? null : onDown),
              _iconBtn(c, CupertinoIcons.delete, onRemove, danger: true),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniField(label: 'Sets', controller: model.setsCtrl, width: 60),
              const SizedBox(width: 10),
              _MiniField(
                label: 'Rest (s)',
                controller: model.restCtrl,
                width: 78,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Single "Normal" plan; the Deload variant scales this by the
          // workout's deload factor at run time.
          Row(
            children: [
              Expanded(
                child: _MiniField(
                  label: unit,
                  controller: model.weightCtrl,
                  dense: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniField(
                  label: 'reps',
                  controller: model.repsCtrl,
                  dense: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          CupertinoTextField(
            controller: model.commentCtrl,
            placeholder: 'Note for this exercise (optional)',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 13,
              fontFamily: 'Rubik',
            ),
            placeholderStyle: TextStyle(color: c.textSecondary, fontSize: 13),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: c.iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(
    AppColors c,
    IconData icon,
    VoidCallback? onTap, {
    bool danger = false,
  }) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Icon(
        icon,
        size: 18,
        color: onTap == null ? c.border : (danger ? c.accent : c.textSecondary),
      ),
    ),
  );
}

class _MiniField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final double? width;
  final bool dense;
  const _MiniField({
    required this.label,
    required this.controller,
    this.width,
    this.dense = false,
  });

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
      decoration: BoxDecoration(
        color: c.iconBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
    );
    if (width != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: c.textSecondary,
              fontFamily: 'Rubik',
            ),
          ),
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
  // One Normal plan per exercise; the Deload variant is derived at run time.
  final weightCtrl = TextEditingController();
  final repsCtrl = TextEditingController();

  _EditExercise({
    required this.exerciseId,
    required this.name,
    required this.imageUrl,
    required this.muscleGroup,
  });

  factory _EditExercise.blank(ExerciseCatalogItem item) => _EditExercise(
    exerciseId: item.id,
    name: item.name,
    imageUrl: item.imageUrl,
    muscleGroup: item.muscleGroup,
  );

  factory _EditExercise.fromExercise(
    WorkoutExercise ex,
    UnitsController units,
  ) {
    final m = _EditExercise(
      exerciseId: ex.exerciseId,
      name: ex.name,
      imageUrl: ex.imageUrl,
      muscleGroup: ex.muscleGroup,
    );
    m.restCtrl.text = '${ex.restSeconds}';
    m.commentCtrl.text = ex.comment;
    // The Normal plan is stored under the legacy 'medium' grade.
    final sets = ex.setsFor('medium');
    final plan = sets.isNotEmpty ? sets : ex.sets;
    if (plan.isNotEmpty) {
      final w = units.fromKg(plan.first.weightKg);
      m.weightCtrl.text = w == 0 ? '' : w.toStringAsFixed(w % 1 == 0 ? 0 : 1);
      m.repsCtrl.text = plan.first.reps == 0 ? '' : '${plan.first.reps}';
    }
    m.setsCtrl.text = '${plan.isEmpty ? 3 : plan.length}';
    return m;
  }

  WorkoutExercise toDomain(UnitsController units) {
    final count = int.tryParse(setsCtrl.text.trim()) ?? 1;
    final rest = int.tryParse(restCtrl.text.trim()) ?? 90;
    final n = count < 1 ? 1 : count;
    final w = units.toKg(double.tryParse(weightCtrl.text.trim()) ?? 0);
    final r = int.tryParse(repsCtrl.text.trim()) ?? 0;
    final sets = <WorkoutSet>[
      for (var i = 0; i < n; i++)
        WorkoutSet(difficulty: 'medium', weightKg: w, reps: r),
    ];
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
    weightCtrl.dispose();
    repsCtrl.dispose();
  }
}
