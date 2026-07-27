import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_scaffold.dart';
import 'package:gymboss/ui/core/ui/widgets/pressable.dart';

/// Count-up stopwatch with laps for an aerobic ("разгрузочная"/cardio) workout.
/// Kept free of UI so the timer/lap logic is unit-testable.
class AerobicSessionController extends ChangeNotifier {
  int _total = 0; // total elapsed seconds
  int _lapBase = 0; // total at the start of the current lap
  bool _running = false;
  final List<int> _laps = [];
  Timer? _ticker;

  int get totalSeconds => _total;
  int get currentLapSeconds => _total - _lapBase;
  bool get running => _running;
  List<int> get laps => List.unmodifiable(_laps);

  void start() {
    if (_running) return;
    _running = true;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _total++;
      notifyListeners();
    });
    notifyListeners();
  }

  void pause() {
    if (!_running) return;
    _ticker?.cancel();
    _running = false;
    notifyListeners();
  }

  void toggle() => _running ? pause() : start();

  /// Close the current lap and start a new one. Ignores empty laps.
  void lap() {
    final d = _total - _lapBase;
    if (d <= 0) return;
    _laps.add(d);
    _lapBase = _total;
    notifyListeners();
  }

  void reset() {
    _ticker?.cancel();
    _total = 0;
    _lapBase = 0;
    _running = false;
    _laps.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  static String fmt(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }
}

class AerobicRunnerScreen extends StatefulWidget {
  final String workoutId;
  final String workoutName;
  final WorkoutsRepository repo;
  const AerobicRunnerScreen({
    super.key,
    required this.workoutId,
    required this.workoutName,
    required this.repo,
  });

  @override
  State<AerobicRunnerScreen> createState() => _AerobicRunnerScreenState();
}

class _AerobicRunnerScreenState extends State<AerobicRunnerScreen> {
  final _c = AerobicSessionController();
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onChange);
    _c.start();
  }

  void _onChange() => setState(() {});

  @override
  void dispose() {
    _c.removeListener(_onChange);
    _c.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    _c.pause();
    HapticFeedback.heavyImpact();
    try {
      await widget.repo.logRun(
        widget.workoutId,
        'normal',
        durationSeconds: _c.totalSeconds,
      );
    } catch (_) {}
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppScaffold(
      child: SafeArea(
        child: Column(
          children: [
            _header(c),
            Expanded(child: _clock(c)),
            _controls(c),
            if (_c.laps.isNotEmpty) _lapList(c),
            _finishBar(c),
          ],
        ),
      ),
    );
  }

  Widget _header(AppColors c) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
    child: Row(
      children: [
        Pressable(
          onTap: () => Navigator.of(context).maybePop(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              CupertinoIcons.chevron_down,
              size: 22,
              color: c.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            widget.workoutName.isEmpty ? 'Aerobic' : widget.workoutName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
              fontFamily: 'Rubik',
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    ),
  );

  Widget _clock(AppColors c) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AerobicSessionController.fmt(_c.totalSeconds),
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: c.textPrimary,
            fontFamily: 'Rubik',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _c.laps.isEmpty
              ? (_c.running ? 'Running' : 'Paused')
              : 'Lap ${_c.laps.length + 1} · ${AerobicSessionController.fmt(_c.currentLapSeconds)}',
          style: TextStyle(
            fontSize: 14,
            color: c.textSecondary,
            fontFamily: 'Rubik',
          ),
        ),
      ],
    ),
  );

  Widget _controls(AppColors c) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: _btn(
            c,
            _c.laps.isEmpty && !_c.running ? 'Reset' : 'Lap',
            _c.running ? _c.lap : _c.reset,
            filled: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _btn(
            c,
            _c.running ? 'Pause' : 'Resume',
            _c.toggle,
            filled: true,
          ),
        ),
      ],
    ),
  );

  Widget _btn(
    AppColors c,
    String label,
    VoidCallback onTap, {
    required bool filled,
  }) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? c.accent : c.iconBg,
          borderRadius: BorderRadius.circular(14),
          border: filled ? null : Border.all(color: c.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: filled ? c.textOnAccent : c.textPrimary,
            fontFamily: 'Rubik',
          ),
        ),
      ),
    );
  }

  Widget _lapList(AppColors c) => Container(
    constraints: const BoxConstraints(maxHeight: 160),
    margin: const EdgeInsets.fromLTRB(24, 4, 24, 4),
    child: ListView.builder(
      itemCount: _c.laps.length,
      reverse: true,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Lap ${i + 1}',
              style: TextStyle(
                fontSize: 13,
                color: c.textSecondary,
                fontFamily: 'Rubik',
              ),
            ),
            Text(
              AerobicSessionController.fmt(_c.laps[i]),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: c.textPrimary,
                fontFamily: 'Rubik',
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _finishBar(AppColors c) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
    child: Pressable(
      onTap: _finish,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.accent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          _finishing ? 'SAVING…' : 'FINISH',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: c.textOnAccent,
            fontFamily: 'Rubik',
          ),
        ),
      ),
    ),
  );
}
