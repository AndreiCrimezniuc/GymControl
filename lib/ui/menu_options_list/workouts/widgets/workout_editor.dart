import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gymboss/data/repositories/exercises_repository.dart';
import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/domain/models/exercises/exercise_catalog.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/input/numeric_limit_formatter.dart';
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
  String _type = 'gym'; // gym | aerobic
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
      _type = w.type;
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
    final picked = await Navigator.of(
      context,
      rootNavigator: true,
    ).push<ExerciseCatalogItem>(
      CupertinoPageRoute(
        builder:
            (_) => ExercisePicker(
              repo: widget.exercises,
              excludedIds:
                  _exercises.map((exercise) => exercise.exerciseId).toSet(),
            ),
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
    if (_type != 'aerobic' && _exercises.isEmpty) {
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
          type: _type,
        );
      } else {
        await widget.repo.create(
          name: name,
          comment: _commentCtrl.text.trim(),
          exercises: exercises,
          deloadFactor: _deloadFactor,
          type: _type,
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
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return AppPage(
      title: widget.existing != null ? 'Edit workout' : 'New workout',
      body: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    if (widget.existing == null)
                      CupertinoSlidingSegmentedControl<String>(
                        groupValue: _type,
                        backgroundColor: c.iconBg,
                        thumbColor: c.accent,
                        onValueChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _type = v ?? 'gym';
                            if (_type == 'aerobic') {
                              for (final exercise in _exercises) {
                                exercise.dispose();
                              }
                              _exercises.clear();
                            }
                          });
                        },
                        children: {
                          for (final t in const ['gym', 'aerobic'])
                            t: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              child: Text(
                                t == 'gym' ? 'Gym' : 'Aerobic',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      _type == t
                                          ? c.textOnAccent
                                          : c.textSecondary,
                                ),
                              ),
                            ),
                        },
                      ),
                    if (widget.existing == null) const SizedBox(height: 14),
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
                    if (_type != 'aerobic') ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _field(c, _deloadCtrl, 'DELOAD %', '70'),
                          ),
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
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        'Aerobic workouts are timed: a stopwatch with laps. '
                        'Exercises below are optional.',
                        style: TextStyle(
                          fontSize: 12,
                          color: c.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
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
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_exercises.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: c.textSecondary,
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
                        onRemove:
                            () => setState(() => _exercises.removeAt(e.key)),
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
                    child:
                        _saving
                            ? const CupertinoActivityIndicator()
                            : Text(
                              widget.existing != null
                                  ? 'SAVE CHANGES'
                                  : 'CREATE WORKOUT',
                              style: TextStyle(
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
        ),
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
        ),
      ),
      const SizedBox(height: 6),
      CupertinoTextField(
        controller: ctrl,
        placeholder: placeholder,
        maxLines: maxLines,
        scrollPadding: const EdgeInsets.only(bottom: 140),
        style: TextStyle(color: c.textPrimary, fontSize: 15),
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

class _ExerciseEditor extends StatefulWidget {
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
  State<_ExerciseEditor> createState() => _ExerciseEditorState();
}

class _ExerciseEditorState extends State<_ExerciseEditor> {
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
                  '${widget.index + 1}. ${widget.model.name}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
              ),
              _iconBtn(
                c,
                CupertinoIcons.chevron_up,
                widget.index == 0 ? null : widget.onUp,
              ),
              _iconBtn(
                c,
                CupertinoIcons.chevron_down,
                widget.last ? null : widget.onDown,
              ),
              _iconBtn(c, CupertinoIcons.delete, widget.onRemove, danger: true),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniField(
                label: 'Rest (s)',
                controller: widget.model.restCtrl,
                width: 78,
              ),
              const Spacer(),
              Text(
                '${widget.model.sets.length} sets',
                style: TextStyle(fontSize: 12, color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 34,
                child: Text(
                  '#',
                  style: TextStyle(fontSize: 10, color: c.textSecondary),
                ),
              ),
              Expanded(child: _setHeader(c, unit.toUpperCase())),
              const SizedBox(width: 8),
              Expanded(child: _setHeader(c, 'REPS')),
              const SizedBox(width: 8),
              SizedBox(width: 82, child: _setHeader(c, 'TYPE')),
              const SizedBox(width: 28),
            ],
          ),
          const SizedBox(height: 6),
          ...widget.model.sets.asMap().entries.map((entry) {
            final set = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    child: Text(
                      '${entry.key + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _MiniField(
                      label: unit,
                      controller: set.weightCtrl,
                      dense: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniField(
                      label: 'reps',
                      controller: set.repsCtrl,
                      dense: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 82,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size.square(34),
                      onPressed: () => setState(() => set.cycleType()),
                      child: Container(
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.iconBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: c.border),
                        ),
                        child: Text(
                          set.shortType,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color:
                                set.type == 'working'
                                    ? c.textPrimary
                                    : c.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 28,
                    child:
                        widget.model.sets.length == 1
                            ? const SizedBox.shrink()
                            : GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap:
                                  () => setState(() {
                                    widget.model.removeSet(entry.key);
                                  }),
                              child: Icon(
                                CupertinoIcons.minus_circle,
                                size: 18,
                                color: c.textSecondary,
                              ),
                            ),
                  ),
                ],
              ),
            );
          }),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(widget.model.addSet),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.add_circled, size: 17, color: c.accent),
                  const SizedBox(width: 6),
                  Text(
                    'Add set',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          CupertinoTextField(
            controller: widget.model.commentCtrl,
            placeholder: 'Note for this exercise (optional)',
            scrollPadding: const EdgeInsets.only(bottom: 140),
            style: TextStyle(color: c.textPrimary, fontSize: 13),
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

  Widget _setHeader(AppColors colors, String label) => Text(
    label,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      color: colors.textSecondary,
    ),
  );

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
      scrollPadding: const EdgeInsets.only(bottom: 140),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        NumericLimitFormatter(allowDecimal: label != 'Sets' && label != 'reps'),
      ],
      textAlign: TextAlign.center,
      style: TextStyle(color: c.textPrimary, fontSize: 14),
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
          Text(label, style: TextStyle(fontSize: 10, color: c.textSecondary)),
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
  final restCtrl = TextEditingController(text: '90');
  final commentCtrl = TextEditingController();
  final List<_PlannedSetDraft> sets;

  _EditExercise({
    required this.exerciseId,
    required this.name,
    required this.imageUrl,
    required this.muscleGroup,
    List<_PlannedSetDraft>? sets,
  }) : sets = sets ?? List.generate(3, (_) => _PlannedSetDraft());

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
    for (final set in m.sets) {
      set.dispose();
    }
    m.sets
      ..clear()
      ..addAll(
        (plan.isEmpty
                ? const [WorkoutSet(difficulty: 'medium', weightKg: 0, reps: 0)]
                : plan)
            .map((set) => _PlannedSetDraft.fromSet(set, units)),
      );
    return m;
  }

  WorkoutExercise toDomain(UnitsController units) {
    final rest = clampWorkoutInteger(restCtrl.text);
    return WorkoutExercise(
      exerciseId: exerciseId,
      name: name,
      imageUrl: imageUrl,
      muscleGroup: muscleGroup,
      restSeconds: rest,
      comment: commentCtrl.text.trim(),
      sets: sets.map((set) => set.toDomain(units)).toList(),
    );
  }

  void addSet() {
    final previous = sets.isEmpty ? null : sets.last;
    sets.add(_PlannedSetDraft.copy(previous));
  }

  void removeSet(int index) {
    final removed = sets.removeAt(index);
    removed.dispose();
  }

  void dispose() {
    restCtrl.dispose();
    commentCtrl.dispose();
    for (final set in sets) {
      set.dispose();
    }
  }
}

