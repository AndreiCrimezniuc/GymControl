import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:gymboss/data/repositories/programs_repository.dart';
import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/domain/models/programs/training_program.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_dialog.dart';
import 'package:gymboss/ui/core/ui/widgets/app_page.dart';

class TrainingPlansScreen extends StatefulWidget {
  const TrainingPlansScreen({super.key});

  @override
  State<TrainingPlansScreen> createState() => _TrainingPlansScreenState();
}

class _TrainingPlansScreenState extends State<TrainingPlansScreen> {
  late final ProgramsRepository _programs;
  late final WorkoutsRepository _workouts;
  List<TrainingProgram> _items = const [];
  List<Workout> _routines = const [];
  bool _loading = true;

  bool get _russian => Localizations.localeOf(context).languageCode == 'ru';

  @override
  void initState() {
    super.initState();
    final client = context.read<AuthenticatedClient>();
    _programs = ProgramsRepository(client: client);
    _workouts = WorkoutsRepository(client: client);
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait([
        _programs.list(),
        _workouts.listOwned(),
      ]);
      if (!mounted) return;
      setState(() {
        _items = values[0] as List<TrainingProgram>;
        _routines = values[1] as List<Workout>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final hasGym = _routines.any((item) => item.type == 'gym');
    final hasAerobic = _routines.any((item) => item.type == 'aerobic');
    if (!hasGym && !hasAerobic) {
      await showAppDialog<void>(
        context,
        title: _russian ? 'Сначала нужна тренировка' : 'Create a workout first',
        message: _russian
            ? 'Программа раскладывает ваши готовые тренировки по фазам и календарю.'
            : 'A program arranges your existing workouts into phases and a calendar.',
        actions: [
          AppDialogAction('OK', onPressed: () => Navigator.pop(context)),
        ],
      );
      return;
    }
    final name = TextEditingController();
    final goal = TextEditingController();
    var frequency = 3;
    var kind = hasGym ? 'gym' : 'aerobic';
    final accepted = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _russian ? 'Новая программа' : 'New training program',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                CupertinoTextField(
                  controller: name,
                  placeholder: _russian ? 'Название' : 'Program name',
                  padding: const EdgeInsets.all(13),
                ),
                const SizedBox(height: 10),
                CupertinoTextField(
                  controller: goal,
                  placeholder: _russian ? 'Цель программы' : 'Program goal',
                  padding: const EdgeInsets.all(13),
                ),
                const SizedBox(height: 16),
                Text(
                  _russian ? 'Тип программы' : 'Program type',
                  style: TextStyle(color: context.colors.textPrimary),
                ),
                const SizedBox(height: 8),
                if (hasGym && hasAerobic)
                  CupertinoSlidingSegmentedControl<String>(
                    groupValue: kind,
                    children: {
                      'gym': Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(_russian ? 'Силовая' : 'Strength'),
                      ),
                      'aerobic': Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(_russian ? 'Аэробная' : 'Aerobic'),
                      ),
                    },
                    onValueChanged: (value) {
                      if (value != null) setSheetState(() => kind = value);
                    },
                  )
                else
                  Text(
                    kind == 'aerobic'
                        ? (_russian ? 'Аэробная' : 'Aerobic')
                        : (_russian ? 'Силовая' : 'Strength'),
                    style: TextStyle(
                      color: context.colors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 7),
                Text(
                  kind == 'aerobic'
                      ? (_russian
                            ? 'В этот план попадут только аэробные тренировки.'
                            : 'Only aerobic workouts can be scheduled here.')
                      : (_russian
                            ? 'В этот план попадут только силовые тренировки.'
                            : 'Only strength workouts can be scheduled here.'),
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _russian ? 'Тренировок в неделю' : 'Workouts per week',
                        style: TextStyle(color: context.colors.textPrimary),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: frequency > 2
                          ? () => setSheetState(() => frequency--)
                          : null,
                      child: const Icon(CupertinoIcons.minus_circle),
                    ),
                    Text(
                      '$frequency',
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: frequency < 7
                          ? () => setSheetState(() => frequency++)
                          : null,
                      child: const Icon(CupertinoIcons.plus_circle),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CupertinoButton.filled(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  child: Text(
                    _russian
                        ? 'Создать план на 11 недель'
                        : 'Build 11-week plan',
                  ),
                ),
                CupertinoButton(
                  onPressed: () => Navigator.pop(sheetContext, false),
                  child: Text(_russian ? 'Отмена' : 'Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (accepted != true || name.text.trim().isEmpty) {
      name.dispose();
      goal.dispose();
      return;
    }
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: (8 - now.weekday) % 7));
    final program = TrainingProgram.progressiveTemplate(
      name: name.text,
      goal: goal.text,
      startsOn: monday,
      workouts: _routines,
      sessionsPerWeek: frequency,
      kind: kind,
    );
    name.dispose();
    goal.dispose();
    await _programs.save(program);
    if (mounted) setState(() => _items = [program, ..._items]);
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: _russian ? 'План подготовки' : 'Training plan',
    actions: [
      CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _create,
        child: Icon(CupertinoIcons.add_circled, color: context.colors.accent),
      ),
    ],
    body: _loading
        ? const Center(child: CupertinoActivityIndicator())
        : _items.isEmpty
        ? _EmptyPlan(onCreate: _create, russian: _russian)
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) => _ProgramCard(
              program: _items[index],
              russian: _russian,
              onDelete: () async {
                await _programs.delete(_items[index].id);
                if (mounted) setState(() => _items.removeAt(index));
              },
            ),
          ),
  );
}

