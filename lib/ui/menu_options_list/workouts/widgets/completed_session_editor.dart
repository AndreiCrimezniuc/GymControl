import 'package:flutter/cupertino.dart';

import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_dialog.dart';
import 'package:gymboss/ui/core/ui/widgets/app_page.dart';

class CompletedSessionEditor extends StatefulWidget {
  final String workoutId;
  final String sessionId;
  final String date;
  final String difficulty;
  final List<PerformedExerciseLog> exercises;
  final WorkoutsRepository repository;

  const CompletedSessionEditor({
    super.key,
    required this.workoutId,
    required this.sessionId,
    required this.date,
    required this.difficulty,
    required this.exercises,
    required this.repository,
  });

  @override
  State<CompletedSessionEditor> createState() => _CompletedSessionEditorState();
}

class _CompletedSessionEditorState extends State<CompletedSessionEditor> {
  late final List<_ExerciseDraft> _drafts;
  bool _saving = false;
  bool get _ru => Localizations.localeOf(context).languageCode == 'ru';

  @override
  void initState() {
    super.initState();
    _drafts = widget.exercises.map(_ExerciseDraft.fromLog).toList();
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final exercises = <PerformedExerciseLog>[];
    for (final draft in _drafts) {
      final sets = <PerformedSetLog>[];
      for (final set in draft.sets) {
        final weight = double.tryParse(set.weight.text.replaceAll(',', '.'));
        final reps = int.tryParse(set.reps.text);
        if (weight == null ||
            weight < 0 ||
            weight > 2000 ||
            reps == null ||
            reps < 1 ||
            reps > 1000) {
          await _showError(
            _ru ? 'Проверьте вес и повторения.' : 'Check weight and reps.',
          );
          return;
        }
        sets.add(
          PerformedSetLog(
            weightKg: weight,
            reps: reps,
            setType: set.type,
            progression: set.progression,
            rpe: set.rpe,
          ),
        );
      }
      if (sets.isEmpty) {
        await _showError(
          _ru
              ? 'У каждого упражнения должен остаться хотя бы один подход.'
              : 'Every exercise must keep at least one set.',
        );
        return;
      }
      exercises.add(
        PerformedExerciseLog(
          exerciseId: draft.exerciseId,
          name: draft.name,
          muscleGroup: draft.muscleGroup,
          sets: sets,
        ),
      );
    }
    final confirmed = await showAppDialog<bool>(
      context,
      title: _ru ? 'Сохранить исправления?' : 'Save corrections?',
      message: _ru
          ? 'GymControl сохранит предыдущую версию на сервере. Статистика и серия будут пересчитаны.'
          : 'GymControl keeps the previous version on the server. Statistics and streak data will be recalculated.',
      actions: [
        AppDialogAction(
          _ru ? 'Отмена' : 'Cancel',
          onPressed: () => Navigator.pop(context, false),
        ),
        AppDialogAction(
          _ru ? 'Сохранить' : 'Save',
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await widget.repository.replaceCompletedSession(
        workoutId: widget.workoutId,
        sessionId: widget.sessionId,
        performedAt: widget.date,
        difficulty: widget.difficulty,
        exercises: exercises,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) await _showError(error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showError(String message) => showAppDialog<void>(
    context,
    title: _ru ? 'Не удалось сохранить' : 'Could not save',
    message: message,
    actions: [AppDialogAction('OK', onPressed: () => Navigator.pop(context))],
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPage(
      title: _ru ? 'Исправить тренировку' : 'Correct workout',
      actions: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saving ? null : _save,
          child: _saving
              ? const CupertinoActivityIndicator()
              : Text(_ru ? 'Готово' : 'Done'),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Text(
            _ru
                ? 'Исправляйте только ошибки записи. Предыдущая версия не теряется.'
                : 'Use this for logging mistakes. The previous version is never discarded.',
            style: TextStyle(color: c.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          for (final exercise in _drafts) _exerciseCard(exercise),
        ],
      ),
    );
  }

  Widget _exerciseCard(_ExerciseDraft exercise) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.name,
            style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < exercise.sets.length; i++) ...[
            _setRow(exercise, i),
            if (i < exercise.sets.length - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => setState(() {
              final source = exercise.sets.last;
              exercise.sets.add(_SetDraft.copy(source));
            }),
            child: Text(_ru ? '+ подход' : '+ set'),
          ),
        ],
      ),
    );
  }

  Widget _setRow(_ExerciseDraft exercise, int index) {
    final c = context.colors;
    final set = exercise.sets[index];
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text('${index + 1}', style: TextStyle(color: c.textSecondary)),
        ),
        Expanded(
          child: _numberField(set.weight, _ru ? 'кг' : 'kg', decimal: true),
        ),
        const SizedBox(width: 8),
        Expanded(child: _numberField(set.reps, _ru ? 'повт.' : 'reps')),
        const SizedBox(width: 8),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(40, 36),
          color: c.iconBg,
          onPressed: () => _pickType(set),
          child: Text(switch (set.type) {
            'warmup' => 'W',
            'failure' => 'F',
            'dropset' => 'D',
            _ => 'S',
          }, style: TextStyle(color: c.textPrimary, fontSize: 12)),
        ),
        if (exercise.sets.length > 1)
          CupertinoButton(
            padding: const EdgeInsets.only(left: 8),
            minimumSize: const Size(36, 36),
            onPressed: () => setState(() {
              exercise.sets.removeAt(index).dispose();
            }),
            child: Icon(CupertinoIcons.minus_circle, color: c.textSecondary),
          ),
      ],
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String placeholder, {
    bool decimal = false,
  }) {
    final c = context.colors;
    return CupertinoTextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      placeholder: placeholder,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
      style: TextStyle(color: c.textPrimary, fontSize: 14),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: c.border),
      ),
    );
  }

  Future<void> _pickType(_SetDraft set) async {
    final selected = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(_ru ? 'Тип подхода' : 'Set type'),
        actions: [
          for (final entry in const {
            'working': 'Working',
            'warmup': 'Warm-up',
            'failure': 'Failure',
            'dropset': 'Drop set',
          }.entries)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, entry.key),
              child: Text(entry.value),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(_ru ? 'Отмена' : 'Cancel'),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => set.type = selected);
  }
}

