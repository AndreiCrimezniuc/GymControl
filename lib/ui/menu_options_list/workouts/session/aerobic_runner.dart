import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/data/repositories/sessions_repository.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_scaffold.dart';
import 'package:gymboss/ui/core/ui/widgets/app_dialog.dart';
import 'package:gymboss/ui/core/ui/widgets/pressable.dart';

/// Count-up stopwatch with laps for an aerobic ("разгрузочная"/cardio) workout.
/// Kept free of UI so the timer/lap logic is unit-testable.
class AerobicSessionController extends ChangeNotifier {
  static const _storageKey = 'active_aerobic_session_v1';
  final DateTime Function() _now;
  int _accumulated = 0;
  int _segmentBase = 0;
  int _lapBase = 0; // total at the start of the current lap
  bool _running = false;
  bool _active = false;
  bool _minimized = false;
  DateTime? _runningSince;
  DateTime? _startedAt;
  String _workoutId = '';
  String _workoutName = '';
  String _sessionId = '';
  final List<int> _laps = [];
  Timer? _ticker;
  int _persistenceVersion = 0;

  AerobicSessionController({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  int get totalSeconds {
    if (_runningSince == null) return _accumulated;
    final wallClock =
        _segmentBase +
        _now().difference(_runningSince!).inSeconds.clamp(0, 172800);
    return wallClock > _accumulated ? wallClock : _accumulated;
  }

  int get currentLapSeconds => totalSeconds - _lapBase;
  bool get running => _running;
  bool get isActive => _active;
  bool get isMinimized => _minimized;
  String get workoutId => _workoutId;
  String get workoutName => _workoutName;
  String get sessionId => _sessionId;
  DateTime get startedAt => _startedAt ?? _now();
  List<int> get laps => List.unmodifiable(_laps);

  void begin({required String workoutId, required String workoutName}) {
    if (_active && _workoutId == workoutId) {
      notifyListeners();
      return;
    }
    _ticker?.cancel();
    _persistenceVersion++;
    _accumulated = 0;
    _segmentBase = 0;
    _lapBase = 0;
    _laps.clear();
    _workoutId = workoutId;
    _workoutName = workoutName;
    _sessionId = const Uuid().v4();
    _startedAt = _now();
    _active = true;
    _minimized = false;
    _running = false;
    _runningSince = null;
    start();
  }

  void start() {
    if (_running) return;
    _active = true;
    _sessionId = _sessionId.isEmpty ? const Uuid().v4() : _sessionId;
    _startedAt ??= _now();
    _running = true;
    _segmentBase = _accumulated;
    _runningSince = _now();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _accumulated++;
      notifyListeners();
    });
    unawaited(_persist());
    notifyListeners();
  }

  void pause() {
    if (!_running) return;
    _accumulated = totalSeconds;
    _segmentBase = _accumulated;
    _runningSince = null;
    _ticker?.cancel();
    _running = false;
    unawaited(_persist());
    notifyListeners();
  }

  void toggle() => _running ? pause() : start();

  /// Close the current lap and start a new one. Ignores empty laps.
  void lap() {
    final total = totalSeconds;
    final d = total - _lapBase;
    if (d <= 0) return;
    _laps.add(d);
    _lapBase = total;
    unawaited(_persist());
    notifyListeners();
  }

