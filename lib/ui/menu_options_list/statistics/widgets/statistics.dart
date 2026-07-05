import 'package:flutter/cupertino.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_page.dart';

class _WeekVolume {
  final String day;
  final int volume;
  const _WeekVolume(this.day, this.volume);
}

class _PersonalRecord {
  final String exercise;
  final double weight;
  final int reps;
  final String date;
  const _PersonalRecord(this.exercise, this.weight, this.reps, this.date);
}

class Statistics extends StatelessWidget {
  const Statistics({super.key});

  static const _weekData = [
    _WeekVolume('Mon', 2400),
    _WeekVolume('Tue', 0),
    _WeekVolume('Wed', 3100),
    _WeekVolume('Thu', 0),
    _WeekVolume('Fri', 2800),
    _WeekVolume('Sat', 1900),
    _WeekVolume('Sun', 0),
  ];

  static const _records = [
    _PersonalRecord('Bench Press', 100, 5, 'May 15'),
    _PersonalRecord('Squats', 140, 3, 'May 12'),
    _PersonalRecord('Deadlift', 160, 2, 'May 10'),
    _PersonalRecord('Pull Ups', 0, 15, 'May 17'),
    _PersonalRecord('Overhead Press', 70, 8, 'May 14'),
  ];

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Statistics',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: const [
          Row(
            children: [
              _StatTile(title: 'Streak', value: '7', unit: 'days', icon: CupertinoIcons.flame_fill),
              SizedBox(width: 10),
              _StatTile(title: 'This Week', value: '3', unit: 'workouts', icon: CupertinoIcons.calendar),
              SizedBox(width: 10),
              _StatTile(title: 'All Time', value: '42', unit: 'total', icon: CupertinoIcons.chart_bar_fill),
            ],
          ),
          SizedBox(height: 24),
          _SectionLabel('Weekly Volume'),
          SizedBox(height: 12),
          _VolumeChart(data: _weekData),
          SizedBox(height: 24),
          _SectionLabel('Personal Records'),
          SizedBox(height: 12),
          _RecordsList(records: _records),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        fontFamily: 'Rubik',
        color: context.colors.textPrimary,
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;

  const _StatTile({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: c.accent, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
                fontFamily: 'Rubik',
              ),
            ),
            Text(
              unit,
              style: TextStyle(fontSize: 10, color: c.textSecondary, fontFamily: 'Rubik'),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: c.textSecondary, fontFamily: 'Rubik'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeChart extends StatelessWidget {
  final List<_WeekVolume> data;
  const _VolumeChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxVol = data.map((e) => e.volume).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((d) {
                final fraction = maxVol > 0 ? d.volume / maxVol : 0.0;
                final barH = d.volume > 0 ? (fraction * 76).clamp(6.0, 76.0) : 4.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (d.volume > 0)
                          Text(
                            '${(d.volume / 1000).toStringAsFixed(1)}t',
                            style: TextStyle(fontSize: 8, color: c.textSecondary, fontFamily: 'Rubik'),
                          ),
                        const SizedBox(height: 2),
                        Container(
                          height: barH,
                          decoration: BoxDecoration(
                            color: d.volume > 0 ? c.accent : c.iconBg,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: data.map((d) => Expanded(
              child: Center(
                child: Text(
                  d.day,
                  style: TextStyle(fontSize: 10, color: c.textSecondary, fontFamily: 'Rubik'),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _RecordsList extends StatelessWidget {
  final List<_PersonalRecord> records;
  const _RecordsList({required this.records});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: records.length,
        separatorBuilder: (_, __) => Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: c.border,
        ),
        itemBuilder: (_, i) {
          final r = records[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(CupertinoIcons.star_fill, size: 16, color: c.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    r.exercise,
                    style: TextStyle(
                      fontSize: 14,
                      color: c.textPrimary,
                      fontFamily: 'Rubik',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      r.weight > 0
                          ? '${r.weight.toStringAsFixed(0)} kg × ${r.reps}'
                          : '${r.reps} reps',
                      style: TextStyle(
                        fontSize: 14,
                        color: c.textPrimary,
                        fontFamily: 'Rubik',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      r.date,
                      style: TextStyle(fontSize: 11, color: c.textSecondary, fontFamily: 'Rubik'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