class _PlannedSetDraft {
  static const _types = ['warmup', 'working', 'failure', 'dropset'];
  final TextEditingController weightCtrl;
  final TextEditingController repsCtrl;
  String type;

  _PlannedSetDraft({
    String weight = '',
    String reps = '',
    this.type = 'working',
  }) : weightCtrl = TextEditingController(text: weight),
       repsCtrl = TextEditingController(text: reps);

  factory _PlannedSetDraft.fromSet(WorkoutSet set, UnitsController units) {
    final weight = units.fromKg(set.weightKg);
    return _PlannedSetDraft(
      weight:
          weight == 0 ? '' : weight.toStringAsFixed(weight % 1 == 0 ? 0 : 1),
      reps: set.reps == 0 ? '' : '${set.reps}',
      type: set.setType,
    );
  }

  factory _PlannedSetDraft.copy(_PlannedSetDraft? other) => _PlannedSetDraft(
    weight: other?.weightCtrl.text ?? '',
    reps: other?.repsCtrl.text ?? '',
    type: other?.type ?? 'working',
  );

  String get shortType => switch (type) {
    'warmup' => 'WARM',
    'failure' => 'FAIL',
    'dropset' => 'DROP',
    _ => 'WORK',
  };

  void cycleType() {
    type = _types[(_types.indexOf(type) + 1) % _types.length];
  }

  WorkoutSet toDomain(UnitsController units) => WorkoutSet(
    difficulty: 'medium',
    weightKg: units.toKg(clampWorkoutDecimal(weightCtrl.text)),
    reps: clampWorkoutInteger(repsCtrl.text),
    setType: type,
  );

  void dispose() {
    weightCtrl.dispose();
    repsCtrl.dispose();
  }
}
