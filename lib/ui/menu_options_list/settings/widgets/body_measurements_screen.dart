import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:gymboss/data/repositories/measurements_repository.dart';
import 'package:gymboss/data/repositories/ranking_repository.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/domain/models/measurements/body_measurement.dart';
import 'package:gymboss/domain/models/ranking/rank_data.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_page.dart';

class BodyMeasurementsScreen extends StatefulWidget {
  final RankingRepository ranking;
  final RankProfile? profile;
  final ValueChanged<RankProfile> onProfileSaved;

  const BodyMeasurementsScreen({
    super.key,
    required this.ranking,
    required this.profile,
    required this.onProfileSaved,
  });

  @override
  State<BodyMeasurementsScreen> createState() => _BodyMeasurementsScreenState();
}

class _BodyMeasurementsScreenState extends State<BodyMeasurementsScreen> {
  late final MeasurementsRepository _repository;
  List<BodyMeasurement> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = MeasurementsRepository(
      client: context.read<AuthenticatedClient>(),
    );
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _repository.list();
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  void _add() {
    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (_) => _MeasurementEditor(
            repository: _repository,
            ranking: widget.ranking,
            onSaved: (measurement, profile) {
              widget.onProfileSaved(profile);
              setState(() {
                _items = [
                  measurement,
                  ..._items.where((item) => item.id != measurement.id),
                ]..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
              });
            },
          ),
    );
  }

  Future<void> _delete(BodyMeasurement item) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Delete measurement?'),
            content: Text('The entry from ${item.measuredAt} will be removed.'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    await _repository.delete(item.id);
    if (mounted) {
      setState(() => _items = _items.where((e) => e.id != item.id).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPage(
      title: 'Body Measurements',
      actions: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size.square(32),
          onPressed: _add,
          child: const Icon(CupertinoIcons.add_circled),
        ),
      ],
      body:
          _loading
              ? const Center(child: CupertinoActivityIndicator())
              : _error != null
              ? Center(
                child: CupertinoButton(
                  onPressed: _load,
                  child: const Text('Could not load · Retry'),
                ),
              )
              : CustomScrollView(
                slivers: [
                  CupertinoSliverRefreshControl(onRefresh: _load),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _MeasurementChart(items: _items),
                        const SizedBox(height: 18),
                        if (_items.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: c.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: c.border),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  CupertinoIcons.chart_bar_alt_fill,
                                  size: 30,
                                  color: c.accent,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Track changes over time',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: c.textPrimary,
                                    fontFamily: 'Rubik',
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Weight, body fat, chest, waist, hips, arms and thighs.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.textSecondary,
                                    fontFamily: 'Rubik',
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._items.map(
                            (item) => GestureDetector(
                              onLongPress: () => _delete(item),
                              child: _MeasurementCard(item: item),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ],
              ),
    );
  }
}

class _MeasurementChart extends StatelessWidget {
  final List<BodyMeasurement> items;
  const _MeasurementChart({required this.items});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final points =
        items.where((item) => item.weightKg != null).toList().reversed.toList();
    return Container(
      height: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WEIGHT TREND',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: c.textSecondary,
              fontFamily: 'Rubik',
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child:
                points.length < 2
                    ? Center(
                      child: Text(
                        'Add two weight entries to see the trend',
                        style: TextStyle(
                          fontSize: 12,
                          color: c.textSecondary,
                          fontFamily: 'Rubik',
                        ),
                      ),
                    )
                    : CustomPaint(
                      size: Size.infinite,
                      painter: _WeightPainter(
                        values: points.map((item) => item.weightKg!).toList(),
                        color: c.accent,
                        gridColor: c.border,
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

class _WeightPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final Color gridColor;

  const _WeightPainter({
    required this.values,
    required this.color,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final grid =
        Paint()
          ..color = gridColor
          ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = size.height * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = max - min < 0.01 ? 1 : max - min;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - ((values[i] - min) / range * size.height);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _WeightPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

class _MeasurementCard extends StatelessWidget {
  final BodyMeasurement item;
  const _MeasurementCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final values = <String>[
      if (item.weightKg != null) '${item.weightKg!.toStringAsFixed(1)} kg',
      if (item.bodyFatPercent != null)
        '${item.bodyFatPercent!.toStringAsFixed(1)}% fat',
      if (item.chestCm != null) 'Chest ${item.chestCm!.toStringAsFixed(1)}',
      if (item.waistCm != null) 'Waist ${item.waistCm!.toStringAsFixed(1)}',
      if (item.hipsCm != null) 'Hips ${item.hipsCm!.toStringAsFixed(1)}',
      if (item.leftArmCm != null)
        'Arms ${item.leftArmCm!.toStringAsFixed(1)}/${item.rightArmCm?.toStringAsFixed(1) ?? '—'}',
      if (item.leftThighCm != null)
        'Thighs ${item.leftThighCm!.toStringAsFixed(1)}/${item.rightThighCm?.toStringAsFixed(1) ?? '—'}',
    ];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.measuredAt,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
              fontFamily: 'Rubik',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            values.join(' · '),
            style: TextStyle(
              fontSize: 12,
              color: c.textSecondary,
              height: 1.4,
              fontFamily: 'Rubik',
            ),
          ),
          if (item.note.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              item.note,
              style: TextStyle(
                fontSize: 11,
                color: c.textSecondary,
                fontFamily: 'Rubik',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MeasurementEditor extends StatefulWidget {
  final MeasurementsRepository repository;
  final RankingRepository ranking;
  final void Function(BodyMeasurement, RankProfile) onSaved;

  const _MeasurementEditor({
    required this.repository,
    required this.ranking,
    required this.onSaved,
  });

  @override
  State<_MeasurementEditor> createState() => _MeasurementEditorState();
}

class _MeasurementEditorState extends State<_MeasurementEditor> {
  final Map<String, TextEditingController> _controllers = {
    for (final key in const [
      'Weight (kg)',
      'Body fat (%)',
      'Chest (cm)',
      'Waist (cm)',
      'Hips (cm)',
      'Left arm (cm)',
      'Right arm (cm)',
      'Left thigh (cm)',
      'Right thigh (cm)',
    ])
      key: TextEditingController(),
  };
  final _note = TextEditingController();
  bool _saving = false;
  String? _error;

  double? _value(String key) => double.tryParse(_controllers[key]!.text.trim());

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    try {
      final item = await widget.repository.save(
        BodyMeasurement(
          id: '',
          measuredAt: date,
          weightKg: _value('Weight (kg)'),
          bodyFatPercent: _value('Body fat (%)'),
          chestCm: _value('Chest (cm)'),
          waistCm: _value('Waist (cm)'),
          hipsCm: _value('Hips (cm)'),
          leftArmCm: _value('Left arm (cm)'),
          rightArmCm: _value('Right arm (cm)'),
          leftThighCm: _value('Left thigh (cm)'),
          rightThighCm: _value('Right thigh (cm)'),
          note: _note.text.trim(),
        ),
      );
      final profile = await widget.ranking.updateProfile(
        weightKg: item.weightKg,
      );
      widget.onSaved(item, profile);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: MediaQuery.sizeOf(context).height * .82,
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          Text(
            'New Measurement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
              fontFamily: 'Rubik',
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 2.6,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children:
                  _controllers.entries
                      .map(
                        (entry) => CupertinoTextField(
                          controller: entry.value,
                          placeholder: entry.key,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          padding: const EdgeInsets.all(12),
                          style: TextStyle(color: c.textPrimary),
                          decoration: BoxDecoration(
                            color: c.iconBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: c.border),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          CupertinoTextField(
            controller: _note,
            placeholder: 'Note (optional)',
            padding: const EdgeInsets.all(12),
            style: TextStyle(color: c.textPrimary),
            decoration: BoxDecoration(
              color: c.iconBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.border),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: const TextStyle(color: CupertinoColors.systemRed),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: _saving ? null : _save,
              child:
                  _saving
                      ? const CupertinoActivityIndicator()
                      : const Text('Save measurement'),
            ),
          ),
        ],
      ),
    );
  }
}