class _ExerciseDraft {
  final int exerciseId;
  final String name;
  final String muscleGroup;
  final List<_SetDraft> sets;

  _ExerciseDraft({
    required this.exerciseId,
    required this.name,
    required this.muscleGroup,
    required this.sets,
  });

  factory _ExerciseDraft.fromLog(PerformedExerciseLog log) => _ExerciseDraft(
    exerciseId: log.exerciseId,
    name: log.name,
    muscleGroup: log.muscleGroup,
    sets: log.sets.map(_SetDraft.fromLog).toList(),
  );

  void dispose() {
    for (final set in sets) {
      set.dispose();
    }
  }
}

class _SetDraft {
  final TextEditingController weight;
  final TextEditingController reps;
  String type;
  final String progression;
  final double? rpe;

  _SetDraft({
    required this.weight,
    required this.reps,
    required this.type,
    required this.progression,
    required this.rpe,
  });

  factory _SetDraft.fromLog(PerformedSetLog log) => _SetDraft(
    weight: TextEditingController(
      text: log.weightKg.toStringAsFixed(
        log.weightKg.truncateToDouble() == log.weightKg ? 0 : 1,
      ),
    ),
    reps: TextEditingController(text: '${log.reps}'),
    type: log.setType,
    progression: log.progression,
    rpe: log.rpe,
  );

  factory _SetDraft.copy(_SetDraft source) => _SetDraft(
    weight: TextEditingController(text: source.weight.text),
    reps: TextEditingController(text: source.reps.text),
    type: source.type,
    progression: source.progression,
    rpe: source.rpe,
  );

  void dispose() {
    weight.dispose();
    reps.dispose();
  }
}
