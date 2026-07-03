import 'package:flutter/cupertino.dart';
import 'package:gymboss/ui/core/ui/colors/main_dark_blue.dart';
import 'package:gymboss/ui/core/ui/colors/main_gradient.dart';

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
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFCAE9FF),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Statistics'),
        backgroundColor: Color(0xFFCAE9FF),
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _StatTile(
                  title: 'Streak',
                  value: '7',
                  unit: 'days',
                  icon: CupertinoIcons.flame_fill,
                  iconColor: const Color(0xFFFF6B35),
                ),
                const SizedBox(width: 10),
                _StatTile(
                  title: 'This Week',
                  value: '3',
                  unit: 'workouts',
                  icon: CupertinoIcons.calendar,
                  iconColor: const Color(0xFF06B6D4),
                ),
                const SizedBox(width: 10),
                _StatTile(
                  title: 'All Time',
                  value: '42',
                  unit: 'total',
                  icon: CupertinoIcons.chart_bar_fill,
                  iconColor: const Color(0xFF8B5CF6),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionLabel('Weekly Volume'),
            const SizedBox(height: 12),
            _VolumeChart(data: _weekData),
            const SizedBox(height: 24),
            _sectionLabel('Personal Records'),
            const SizedBox(height: 12),
            _RecordsList(records: _records),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      fontFamily: 'Rubik',
      color: Color(0xFF0D1F2D),
    ),
  );
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;

  const _StatTile({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: mainDarkBlue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: CupertinoColors.white,
                fontFamily: 'Rubik',
              ),
            ),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF8B9EAE),
                fontFamily: 'Rubik',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF546A7B),
                fontFamily: 'Rubik',
              ),
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
    final maxVol = data.map((e) => e.volume).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: mainDarkBlue,
        borderRadius: BorderRadius.circular(16),
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
                            style: const TextStyle(
                              fontSize: 8,
                              color: Color(0xFF8B9EAE),
                              fontFamily: 'Rubik',
                            ),
                          ),
                        const SizedBox(height: 2),
                        Container(
                          height: barH,
                          decoration: BoxDecoration(
                            gradient: d.volume > 0 ? MainGradient.purpleBlueGradient : null,
                            color: d.volume == 0 ? const Color(0xFF1E3A50) : null,
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
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF546A7B),
                    fontFamily: 'Rubik',
                  ),
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
    return Container(
      decoration: BoxDecoration(
        color: mainDarkBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: records.length,
        separatorBuilder: (_, __) => Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: const Color(0xFF1E3A50),
        ),
        itemBuilder: (_, i) {
          final r = records[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                ShaderMask(
                  shaderCallback: (b) =>
                      MainGradient.purpleBlueGradient.createShader(b),
                  child: const Icon(
                    CupertinoIcons.star_fill,
                    size: 16,
                    color: CupertinoColors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    r.exercise,
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.white,
                      fontFamily: 'Rubik',
                      fontWeight: FontWeight.w500,
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
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.white,
                        fontFamily: 'Rubik',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      r.date,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF546A7B),
                        fontFamily: 'Rubik',
                      ),
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
