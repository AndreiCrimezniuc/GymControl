import 'package:flutter/cupertino.dart';
import 'package:gymboss/domain/models/trainings/trainings.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_page.dart';

class _DayPlan {
  final String day;
  final String shortDay;
  String? trainingName;
  TrainingComplexity? complexity;

  _DayPlan({
    required this.day,
    required this.shortDay,
    this.trainingName,
    this.complexity,
  });
}

class Program extends StatefulWidget {
  const Program({super.key});

  @override
  State<Program> createState() => _ProgramState();
}

class _ProgramState extends State<Program> {
  final List<_DayPlan> _schedule = [
    _DayPlan(day: 'Monday',    shortDay: 'MON', trainingName: 'Hard Day',   complexity: TrainingComplexity.hard),
    _DayPlan(day: 'Tuesday',   shortDay: 'TUE'),
    _DayPlan(day: 'Wednesday', shortDay: 'WED', trainingName: 'Medium Day', complexity: TrainingComplexity.medium),
    _DayPlan(day: 'Thursday',  shortDay: 'THU'),
    _DayPlan(day: 'Friday',    shortDay: 'FRI', trainingName: 'Hard Day',   complexity: TrainingComplexity.hard),
    _DayPlan(day: 'Saturday',  shortDay: 'SAT', trainingName: 'Easy Day',   complexity: TrainingComplexity.easy),
    _DayPlan(day: 'Sunday',    shortDay: 'SUN'),
  ];

  static const _available = ['Hard Day', 'Medium Day', 'Easy Day'];

  int get _workoutDays => _schedule.where((d) => d.trainingName != null).length;
  int get _restDays    => _schedule.length - _workoutDays;

  Color _complexityColor(TrainingComplexity? c) => switch (c) {
    TrainingComplexity.hard   => const Color(0xFFEF4444),
    TrainingComplexity.medium => const Color(0xFFF59E0B),
    TrainingComplexity.easy   => const Color(0xFF10B981),
    null                      => context.colors.textSecondary,
  };

  TrainingComplexity _complexityFor(String name) => switch (name) {
    'Hard Day'   => TrainingComplexity.hard,
    'Medium Day' => TrainingComplexity.medium,
    _            => TrainingComplexity.easy,
  };

  void _editDay(_DayPlan day) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(day.day),
        message: const Text('Choose a training or rest'),
        actions: [
          ..._available.map(
            (t) => CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  day.trainingName = t;
                  day.complexity = _complexityFor(t);
                });
                Navigator.pop(context);
              },
              child: Text(t),
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              setState(() {
                day.trainingName = null;
                day.complexity = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Set as Rest Day'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final today = DateTime.now().weekday; // 1 = Monday

    return AppPage(
      title: 'Program',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Row(
            children: [
              _SummaryCard(value: '$_workoutDays', label: 'Workouts', icon: CupertinoIcons.bolt_fill),
              const SizedBox(width: 12),
              _SummaryCard(value: '$_restDays', label: 'Rest Days', icon: CupertinoIcons.moon_fill),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'This Week',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Rubik',
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_schedule.length, (i) {
            final day = _schedule[i];
            final isToday = i + 1 == today;
            final hasWorkout = day.trainingName != null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _editDay(day),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isToday ? c.accent : c.border,
                      width: isToday ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: hasWorkout ? c.accent : c.iconBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            day.shortDay,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: hasWorkout ? c.textOnAccent : c.textSecondary,
                              fontFamily: 'Rubik',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  day.day,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: c.textPrimary,
                                    fontFamily: 'Rubik',
                                  ),
                                ),
                                if (isToday) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: c.accent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Today',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: c.textOnAccent,
                                        fontFamily: 'Rubik',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              day.trainingName ?? 'Rest Day',
                              style: TextStyle(
                                fontSize: 12,
                                color: _complexityColor(day.complexity),
                                fontFamily: 'Rubik',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(CupertinoIcons.pencil, size: 16, color: c.textSecondary),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _SummaryCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: c.accent, size: 22),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                    fontFamily: 'Rubik',
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: c.textSecondary, fontFamily: 'Rubik'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