class _EmptyPlan extends StatelessWidget {
  final VoidCallback onCreate;
  final bool russian;
  const _EmptyPlan({required this.onCreate, required this.russian});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.calendar_badge_plus,
            size: 42,
            color: context.colors.accent,
          ),
          const SizedBox(height: 14),
          Text(
            russian
                ? 'Тренировки станут маршрутом'
                : 'Turn routines into a route',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            russian
                ? 'Фазы нагрузки, разгрузка и конкретные даты — без ручного копирования каждой недели.'
                : 'Load phases, deload and concrete dates without copying every week by hand.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 18),
          CupertinoButton.filled(
            onPressed: onCreate,
            child: Text(russian ? 'Создать программу' : 'Create program'),
          ),
        ],
      ),
    ),
  );
}

class _ProgramCard extends StatelessWidget {
  final TrainingProgram program;
  final bool russian;
  final VoidCallback onDelete;
  const _ProgramCard({
    required this.program,
    required this.russian,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final next = program.nextWorkout(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  program.name,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 40),
                onPressed: onDelete,
                child: Icon(
                  CupertinoIcons.archivebox,
                  size: 17,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          if (program.goal.isNotEmpty)
            Text(
              program.goal,
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          const SizedBox(height: 5),
          Text(
            program.kind == 'aerobic'
                ? (russian ? 'АЭРОБНАЯ ПРОГРАММА' : 'AEROBIC PROGRAM')
                : (russian ? 'СИЛОВАЯ ПРОГРАММА' : 'STRENGTH PROGRAM'),
            style: TextStyle(
              color: colors.accent,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 35,
            child: Row(
              children: [
                for (final phase in program.phases)
                  Expanded(
                    flex: phase.weeks,
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(
                          alpha: .12 + phase.intensity * .12,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        phase.name,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        style: TextStyle(
                          color: colors.accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(CupertinoIcons.calendar, size: 15, color: colors.accent),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  next == null
                      ? (russian ? 'Расписание завершено' : 'Schedule complete')
                      : '${next.plannedOn} · ${next.workoutName}',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${program.totalWeeks} ${russian ? 'недель' : 'weeks'}',
                style: TextStyle(color: colors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) =>
                    _ProgramScheduleScreen(program: program, russian: russian),
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(russian ? 'Открыть календарь →' : 'Open calendar →'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramScheduleScreen extends StatelessWidget {
  final TrainingProgram program;
  final bool russian;

  const _ProgramScheduleScreen({required this.program, required this.russian});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final phaseNames = {
      for (final phase in program.phases) phase.id: phase.name,
    };
    final items = [...program.schedule]
      ..sort((a, b) => a.plannedOn.compareTo(b.plannedOn));
    return AppPage(
      title: program.name,
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          final item = items[index];
          final date = item.date;
          final weekday = date == null
              ? ''
              : const [
                  'MON',
                  'TUE',
                  'WED',
                  'THU',
                  'FRI',
                  'SAT',
                  'SUN',
                ][date.weekday - 1];
          final completed = item.status == 'completed';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 54,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date == null
                            ? item.plannedOn
                            : '${date.day}.${date.month.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        weekday,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 2,
                  height: 34,
                  color: completed ? colors.accent : colors.border,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.workoutName,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        phaseNames[item.phaseId] ?? '',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (completed)
                  Icon(
                    CupertinoIcons.check_mark_circled_solid,
                    size: 18,
                    color: colors.accent,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
