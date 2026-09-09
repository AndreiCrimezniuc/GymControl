import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gymboss/data/repositories/exercises_repository.dart';
import 'package:gymboss/data/repositories/ranking_repository.dart';
import 'package:gymboss/data/repositories/sessions_repository.dart';
import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/domain/models/exercises/exercise_catalog.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';
import 'package:gymboss/domain/models/training/training_prescription.dart';
import 'package:gymboss/l10n/app_localizations.dart';
import 'package:gymboss/ui/menu_options_list/exercises/widgets/exercises.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/subscription/pro_controller.dart';
import 'package:gymboss/ui/core/units/units_controller.dart';
import 'package:gymboss/ui/core/training/training_preferences_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_dialog.dart';
import 'package:gymboss/ui/core/ui/widgets/app_page.dart';
import 'package:gymboss/ui/core/ui/widgets/pressable.dart';
import 'package:gymboss/ui/menu_options_list/exercises/widgets/exercise_mannequin.dart';
import 'package:gymboss/ui/menu_options_list/exercises/widgets/muscle_illustration.dart';
import 'package:gymboss/ui/menu_options_list/workouts/widgets/workout_editor.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/workout_session_controller.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/aerobic_runner.dart';
import 'package:gymboss/ui/menu_options_list/workouts/widgets/workout_runner.dart';
import 'package:gymboss/ui/menu_options_list/workouts/widgets/completed_session_editor.dart';
import 'package:gymboss/ui/subscription/paywall_screen.dart';

const _modes = ['normal', 'deload'];

