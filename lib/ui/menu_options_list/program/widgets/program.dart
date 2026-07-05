import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymboss/data/repositories/trainings_api.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/services/trainings/trainings.dart';
import 'package:gymboss/domain/models/trainings/trainings.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_page.dart';

const _prefsKey = 'program_schedule_v1';
const _dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _shortDays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

class Program extends StatefulWidget {
  const Program({super.key});

  @override
  State<Program> createState() => _ProgramState();
}

class _ProgramState extends State<Program> {
  late final TrainingsService _trainings;

  // weekday index (0=Mon) -> training name (null = rest day)
  List<String?> _schedule = List<String?>.filled(7, null);
  Map<String, TrainingComplexity> _complexityByName = {};
  List<String> _available = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _trainings = TrainingsService(
      repository: TrainingsApiRepository(client: context.read<AuthenticatedClient>()),
    );
    _load();
  }

  Future<void> _load() async {
    // saved schedule (survives restarts)
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    List<String?> saved = List<String?>.filled(7, null);
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List).cast<dynamic>();
        for (var i = 0; i < 7 && i < list.length; i++) {
          final v = list[i];
          saved[i] = (v is String && v.isNotEmpty) ? v : null;
        }
      } catch (_) {}
    }

    // real trainings for the available options + complexity lookup
    final available = <String>[];
    final byName = <String, TrainingComplexity>{};
    try {
      final trainings = await _trainings.fetchAllTrainings();
      for (final t in trainings) {
        if (!byName.containsKey(t.name)) {
          byName[t.name] = t.complexity;
          available.add(t.name);
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _schedule = saved;
      _available = available;
      _complexityByName = byName;
      _loading = false;
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_schedule.map((e) => e ?? '').toList()));
  }

  int get _workoutDays => _schedule.where((d) => d != null).length;
  int get _restDays => 7 - _workoutDays;

  TrainingComplexity? _complexityFor(String? name) =>
      name == null ? null : _complexityByName[name];

  Color _complexityColor(TrainingComplexity? c) => switch (c) {
    TrainingComplexity.hard => const Color(0xFFEF4444),
    TrainingComplexity.medium => const Color(0xFFF59E0B),
    TrainingComplexity.easy => const Color(0xFF10B981),
    null => context.colors.textSecondary,
  };

  void _editDay(int index) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(_dayNames[index]),
        message: const Text('Choose a training or rest'),
        actions: [
          ..._available.map(
            (name) => CupertinoActionSheetAction(
              onPressed: () {
                setState(() => _schedule[index] = name);
                _persist();
                Navigator.pop(context);
              },
              child: Text(name),
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              setState(() => _schedule[index] = null);
              _persist();
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
      body: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : ListView(
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Rubik', color: c.textPrimary),
                ),
                const SizedBox(height: 12),
                ...List.generate(7, (i) {
                  final name = _schedule[i];
                  final isToday = i + 1 == today;
                  final hasWorkout = name != null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => _editDay(i),
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
                                  _shortDays[i],
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
                                        _dayNames[i],
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary, fontFamily: 'Rubik'),
                                      ),
                                      if (isToday) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(6)),
                                          child: Text('Today',
                                              style: TextStyle(fontSize: 10, color: c.textOnAccent, fontFamily: 'Rubik', fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    name ?? 'Rest Day',
                                    style: TextStyle(fontSize: 12, color: _complexityColor(_complexityFor(name)), fontFamily: 'Rubik'),
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

  const _SummaryCard({required this.value, required this.label, required this.icon});

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
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: c.textPrimary, fontFamily: 'Rubik')),
                Text(label, style: TextStyle(fontSize: 12, color: c.textSecondary, fontFamily: 'Rubik')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
