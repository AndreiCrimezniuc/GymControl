import 'package:flutter/cupertino.dart';
import 'package:gymboss/domain/models/trainings/trainings.dart';
import 'package:gymboss/ui/core/ui/colors/main_dark_blue.dart';
import 'package:gymboss/ui/core/ui/colors/main_gradient.dart';

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
    null                      => const Color(0xFF546A7B),
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
    final today = DateTime.now().weekday; // 1 = Monday

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFCAE9FF),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Program'),
        backgroundColor: Color(0xFFCAE9FF),
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _SummaryCard(
                  value: '$_workoutDays',
                  label: 'Workouts',
                  icon: CupertinoIcons.bolt_fill,
                  iconColor: const Color(0xFF8B5CF6),
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  value: '$_restDays',
                  label: 'Rest Days',
                  icon: CupertinoIcons.moon_fill,
                  iconColor: const Color(0xFF06B6D4),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'This Week',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Rubik',
                color: Color(0xFF0D1F2D),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(_schedule.length, (i) {
              final day = _schedule[i];
              final isToday = i + 1 == today;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => _editDay(day),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isToday ? const Color(0xFF162534) : mainDarkBlue,
                      borderRadius: BorderRadius.circular(16),
                      border: isToday
                          ? Border.all(color: const Color(0xFF3B82F6), width: 1.5)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: day.trainingName != null
                                ? MainGradient.purpleBlueGradient
                                : null,
                            color: day.trainingName == null
                                ? const Color(0xFF1E3A50)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              day.shortDay,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: day.trainingName != null
                                    ? CupertinoColors.white
                                    : const Color(0xFF546A7B),
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
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: CupertinoColors.white,
                                      fontFamily: 'Rubik',
                                    ),
                                  ),
                                  if (isToday) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Today',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: CupertinoColors.white,
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
                        const Icon(
                          CupertinoIcons.pencil,
                          size: 16,
                          color: Color(0xFF546A7B),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _SummaryCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: mainDarkBlue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.white,
                    fontFamily: 'Rubik',
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF546A7B),
                    fontFamily: 'Rubik',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