class WorkoutDetailScreen extends StatefulWidget {
  final String id;
  final WorkoutsRepository repo;
  final ExercisesRepository exercises;
  const WorkoutDetailScreen({
    super.key,
    required this.id,
    required this.repo,
    required this.exercises,
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _LaunchChoice extends StatelessWidget {
  final String label;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  const _LaunchChoice({
    required this.label,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 46),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.accent.withValues(alpha: .14) : c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? c.accent : c.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  Text(
                    detail,
                    style: TextStyle(fontSize: 11, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle,
              size: 20,
              color: selected ? c.accent : c.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  Workout? _w;
  WorkoutStats? _stats;
  bool _loading = true;
  String? _error;
  String _difficulty = 'normal'; // 'normal' | 'deload'
  EnergyMode _energy = EnergyMode.full;
  bool _suggesting = false;

  String _difficultyLabel(String value) {
    final russian = Localizations.localeOf(context).languageCode == 'ru';
    return switch (value) {
      'deload' => russian ? 'Разгрузка' : 'Deload',
      _ => russian ? 'Обычная' : 'Normal',
    };
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final w = await widget.repo.get(widget.id);
      final s = await widget.repo.stats(widget.id);
      if (mounted) {
        setState(() {
          _w = w;
          _stats = s;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _launch() async {
    final l = AppLocalizations.of(context);
    final session = context.read<WorkoutSessionController>();
    final aerobic = context.read<AerobicSessionController>();
    final sessions = SessionsRepository(
      client: context.read<AuthenticatedClient>(),
    );
    final ranking = RankingRepository(
      client: context.read<AuthenticatedClient>(),
    );
    if ((session.isActive && !session.isFinished) || aerobic.isActive) {
      final replace = await showAppDialog<bool>(
        context,
        title: l.startNewWorkoutQuestion,
        message: l.activeWorkoutBody,
        actions: [
          AppDialogAction(
            l.resumeActive,
            onPressed: () => Navigator.pop(context, false),
          ),
          AppDialogAction(
            l.startNew,
            isDestructive: true,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      );
      if (!mounted || replace == null) return;
      if (!replace) {
        if (aerobic.isActive) {
          aerobic.resume();
          await Navigator.of(context, rootNavigator: true).push(
            CupertinoPageRoute(
              builder: (_) => AerobicRunnerScreen(
                workoutId: aerobic.workoutId,
                workoutName: aerobic.workoutName,
                repo: widget.repo,
                sessions: sessions,
              ),
            ),
          );
        } else {
          session.resume();
          await Navigator.of(context, rootNavigator: true).push(
            CupertinoPageRoute(builder: (_) => const WorkoutRunnerScreen()),
          );
        }
        return;
      }
      if (aerobic.isActive) await aerobic.clear();
      if (session.isActive) await session.discard();
      if (!mounted) return;
    }
    // Aerobic workouts use the stopwatch/laps runner instead of the set logger.
    if (_w!.type == 'aerobic') {
      await Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(
          builder: (_) => AerobicRunnerScreen(
            workoutId: _w!.id,
            workoutName: _w!.name,
            repo: widget.repo,
            sessions: sessions,
          ),
        ),
      );
      if (mounted) _load();
      return;
    }
    // Detail cards may have been rendered from the compact list cache. Reload
    // the full plan at the launch boundary so no workout can start empty.
    final fullWorkout = await widget.repo.get(_w!.id, forceRefresh: true);
    if (!mounted) return;
    final configured = await _configureExercises(
      fullWorkout.forEnergy(_energy),
    );
    if (!mounted || configured == null) return;
    session.start(
      workout: configured,
      difficulty: _difficulty,
      deloadFactor: context.read<TrainingPreferencesController>().deloadFactor,
      exercises: widget.exercises,
      ranking: ranking,
      sessions: sessions,
      workouts: widget.repo,
      units: context.read<UnitsController>(),
    );
    await Navigator.of(
      context,
      rootNavigator: true,
    ).push(CupertinoPageRoute(builder: (_) => const WorkoutRunnerScreen()));
    if (mounted) _load();
  }

  Future<Workout?> _configureExercises(Workout workout) async {
    final l = AppLocalizations.of(context);
    final optional = workout.exercises.where((e) => e.isOptional).toList();
    final groups = <String, List<WorkoutExercise>>{};
    for (final exercise in workout.exercises) {
      final id = exercise.alternativeGroupId;
      if (id != null) (groups[id] ??= []).add(exercise);
    }
    groups.removeWhere((_, choices) => choices.length < 2);
    if (optional.isEmpty && groups.isEmpty) return workout;

    final included = {for (final exercise in optional) exercise.exerciseId};
    final selected = {
      for (final entry in groups.entries)
        entry.key: entry.value.first.exerciseId,
    };
    final accepted = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final c = context.colors;
          return Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            decoration: BoxDecoration(
              color: c.bg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l.configureWorkout,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.configureWorkoutBody,
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  for (final exercise in optional)
                    _LaunchChoice(
                      label: exercise.name,
                      detail: l.optional,
                      selected: included.contains(exercise.exerciseId),
                      onTap: () => setSheetState(
                        () => included.contains(exercise.exerciseId)
                            ? included.remove(exercise.exerciseId)
                            : included.add(exercise.exerciseId),
                      ),
                    ),
                  for (final entry in groups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Text(
                        l.chooseOne,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .8,
                          color: c.accentSecondary,
                        ),
                      ),
                    ),
                    for (final exercise in entry.value)
                      _LaunchChoice(
                        label: exercise.name,
                        detail: l.alternative,
                        selected: selected[entry.key] == exercise.exerciseId,
                        onTap: () => setSheetState(
                          () => selected[entry.key] = exercise.exerciseId,
                        ),
                      ),
                  ],
                  const SizedBox(height: 10),
                  CupertinoButton.filled(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: Text(l.startWorkout),
                  ),
                  CupertinoButton(
                    onPressed: () => Navigator.pop(sheetContext, false),
                    child: Text(l.cancel),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (accepted != true) return null;
    final chosenAlternativeIds = selected.values.toSet();
    return workout.copyWith(
      exercises: workout.exercises.where((exercise) {
        if (exercise.isOptional && !included.contains(exercise.exerciseId)) {
          return false;
        }
        if (exercise.alternativeGroupId != null &&
            groups.containsKey(exercise.alternativeGroupId)) {
          return chosenAlternativeIds.contains(exercise.exerciseId);
        }
        return true;
      }).toList(),
    );
  }

  Future<void> _saveCopy() async {
    final l = AppLocalizations.of(context);
    try {
      await widget.repo.copy(_w!.id);
      if (!mounted) return;
      await showAppDialog<void>(
        context,
        title: l.saved,
        message: l.copySavedBody,
        actions: [
          AppDialogAction(
            'OK',
            isDefault: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      _toast(l.couldNotSaveCopy);
    }
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context, rootNavigator: true).push<bool>(
      CupertinoPageRoute(
        builder: (_) => WorkoutEditorScreen(
          repo: widget.repo,
          exercises: widget.exercises,
          existing: _w,
        ),
      ),
    );
    if (saved == true) _load();
  }

  void _openRunDetail(WorkoutRunPoint run) {
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(
        builder: (_) => _RunDetailScreen(
          workoutId: _w!.id,
          date: run.date,
          difficulty: run.difficulty,
          sessionId: run.sessionId,
          repo: widget.repo,
        ),
      ),
    );
  }

  void _openHistory() {
    final history = _stats?.history ?? const <WorkoutRunPoint>[];
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(
        builder: (_) =>
            _WorkoutHistoryScreen(history: history, onOpen: _openRunDetail),
      ),
    );
  }

  void _openExerciseStats(WorkoutExercise ex) {
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(
        builder: (_) => ExerciseDetailScreen(
          entry: ExerciseCatalogItem(
            id: ex.exerciseId,
            name: ex.name,
            muscleGroup: ex.muscleGroup,
            equipment: '',
            category: '',
            level: '',
            force: '',
            imageUrl: ex.imageUrl,
            imageUrl2: '',
            instructions: '',
          ),
          repo: widget.exercises,
        ),
      ),
    );
  }

  Future<void> _togglePublic() async {
    final w = _w!;
    try {
      await widget.repo.setVisibility(w.id, w.isPublic ? 'private' : 'public');
      _load();
    } catch (_) {
      _toast('Could not change visibility');
    }
  }

  Future<void> _requestAiSuggestion() async {
    final pro = context.read<ProController>();
    final known = pro.isKnown || await pro.load(force: true);
    if (!mounted) return;
    if (!known) {
      _toast('Could not verify Pro access');
      return;
    }
    if (!pro.isPro) {
      await Navigator.of(
        context,
        rootNavigator: true,
      ).push(CupertinoPageRoute(builder: (_) => const PaywallScreen()));
      return;
    }
    setState(() => _suggesting = true);
    try {
      final suggestion = await widget.repo.requestAiSuggestion(widget.id);
      if (mounted) _showSuggestion(suggestion);
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      final l10n = AppLocalizations.of(context);
      await showAppDialog<void>(
        context,
        title: l10n.aiReviewStagedTitle,
        message: message.contains('provider is not configured')
            ? l10n.aiReviewStagedBody
            : l10n.aiReviewFailed,
        actions: [
          AppDialogAction('OK', onPressed: () => Navigator.pop(context)),
        ],
      );
    } finally {
      if (mounted) setState(() => _suggesting = false);
    }
  }

  void _showSuggestion(WorkoutSuggestion suggestion) {
    final c = context.colors;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * .82,
        ),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'AI TRAINING REVIEW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: c.accent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                suggestion.summary,
                style: TextStyle(
                  fontSize: 19,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              _SuggestionSection(
                title: AppLocalizations.of(context).whatWorks,
                items: suggestion.highlights,
              ),
              _SuggestionSection(
                title: AppLocalizations.of(context).watch,
                items: suggestion.cautions,
              ),
              _SuggestionSection(
                title: AppLocalizations.of(context).nextFocus,
                items: suggestion.nextFocus,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final ok = await showAppDialog<bool>(
      context,
      title: AppLocalizations.of(context).deleteWorkoutQuestion,
      message: '“${_w!.name}” will be permanently removed.',
      actions: [
        AppDialogAction(
          'Cancel',
          onPressed: () => Navigator.pop(context, false),
        ),
        AppDialogAction(
          'Delete',
          isDestructive: true,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
    if (ok != true) return;
    try {
      await widget.repo.delete(_w!.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      _toast('Could not delete');
    }
  }

  void _menu() {
    final w = _w!;
    showAppActionSheet(
      context,
      actions: [
        AppSheetAction(
          'Edit',
          onPressed: () {
            Navigator.pop(context);
            _edit();
          },
        ),
        AppSheetAction(
          w.isPublic ? 'Make private' : 'Publish to library',
          onPressed: () {
            Navigator.pop(context);
            _togglePublic();
          },
        ),
        AppSheetAction(
          'Delete',
          isDestructive: true,
          onPressed: () {
            Navigator.pop(context);
            _delete();
          },
        ),
      ],
    );
  }

  void _toast(String msg) {
    showAppDialog<void>(
      context,
      title: msg,
      actions: [
        AppDialogAction(
          'OK',
          isDefault: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final w = _w;
    return AppPage(
      title: w?.name ?? 'Workout',
      actions: [
        if (w != null && w.owned)
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(44, 44),
            onPressed: _menu,
            child: Icon(
              CupertinoIcons.ellipsis,
              size: 22,
              color: c.textPrimary,
            ),
          ),
      ],
      body: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : _error != null || w == null
          ? Center(
              child: Text(
                'Could not load',
                style: TextStyle(color: c.textSecondary),
              ),
            )
          : _buildBody(c, w),
    );
  }

  Widget _buildBody(AppColors c, Workout w) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              if (w.comment.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    w.comment,
                    style: TextStyle(
                      fontSize: 13,
                      color: c.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              _statsRow(c, w),
              const SizedBox(height: 16),
              // Normal/Deload + planned volume only apply to strength workouts.
              if (w.type != 'aerobic') ...[
                _difficultyPicker(c),
                const SizedBox(height: 8),
                if (_difficulty != 'deload') ...[
                  _energyPicker(c),
                  const SizedBox(height: 8),
                ],
                _potentialVolumeLine(c),
                const SizedBox(height: 16),
              ],
              _AiSuggestCard(loading: _suggesting, onTap: _requestAiSuggestion),
              const SizedBox(height: 16),
              Row(
                children: [
                  const _SectionLabel('Exercises'),
                  const Spacer(),
                  Text(
                    '${w.exercises.length} exercise${w.exercises.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...w.exercises.asMap().entries.map(
                (e) => _ExerciseBlock(
                  index: e.key + 1,
                  exercise: e.value,
                  deloadScale: _difficulty == 'deload'
                      ? context
                            .watch<TrainingPreferencesController>()
                            .deloadFactor
                      : 1.0,
                  onTap: () => _openExerciseStats(e.value),
                ),
              ),
              if (_stats != null && _stats!.history.isNotEmpty) ...[
                const SizedBox(height: 8),
                _SectionLabel('History'),
                const SizedBox(height: 8),
                Pressable(
                  onTap: _openHistory,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: c.iconBg,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            CupertinoIcons.calendar,
                            size: 19,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Workout calendar',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: c.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_stats!.history.length} completed session${_stats!.history.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: c.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 15,
                          color: c.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
          child: w.owned ? _launchButton(c) : _saveCopyButton(c),
        ),
      ],
    );
  }

  Widget _statsRow(AppColors c, Workout w) => Row(
    children: [
      _StatChip(
        icon: CupertinoIcons.chart_bar_alt_fill,
        label: AppLocalizations.of(context).volume,
        value: context.units.formatVolume(
          _stats?.potentialVolume['medium'] ?? 0,
        ),
      ),
      const SizedBox(width: 10),
      _StatChip(
        icon: CupertinoIcons.clock_fill,
        label: AppLocalizations.of(context).averageTime,
        value: _formatDuration(_stats?.averageDurationSeconds ?? 0),
      ),
      const SizedBox(width: 10),
      _StatChip(
        icon: CupertinoIcons.checkmark_alt_circle_fill,
        label: AppLocalizations.of(context).done,
        value: '${_stats?.timesPerformed ?? w.timesPerformed}x',
      ),
    ],
  );

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '—';
    final minutes = (seconds / 60).round();
    return minutes >= 60 ? '${minutes ~/ 60}h ${minutes % 60}m' : '${minutes}m';
  }

  Widget _difficultyPicker(
    AppColors c,
  ) => CupertinoSlidingSegmentedControl<String>(
    groupValue: _difficulty,
    backgroundColor: c.iconBg,
    thumbColor: c.accent,
    onValueChanged: (v) {
      HapticFeedback.selectionClick();
      setState(() => _difficulty = v ?? 'normal');
    },
    children: {
      for (final d in _modes)
        d: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Text(
            d == 'deload'
                ? '${_difficultyLabel(d)} (${(context.watch<TrainingPreferencesController>().deloadFactor * 100).round()}%)'
                : _difficultyLabel(d),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _difficulty == d ? c.textOnAccent : c.textSecondary,
            ),
          ),
        ),
    },
  );

  Widget _energyPicker(AppColors colors) {
    final russian = Localizations.localeOf(context).languageCode == 'ru';
    final labels = russian
        ? const {EnergyMode.full: 'Полная', EnergyMode.low: 'Мало сил'}
        : const {EnergyMode.full: 'Full', EnergyMode.low: 'Low energy'};
    return CupertinoSlidingSegmentedControl<EnergyMode>(
      groupValue: _energy,
      backgroundColor: colors.iconBg,
      thumbColor: colors.card,
      onValueChanged: (value) {
        HapticFeedback.selectionClick();
        setState(() => _energy = value ?? EnergyMode.full);
      },
      children: {
        for (final mode in EnergyMode.values)
          mode: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
            child: Text(
              labels[mode]!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: mode == _energy
                    ? colors.textPrimary
                    : colors.textSecondary,
              ),
            ),
          ),
      },
    );
  }

  Widget _potentialVolumeLine(AppColors c) {
    // The stored plan lives under the legacy 'medium' key; Deload scales it.
    final base = _stats?.potentialVolume['medium'] ?? 0;
    final vol = _difficulty == 'deload'
        ? base * context.watch<TrainingPreferencesController>().deloadFactor
        : base;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          CupertinoIcons.chart_bar_alt_fill,
          size: 14,
          color: c.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          'Potential volume: ${context.units.formatVolume(vol)}',
          style: TextStyle(fontSize: 12, color: c.textSecondary),
        ),
      ],
    );
  }

  Widget _launchButton(AppColors c) => Pressable(
    onTap: _launch,
    child: Container(
      height: 54,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: c.accent,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
        shadows: [
          BoxShadow(
            color: c.accent.withValues(
              alpha: c.usesLightForeground ? 0.28 : 0.20,
            ),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.play_arrow_solid,
            size: 18,
            color: c.textOnAccent,
          ),
          const SizedBox(width: 8),
          Text(
            _energy == EnergyMode.full
                ? 'START WORKOUT · ${_difficultyLabel(_difficulty).toUpperCase()}'
                : 'START · LOW ENERGY',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: c.textOnAccent,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _saveCopyButton(AppColors c) => Pressable(
    onTap: _saveCopy,
    child: Container(
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.accent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.plus_square_on_square,
            size: 18,
            color: c.textOnAccent,
          ),
          const SizedBox(width: 8),
          Text(
            'SAVE A COPY',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: c.textOnAccent,
            ),
          ),
        ],
      ),
    ),
  );
}

class _AiSuggestCard extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _AiSuggestCard({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    return Pressable(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.invBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.accent.withValues(alpha: .48)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: .20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: loading
                  ? const CupertinoActivityIndicator(radius: 9)
                  : Icon(CupertinoIcons.sparkles, size: 19, color: c.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.aiSuggest,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .9,
                          color: c.invText,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: c.accent,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'PRO',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: c.textOnAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.aiReviewPlan,
                    style: TextStyle(
                      fontSize: 11,
                      color: c.invText.withValues(alpha: .62),
                    ),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.arrow_up_right, size: 16, color: c.accent),
          ],
        ),
      ),
    );
  }
}

class _SuggestionSection extends StatelessWidget {
  final String title;
  final List<String> items;
  const _SuggestionSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: c.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ExerciseBlock extends StatelessWidget {
  final int index;
  final WorkoutExercise exercise;
  final double deloadScale; // 1.0 = Normal, <1 = Deload preview
  final VoidCallback onTap;
  const _ExerciseBlock({
    required this.index,
    required this.exercise,
    required this.deloadScale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final units = context.units;
    final medium = exercise.setsFor('medium');
    final sets = medium.isNotEmpty ? medium : exercise.sets;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: ExerciseVisual(
                    name: exercise.name,
                    muscleGroup: exercise.muscleGroup,
                    category: '',
                    imageUrl: exercise.imageUrl,
                    imageUrl2: exercise.imageUrl2,
                    radius: 10,
                    figurePadding: 4,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 25,
                            height: 25,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: c.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$index',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: c.accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              exercise.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rest ${exercise.restSeconds}s',
                        style: TextStyle(fontSize: 11, color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (sets.isNotEmpty) ...[
              const SizedBox(height: 10),
              Column(
                children: sets.asMap().entries.map((entry) {
                  final set = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: c.iconBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${entry.key + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: c.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (set.weightKg > 0)
                          Text(
                            '${units.format(set.weightKg * deloadScale)} ${units.label}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                            ),
                          )
                        else
                          Text(
                            'Bodyweight',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.textSecondary,
                            ),
                          ),
                        const Spacer(),
                        Text(
                          '${set.reps} reps',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            if (exercise.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                exercise.comment,
                style: TextStyle(
                  fontSize: 12,
                  color: c.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: c.accent),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 0.5,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: context.colors.textPrimary,
    ),
  );
}

const _runDiffLabels = {'easy': 'Easy', 'medium': 'Medium', 'hard': 'Hard'};

class _WorkoutHistoryScreen extends StatefulWidget {
  final List<WorkoutRunPoint> history;
  final ValueChanged<WorkoutRunPoint> onOpen;

  const _WorkoutHistoryScreen({required this.history, required this.onOpen});

  @override
  State<_WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<_WorkoutHistoryScreen> {
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  late DateTime _month;
  late final Map<String, WorkoutRunPoint> _sessionsByDate;

  @override
  void initState() {
    super.initState();
    _sessionsByDate = {};
    for (final session in widget.history) {
      _sessionsByDate.putIfAbsent(session.date, () => session);
    }
    final latest = widget.history
        .map((session) => DateTime.tryParse(session.date))
        .whereType<DateTime>()
        .fold<DateTime?>(
          null,
          (current, date) =>
              current == null || date.isAfter(current) ? date : current,
        );
    final initial = latest ?? DateTime.now();
    _month = DateTime(initial.year, initial.month);
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  void _moveMonth(int offset) {
    HapticFeedback.selectionClick();
    setState(() => _month = DateTime(_month.year, _month.month + offset));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final firstDay = DateTime(_month.year, _month.month);
    final dayCount = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = firstDay.weekday - DateTime.monday;
    final cellCount = ((leading + dayCount + 6) ~/ 7) * 7;

    return AppPage(
      title: AppLocalizations.of(context).workoutHistory,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 44),
                      onPressed: () => _moveMonth(-1),
                      child: Icon(
                        CupertinoIcons.chevron_left,
                        size: 18,
                        color: c.textPrimary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${_monthNames[_month.month - 1]} ${_month.year}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 44),
                      onPressed: () => _moveMonth(1),
                      child: Icon(
                        CupertinoIcons.chevron_right,
                        size: 18,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: _weekdays
                      .map(
                        (day) => Expanded(
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                  ),
                  itemCount: cellCount,
                  itemBuilder: (context, index) {
                    final day = index - leading + 1;
                    if (day < 1 || day > dayCount) {
                      return const SizedBox.shrink();
                    }
                    final date = DateTime(_month.year, _month.month, day);
                    final session = _sessionsByDate[_dateKey(date)];
                    return _CalendarDay(
                      day: day,
                      session: session,
                      onTap: session == null
                          ? null
                          : () => widget.onOpen(session),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: c.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Tap a marked day to view the workout',
                style: TextStyle(fontSize: 12, color: c.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  final int day;
  final WorkoutRunPoint? session;
  final VoidCallback? onTap;

  const _CalendarDay({required this.day, this.session, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final completed = session != null;
    return Semantics(
      button: completed,
      label: completed ? 'Workout on ${session!.date}' : '$day',
      child: Pressable(
        onTap: onTap,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: completed ? c.accent : const Color(0x00000000),
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: completed ? FontWeight.w800 : FontWeight.w500,
                  color: completed ? c.textOnAccent : c.textPrimary,
                ),
              ),
              if (completed)
                Positioned(
                  bottom: 5,
                  child: Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: c.textOnAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows what a past session actually was: the sets logged on that date for the
/// workout's exercises, grouped by exercise, with total working volume.
class _RunDetailScreen extends StatefulWidget {
  final String workoutId;
  final String date;
  final String difficulty;
  final String sessionId;
  final WorkoutsRepository repo;
  const _RunDetailScreen({
    required this.workoutId,
    required this.date,
    required this.difficulty,
    required this.sessionId,
    required this.repo,
  });

  @override
  State<_RunDetailScreen> createState() => _RunDetailScreenState();
}

class _RunDetailScreenState extends State<_RunDetailScreen> {
  List<PerformedExerciseLog>? _items;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await widget.repo.runDetail(
        widget.workoutId,
        widget.date,
        sessionId: widget.sessionId,
      );
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final units = context.units;
    final items = _items ?? [];
    final totalVol = items.fold<double>(0, (a, e) => a + e.volumeKg);
    return AppPage(
      title: widget.date,
      actions: [
        if (!_loading && items.isNotEmpty && widget.sessionId.isNotEmpty)
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _edit,
            child: const Icon(CupertinoIcons.pencil, size: 20),
          ),
      ],
      body: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : items.isEmpty
          ? Center(
              child: Text(
                'No logged sets for this session',
                style: TextStyle(color: c.textSecondary),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                Row(
                  children: [
                    _summaryTile(
                      c,
                      _runDiffLabels[widget.difficulty] ?? widget.difficulty,
                      'DIFFICULTY',
                    ),
                    const SizedBox(width: 10),
                    _summaryTile(c, units.formatVolume(totalVol), 'VOLUME'),
                  ],
                ),
                const SizedBox(height: 16),
                ...items.map((e) => _exerciseTile(c, units, e)),
              ],
            ),
    );
  }

  Future<void> _edit() async {
    final items = _items;
    if (items == null || items.isEmpty) return;
    final changed = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        builder: (_) => CompletedSessionEditor(
          workoutId: widget.workoutId,
          sessionId: widget.sessionId,
          date: widget.date,
          difficulty: widget.difficulty,
          exercises: items,
          repository: widget.repo,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _loading = true);
      try {
        final fresh = await widget.repo.runDetail(
          widget.workoutId,
          widget.date,
          sessionId: widget.sessionId,
          forceRefresh: true,
        );
        if (mounted) setState(() => _items = fresh);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Widget _summaryTile(AppColors c, String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10, color: c.textSecondary)),
        ],
      ),
    ),
  );

  Widget _exerciseTile(AppColors c, dynamic units, PerformedExerciseLog e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: ExerciseMannequin(
                  pattern: patternFor(
                    name: e.name,
                    muscle: e.muscleGroup,
                    equipment: '',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: e.sets.map<Widget>((s) {
              final warm = s.setType == 'warmup';
              final fail = s.setType == 'failure';
              final prefix = warm ? 'W ' : (fail ? 'F ' : '');
              const progLabels = {
                'weight': 'WT',
                'amplitude': 'AMP',
                'efficiency': 'EFF',
                'meo': 'MEO',
                'dropset': 'DROP',
              };
              final progSuffix = progLabels[s.progression] != null
                  ? '  · ${progLabels[s.progression]}'
                  : '';
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: warm
                      ? c.iconBg
                      : (fail ? c.accent.withValues(alpha: 0.12) : c.iconBg),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$prefix${units.format(s.weightKg)}${units.label} × ${s.reps}$progSuffix',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: warm
                        ? c.textSecondary
                        : (fail ? c.accent : c.textPrimary),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