  void reset() {
    _ticker?.cancel();
    _accumulated = 0;
    _segmentBase = 0;
    _lapBase = 0;
    _running = false;
    _runningSince = null;
    _laps.clear();
    unawaited(_persist());
    notifyListeners();
  }

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final startedAt = DateTime.tryParse(json['started_at'] as String? ?? '');
      final runningSince = DateTime.tryParse(
        json['running_since'] as String? ?? '',
      );
      final id = json['session_id'] as String? ?? '';
      if (startedAt == null || id.isEmpty) throw const FormatException();
      _workoutId = json['workout_id'] as String? ?? '';
      _workoutName = json['workout_name'] as String? ?? '';
      _sessionId = id;
      _startedAt = startedAt;
      _accumulated =
          (json['accumulated'] as num?)?.toInt().clamp(0, 172800) ?? 0;
      _segmentBase = _accumulated;
      _lapBase = (json['lap_base'] as num?)?.toInt().clamp(0, 172800) ?? 0;
      _laps
        ..clear()
        ..addAll(
          ((json['laps'] as List?) ?? const []).map(
            (value) => (value as num).toInt().clamp(0, 172800),
          ),
        );
      _active = true;
      _minimized = true;
      _running = json['running'] == true;
      _runningSince = _running ? (runningSince ?? _now()) : null;
      if (_running) {
        _ticker?.cancel();
        _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
          _accumulated++;
          notifyListeners();
        });
      }
      notifyListeners();
    } catch (_) {
      await prefs.remove(_storageKey);
    }
  }

  Future<void> clear() async {
    _persistenceVersion++;
    _ticker?.cancel();
    _accumulated = 0;
    _segmentBase = 0;
    _lapBase = 0;
    _running = false;
    _active = false;
    _minimized = false;
    _runningSince = null;
    _startedAt = null;
    _workoutId = '';
    _workoutName = '';
    _sessionId = '';
    _laps.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }

  void minimize() {
    if (!_active || _minimized) return;
    _minimized = true;
    notifyListeners();
  }

  void resume() {
    if (!_active || !_minimized) return;
    _minimized = false;
    notifyListeners();
  }

  Future<void> _persist() async {
    if (!_active) return;
    final version = _persistenceVersion;
    final prefs = await SharedPreferences.getInstance();
    if (!_active || version != _persistenceVersion) return;
    await prefs.setString(
      _storageKey,
      jsonEncode({
        'workout_id': _workoutId,
        'workout_name': _workoutName,
        'session_id': _sessionId,
        'started_at': _startedAt?.toIso8601String(),
        'accumulated': _accumulated,
        'lap_base': _lapBase,
        'laps': _laps,
        'running': _running,
        'running_since': _runningSince?.toIso8601String(),
      }),
    );
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
  final SessionsRepository sessions;
  const AerobicRunnerScreen({
    super.key,
    required this.workoutId,
    required this.workoutName,
    required this.repo,
    required this.sessions,
  });

  @override
  State<AerobicRunnerScreen> createState() => _AerobicRunnerScreenState();
}

class _AerobicRunnerScreenState extends State<AerobicRunnerScreen> {
  late final AerobicSessionController _c;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _c = context.read<AerobicSessionController>();
    _c.addListener(_onChange);
    _c.begin(workoutId: widget.workoutId, workoutName: widget.workoutName);
    _c.resume();
  }

  void _onChange() => setState(() {});

  @override
  void dispose() {
    if (_c.isActive) _c.minimize();
    _c.removeListener(_onChange);
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
        sessionId: _c.sessionId,
        performedAt: _c.startedAt,
      );
      await widget.sessions.recordSession(
        performedAt: _c.startedAt,
        sessionId: _c.sessionId,
      );
      await _c.clear();
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _finishing = false);
      await showAppDialog<void>(
        context,
        title: Localizations.localeOf(context).languageCode == 'ru'
            ? 'Не удалось сохранить'
            : 'Could not save',
        message: error.toString(),
        actions: [
          AppDialogAction('OK', onPressed: () => Navigator.pop(context)),
        ],
      );
    }
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
          onTap: () {
            _c.minimize();
            Navigator.of(context).maybePop();
          },
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
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _c.laps.isEmpty
              ? (_c.running ? 'Running' : 'Paused')
              : 'Lap ${_c.laps.length + 1} · ${AerobicSessionController.fmt(_c.currentLapSeconds)}',
          style: TextStyle(fontSize: 14, color: c.textSecondary),
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
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
            Text(
              AerobicSessionController.fmt(_c.laps[i]),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: c.textPrimary,
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
          ),
        ),
      ),
    ),
  );
}
