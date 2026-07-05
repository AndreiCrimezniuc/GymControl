import 'package:flutter/cupertino.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_page.dart';

class _CatalogEntry {
  final String name;
  final String muscleGroup;
  final String description;

  const _CatalogEntry({
    required this.name,
    required this.muscleGroup,
    required this.description,
  });
}

const _catalog = [
  _CatalogEntry(name: 'Bench Press', muscleGroup: 'Chest', description: 'Lie on bench, lower bar to chest, press up.'),
  _CatalogEntry(name: 'Incline DB Press', muscleGroup: 'Chest', description: 'Press dumbbells on an inclined bench.'),
  _CatalogEntry(name: 'Cable Fly', muscleGroup: 'Chest', description: 'Cable crossover fly for chest isolation.'),
  _CatalogEntry(name: 'Pull Ups', muscleGroup: 'Back', description: 'Dead hang, pull until chin clears the bar.'),
  _CatalogEntry(name: 'Barbell Row', muscleGroup: 'Back', description: 'Bent-over row for upper back thickness.'),
  _CatalogEntry(name: 'Lat Pulldown', muscleGroup: 'Back', description: 'Pull bar to upper chest for lat width.'),
  _CatalogEntry(name: 'Squats', muscleGroup: 'Legs', description: 'Full-depth squat with bar on upper back.'),
  _CatalogEntry(name: 'Romanian Deadlift', muscleGroup: 'Legs', description: 'Hip hinge targeting hamstrings and glutes.'),
  _CatalogEntry(name: 'Leg Press', muscleGroup: 'Legs', description: 'Press plate for quad and glute development.'),
  _CatalogEntry(name: 'Overhead Press', muscleGroup: 'Shoulders', description: 'Press barbell overhead for shoulder mass.'),
  _CatalogEntry(name: 'Lateral Raises', muscleGroup: 'Shoulders', description: 'Dumbbell raises for lateral deltoid isolation.'),
  _CatalogEntry(name: 'Face Pulls', muscleGroup: 'Shoulders', description: 'Cable pull for rear delt and external rotation.'),
  _CatalogEntry(name: 'Barbell Curl', muscleGroup: 'Arms', description: 'Curl barbell for bicep peak development.'),
  _CatalogEntry(name: 'Tricep Pushdown', muscleGroup: 'Arms', description: 'Cable pushdown for tricep isolation.'),
  _CatalogEntry(name: 'Hammer Curl', muscleGroup: 'Arms', description: 'Neutral grip curl for brachialis development.'),
  _CatalogEntry(name: 'Plank', muscleGroup: 'Core', description: 'Isometric hold for core stability endurance.'),
  _CatalogEntry(name: 'Cable Crunch', muscleGroup: 'Core', description: 'Cable crunch for rectus abdominis isolation.'),
  _CatalogEntry(name: 'Hanging Leg Raise', muscleGroup: 'Core', description: 'Raise legs from a dead hang for lower abs.'),
];

const _groups = ['All', 'Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core'];

class Exercises extends StatefulWidget {
  const Exercises({super.key});

  @override
  State<Exercises> createState() => _ExercisesState();
}

class _ExercisesState extends State<Exercises> {
  String _group = 'All';
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_CatalogEntry> get _filtered => _catalog.where((e) {
    final matchGroup = _group == 'All' || e.muscleGroup == _group;
    final matchQuery = _query.isEmpty ||
        e.name.toLowerCase().contains(_query.toLowerCase());
    return matchGroup && matchQuery;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final filtered = _filtered;
    return AppPage(
      title: 'Exercises',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: CupertinoSearchTextField(
              controller: _searchCtrl,
              placeholder: 'Search exercises',
              backgroundColor: c.card,
              style: TextStyle(color: c.textPrimary, fontFamily: 'Rubik'),
              placeholderStyle: TextStyle(color: c.textSecondary, fontFamily: 'Rubik'),
              itemColor: c.textSecondary,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _groups.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final g = _groups[i];
                final active = g == _group;
                return GestureDetector(
                  onTap: () => setState(() => _group = g),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: active ? c.accent : c.card,
                      borderRadius: BorderRadius.circular(12),
                      border: active ? null : Border.all(color: c.border),
                    ),
                    child: Text(
                      g,
                      style: TextStyle(
                        fontSize: 13,
                        color: active ? c.textOnAccent : c.textSecondary,
                        fontFamily: 'Rubik',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No exercises found',
                      style: TextStyle(color: c.textSecondary, fontFamily: 'Rubik'),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _ExerciseTile(entry: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final _CatalogEntry entry;
  const _ExerciseTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(
          builder: (_) => _ExerciseDetailScreen(entry: entry),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                      fontFamily: 'Rubik',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.textSecondary,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: c.iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entry.muscleGroup,
                style: TextStyle(
                  fontSize: 11,
                  color: c.accent,
                  fontFamily: 'Rubik',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(CupertinoIcons.chevron_forward, size: 16, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _ExerciseDetailScreen extends StatelessWidget {
  final _CatalogEntry entry;
  const _ExerciseDetailScreen({required this.entry});

  static const _history = [
    {'date': 'May 17', 'sets': '4 × 10 @ 80 kg'},
    {'date': 'May 14', 'sets': '3 × 8 @ 82.5 kg'},
    {'date': 'May 10', 'sets': '4 × 10 @ 77.5 kg'},
    {'date': 'May 7',  'sets': '3 × 10 @ 75 kg'},
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPage(
      title: entry.name,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.muscleGroup,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.textOnAccent,
                      fontFamily: 'Rubik',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  entry.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: c.textSecondary,
                    fontFamily: 'Rubik',
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Recent History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Rubik',
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length,
              separatorBuilder: (_, __) => Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: c.border,
              ),
              itemBuilder: (_, i) {
                final h = _history[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.calendar, size: 16, color: c.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          h['date']!,
                          style: TextStyle(
                            fontSize: 14,
                            color: c.textSecondary,
                            fontFamily: 'Rubik',
                          ),
                        ),
                      ),
                      Text(
                        h['sets']!,
                        style: TextStyle(
                          fontSize: 14,
                          color: c.textPrimary,
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
