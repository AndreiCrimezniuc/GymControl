import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymboss/data/repositories/ranking_repository.dart';
import 'package:gymboss/data/repositories/sessions_repository.dart';
import 'package:gymboss/data/repositories/programs_repository.dart';
import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/domain/models/ranking/rank_data.dart';
import 'package:gymboss/domain/models/streak/streak_data.dart';
import 'package:gymboss/domain/models/programs/training_program.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/theme/app_design.dart';
import 'package:gymboss/ui/core/ui/widgets/app_scaffold.dart';
import 'package:gymboss/ui/core/ui/widgets/app_glass_surface.dart';
import 'package:gymboss/ui/core/ui/widgets/pressable.dart';
import 'package:gymboss/ui/core/ui/widgets/theme_toggle.dart';
import 'package:gymboss/ui/menu_options_list/exercises/widgets/exercises.dart';
import 'package:gymboss/ui/menu_options_list/ranking/widgets/ranking.dart';
import 'package:gymboss/ui/menu_options_list/settings/widgets/settings.dart';
import 'package:gymboss/ui/menu_options_list/statistics/widgets/statistics.dart';
import 'package:gymboss/ui/menu_options_list/workouts/widgets/workouts.dart';
import 'package:gymboss/ui/menu_options_list/workouts/widgets/workout_runner.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/aerobic_runner.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/workout_session_controller.dart';
import 'package:gymboss/l10n/app_localizations.dart';

class MenuOptions extends StatefulWidget {
  const MenuOptions({super.key});

  @override
  State<MenuOptions> createState() => _MenuOptionsState();
}

class _MenuOptionsState extends State<MenuOptions> {
  static const _weightPromptKey = 'weight_last_asked';
  static const _weightPromptInterval = Duration(days: 365);
  late final SessionsRepository _sessions;
  late final RankingRepository _ranking;
  late final ProgramsRepository _programs;
  late final WorkoutsRepository _workoutsRepo;
  StreakData _streak = StreakData.empty;
  UserRanks? _passport;
  int _workouts = 0;
  List<TrainingProgram> _programItems = const [];

  @override
  void initState() {
    super.initState();
    final client = context.read<AuthenticatedClient>();
    _sessions = SessionsRepository(client: client);
    _ranking = RankingRepository(client: client);
    _programs = ProgramsRepository(client: client);
    _workoutsRepo = WorkoutsRepository(client: client);
    _loadStreak();
    _loadPassport();
    _loadWorkouts();
    _loadPrograms();
  }

  Future<void> _loadWorkouts() async {
    try {
      final w = await _workoutsRepo.listOwned();
      if (mounted) setState(() => _workouts = w.length);
    } catch (_) {}
  }

  Future<void> _loadPassport() async {
    try {
      final passport = await _ranking.getUserRanks();
      if (mounted) setState(() => _passport = passport);
    } catch (_) {}
  }

  Future<void> _loadPrograms() async {
    try {
      final programs = await _programs.list();
      if (mounted) setState(() => _programItems = programs);
    } catch (_) {}
  }

  Future<void> _loadStreak() async {
    try {
      final data = await _sessions.getStreakData();
      if (mounted) {
        setState(() => _streak = data);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _streak = StreakData.empty);
      }
    }
    _checkWeightPrompt();
  }

  Future<void> _checkWeightPrompt() async {
    try {
      // Prefer the server timestamp whenever it is reachable so an annual
      // prompt answered on a second device cannot briefly reappear here.
      // Offline still falls back to the durable profile snapshot.
      final profile = await _ranking.getProfile(forceRefresh: true);
      if (!mounted) return;
      if (profile.dontAskWeight) return;

      final prefs = await SharedPreferences.getInstance();
      final legacyMs = prefs.getInt(_weightPromptKey);
      final lastCheck =
          profile.weightPromptedAt ??
          (legacyMs == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(legacyMs));
      if (lastCheck != null &&
          DateTime.now().difference(lastCheck) < _weightPromptInterval) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      if (profile.weightKg == null || profile.heightCm == null) {
        _showFirstTimeWeightSheet();
      } else {
        _showAnnualWeightPopup(profile);
      }
    } catch (_) {}
  }

  Future<void> _markWeightPrompted() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_weightPromptKey, now.millisecondsSinceEpoch);
    await _ranking.updateProfile(weightPromptedAt: now);
  }

  void _showFirstTimeWeightSheet() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => _FirstTimeWeightSheet(
        ranking: _ranking,
        onDismiss: _markWeightPrompted,
      ),
    );
  }

  void _showAnnualWeightPopup(RankProfile profile) {
    showCupertinoDialog<void>(
      context: context,
      builder: (_) => _AnnualWeightDialog(
        ranking: _ranking,
        profile: profile,
        onDismiss: _markWeightPrompted,
      ),
    );
  }

  void _push(Widget page) {
    Navigator.of(context).push(CupertinoPageRoute<void>(builder: (_) => page));
  }

  Future<void> _pushAndReload(Widget page) async {
    await Navigator.of(
      context,
    ).push(CupertinoPageRoute<void>(builder: (_) => page));
    _loadWorkouts();
    _loadPrograms();
    _loadPassport();
    _loadStreak();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final chain = _streak.currentStreakWorkouts;
    final strengthSession = context.watch<WorkoutSessionController>();
    final aerobicSession = context.watch<AerobicSessionController>();
    final nextMilestone = _streak.nextMilestoneWorkouts;
    final nextMilestoneLabel =
        '$nextMilestone ${_workoutWord(context, nextMilestone)}';

    return AppScaffold(
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 2,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          children: [
            Row(
              children: [
                Expanded(
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.5,
                    child: Text(
                      'GymControl',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.7,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const ThemeToggle(),
              ],
            ),
            const SizedBox(height: 22),
            _TodayCommandCard(
              strengthSession: strengthSession,
              aerobicSession: aerobicSession,
              nextScheduled: _nextScheduledWorkout(),
              passport: _passport,
              onOpenWorkouts: () => _pushAndReload(const Workouts()),
              onOpenPassport: () => _push(const Ranking()),
              onResumeStrength: () {
                strengthSession.resume();
                _push(const WorkoutRunnerScreen());
              },
              onResumeAerobic: () {
                aerobicSession.resume();
                _push(
                  AerobicRunnerScreen(
                    workoutId: aerobicSession.workoutId,
                    workoutName: aerobicSession.workoutName,
                    repo: _workoutsRepo,
                    sessions: _sessions,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            AppGlassSurface(
              onTap: () => _showYearCalendar(context),
              child: _StatStrip(
                segments: [
                  ('$chain', l10n.weekStreak),
                  (nextMilestoneLabel, l10n.nextGoal),
                  ('$_workouts', l10n.routines),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Text(
              l10n.explore,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            AppGlassSurface(
              radius: AppDesign.radiusCard,
              blur: true,
              child: Column(
                children: [
                  _MenuRow(
                    icon: Icons.view_list_rounded,
                    title: l10n.workouts,
                    subtitle: l10n.workoutsSubtitle,
                    onTap: () => _pushAndReload(const Workouts()),
                  ),
                  _MenuRow(
                    icon: Icons.insights_rounded,
                    title: l10n.progress,
                    subtitle: l10n.progressSubtitle,
                    onTap: () => _push(const Statistics()),
                  ),
                  _MenuRow(
                    icon: Icons.military_tech_rounded,
                    title: l10n.strengthPassport,
                    subtitle: l10n.strengthPassportSubtitle,
                    onTap: () => _push(const Ranking()),
                  ),
                  _MenuRow(
                    icon: Icons.fitness_center_rounded,
                    title: l10n.exercises,
                    subtitle: l10n.exercisesSubtitle,
                    onTap: () => _push(const Exercises()),
                  ),
                  _MenuRow(
                    icon: Icons.settings_rounded,
                    title: l10n.settingsTitle,
                    subtitle: l10n.settingsSubtitle,
                    onTap: () => _push(const Settings()),
                    last: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _StartButton(onTap: () => _pushAndReload(const Workouts())),
            if (_passport != null) ...[
              const SizedBox(height: 20),
              _TrainingBriefCard(
                ranks: _passport!,
                onTap: () => _push(const Ranking()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showYearCalendar(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => _YearCalendarSheet(streak: _streak),
    );
  }

  ScheduledWorkout? _nextScheduledWorkout() {
    final now = DateTime.now();
    ScheduledWorkout? next;
    for (final program in _programItems) {
      final candidate = program.nextWorkout(now);
      if (candidate == null) continue;
      if (next == null || candidate.date!.isBefore(next.date!)) {
        next = candidate;
      }
    }
    return next;
  }
}

class _TodayCommandCard extends StatelessWidget {
  final WorkoutSessionController strengthSession;
  final AerobicSessionController aerobicSession;
  final ScheduledWorkout? nextScheduled;
  final UserRanks? passport;
  final VoidCallback onOpenWorkouts;
  final VoidCallback onOpenPassport;
  final VoidCallback onResumeStrength;
  final VoidCallback onResumeAerobic;

  const _TodayCommandCard({
    required this.strengthSession,
    required this.aerobicSession,
    required this.nextScheduled,
    required this.passport,
    required this.onOpenWorkouts,
    required this.onOpenPassport,
    required this.onResumeStrength,
    required this.onResumeAerobic,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final russian = Localizations.localeOf(context).languageCode == 'ru';
    final activeStrength =
        strengthSession.isActive && !strengthSession.isFinished;
    final activeAerobic = aerobicSession.isActive;
    final active = activeStrength || activeAerobic;
    final action = activeStrength
        ? onResumeStrength
        : activeAerobic
        ? onResumeAerobic
        : onOpenWorkouts;
    final title = activeStrength
        ? strengthSession.workout?.name ?? ''
        : activeAerobic
        ? aerobicSession.workoutName
        : nextScheduled?.workoutName ??
              (russian ? 'Сделайте день своим' : 'Make the day yours');
    final detail = activeStrength
        ? '${strengthSession.doneSets}/${strengthSession.totalSets} ${russian ? 'подходов' : 'sets'} · ${strengthSession.elapsed}'
        : activeAerobic
        ? '${aerobicSession.running ? (russian ? 'идёт' : 'running') : (russian ? 'пауза' : 'paused')} · ${AerobicSessionController.fmt(aerobicSession.totalSeconds)}'
        : nextScheduled == null
        ? (russian
              ? 'Начните тренировку без лишнего планирования.'
              : 'Start a session without extra planning.')
        : _dateLabel(nextScheduled!, russian);
    final eyebrow = active
        ? (russian ? 'АКТИВНАЯ ТРЕНИРОВКА' : 'ACTIVE WORKOUT')
        : nextScheduled == null
        ? (russian ? 'СЕГОДНЯ' : 'TODAY')
        : (russian ? 'СЛЕДУЮЩАЯ ПО ПЛАНУ' : 'NEXT ON PLAN');
    final actionLabel = active
        ? (russian ? 'Продолжить' : 'Resume')
        : nextScheduled == null
        ? (russian ? 'Выбрать тренировку' : 'Choose workout')
        : (russian ? 'Открыть тренировки' : 'Open workouts');
    final ranked = passport?.exerciseRanks.length ?? 0;
    final passportLabel = ranked == 0
        ? (russian ? 'Паспорт: первая запись' : 'Passport: first entry')
        : ranked < 3
        ? (russian
              ? 'Паспорт: калибровка $ranked/3'
              : 'Passport: calibration $ranked/3')
        : (russian
              ? 'Паспорт: класс ${passport!.overallRank ?? '—'}'
              : 'Passport: class ${passport!.overallRank ?? '—'}');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: c.invBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.accent.withValues(alpha: .4)),
        boxShadow: c.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                eyebrow,
                style: TextStyle(
                  color: c.accent,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
              const Spacer(),
              Pressable(
                semanticLabel: passportLabel,
                onTap: onOpenPassport,
                child: Icon(
                  CupertinoIcons.shield_lefthalf_fill,
                  size: 17,
                  color: c.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: c.invText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -.45,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: TextStyle(
              color: c.invText.withValues(alpha: .67),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Pressable(
                  onTap: action,
                  haptic: true,
                  child: Container(
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      actionLabel,
                      style: TextStyle(
                        color: c.textOnAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Pressable(
                  semanticLabel: passportLabel,
                  onTap: onOpenPassport,
                  child: Text(
                    passportLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.invText.withValues(alpha: .68),
                      fontSize: 10,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _dateLabel(ScheduledWorkout item, bool russian) {
    final date = item.date;
    if (date == null) return item.plannedOn;
    final now = DateTime.now();
    final days = DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (days == 0) return russian ? 'Сегодня по плану' : 'Planned for today';
    if (days == 1) return russian ? 'Завтра по плану' : 'Planned for tomorrow';
    return russian
        ? 'Через $days дн. · ${item.plannedOn}'
        : 'In $days days · ${item.plannedOn}';
  }
}

class _TrainingBriefCard extends StatelessWidget {
  final UserRanks ranks;
  final VoidCallback onTap;

  const _TrainingBriefCard({required this.ranks, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final count = ranks.exerciseRanks.length;
    final promotable =
        ranks.exerciseRanks.where((rank) => rank.nextRank != null).toList()
          ..sort((a, b) => a.ratioToNext.compareTo(b.ratioToNext));

    late final String title;
    late final String body;
    late final String badge;
    if (count == 0) {
      title = l10n.passportSignal;
      body = l10n.passportFirstBenchmark;
      badge = '0/3';
    } else if (count < 3) {
      title = l10n.passportCalibration(count);
      body = l10n.passportCalibrationBody(3 - count);
      badge = '$count/3';
    } else if (promotable.isNotEmpty) {
      final next = promotable.first;
      title = l10n.passportClosestPromotion;
      body = l10n.passportPromotionBody(
        next.exerciseName,
        next.rank,
        next.nextRank!,
      );
      badge = '${next.rank}→${next.nextRank}';
    } else {
      title = l10n.passportHighestClass;
      body = l10n.passportHighestClassBody;
      badge = 'SS';
    }

    final foreground = c.isDark ? c.textPrimary : c.invText;
    final secondary = foreground.withValues(alpha: .66);
    return Pressable(
      semanticLabel: '${l10n.trainingBrief}. $title. $body',
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 15),
        decoration: BoxDecoration(
          color: c.isDark ? c.card : c.invBg,
          borderRadius: BorderRadius.circular(AppDesign.radiusControl),
          border: Border.all(
            color: c.isDark ? c.border : c.accent.withValues(alpha: .42),
          ),
          boxShadow: c.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              height: 66,
              decoration: BoxDecoration(
                color: c.accent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.trainingBrief,
                    style: TextStyle(
                      color: c.accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.35,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: secondary,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.accent.withValues(alpha: .38)),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: c.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats strip (3 red segments) ──────────────────────────────────────────────

class _StatStrip extends StatelessWidget {
  final List<(String, String)> segments;
  const _StatStrip({required this.segments});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final items = [
      for (var i = 0; i < segments.length; i++)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      segments[i].$1,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        height: 1,
                        letterSpacing: -0.8,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  segments[i].$2,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    height: 1.25,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
    return largeText
        ? Column(
            children: [
              for (var i = 0; i < segments.length; i++) ...[
                if (i > 0) Container(height: 1, color: c.border),
                Row(children: [items[i]]),
              ],
            ],
          )
        : Row(
            children: [
              for (var i = 0; i < segments.length; i++) ...[
                if (i > 0) Container(width: 1, height: 54, color: c.border),
                items[i],
              ],
            ],
          );
  }
}

// ── Navigation row ────────────────────────────────────────────────────────────

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool last;

  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      semanticLabel: '$title, $subtitle',
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                _LogoIconTile(icon: icon),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.25,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 15,
                  color: c.textSecondary.withValues(alpha: 0.76),
                ),
              ],
            ),
          ),
          if (!last)
            Padding(
              padding: const EdgeInsets.only(left: 68, right: 14),
              child: Container(height: AppDesign.hairline, color: c.border),
            ),
        ],
      ),
    );
  }
}

class _LogoIconTile extends StatelessWidget {
  final IconData icon;
  const _LogoIconTile({required this.icon});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: c.isDark ? c.iconBg : c.invBg,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: c.isDark ? c.border : c.invBg,
                  width: AppDesign.hairline,
                ),
              ),
              child: Icon(
                icon,
                size: 17,
                color: c.isDark ? c.textPrimary : c.invText,
              ),
            ),
          ),
          Positioned(
            top: 6,
            left: 5,
            child: Transform.rotate(
              angle: 0.72,
              child: Container(
                width: 7,
                height: 2,
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Start workout button ──────────────────────────────────────────────────────

class _StartButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = AppLocalizations.of(context).chooseWorkout;
    return Pressable(
      semanticLabel: label,
      haptic: true,
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: c.invBg,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          shadows: c.cardShadow,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: c.invText,
          ),
        ),
      ),
    );
  }
}

// ── First-time weight sheet ───────────────────────────────────────────────────

class _FirstTimeWeightSheet extends StatefulWidget {
  final RankingRepository ranking;
  final Future<void> Function() onDismiss;
  const _FirstTimeWeightSheet({required this.ranking, required this.onDismiss});

  @override
  State<_FirstTimeWeightSheet> createState() => _FirstTimeWeightSheetState();
}

class _FirstTimeWeightSheetState extends State<_FirstTimeWeightSheet> {
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  bool get _isRussian => Localizations.localeOf(context).languageCode == 'ru';

  Future<void> _save() async {
    final w = _metricValue(_weightCtrl.text);
    final h = _metricValue(_heightCtrl.text);
    if (w == null && h == null) {
      await _dismiss();
      return;
    }
    if ((w != null && (w < 20 || w > 500)) ||
        (h != null && (h < 80 || h > 260))) {
      setState(
        () => _error = _isRussian
            ? 'Введите вес 20–500 кг и рост 80–260 см.'
            : 'Enter weight between 20–500 kg and height between 80–260 cm.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.ranking.updateProfile(weightKg: w, heightCm: h);
      if (mounted) await _dismiss();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = _isRussian
              ? 'Не удалось сохранить. Проверьте соединение и попробуйте снова.'
              : 'Could not save. Check your connection and try again.';
        });
      }
    }
  }

  Future<void> _dismiss() async {
    await widget.onDismiss();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${l.quickSetupTitle} 🏋',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.quickSetupBody,
              style: TextStyle(fontSize: 12, color: c.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricField(
                    controller: _weightCtrl,
                    label: AppLocalizations.of(context).weightKgLabel,
                    placeholder: '80',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricField(
                    controller: _heightCtrl,
                    label: AppLocalizations.of(context).heightCmLabel,
                    placeholder: '175',
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: c.accent, fontSize: 12)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _saving ? null : _dismiss,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: c.iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          l.skip,
                          style: TextStyle(color: c.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _saving ? null : _save,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: c.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: _saving
                            ? const CupertinoActivityIndicator()
                            : Text(
                                l.save,
                                style: TextStyle(
                                  color: c.textOnAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
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

class _MetricField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  const _MetricField({
    required this.controller,
    required this.label,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: c.textPrimary, fontSize: 15),
          placeholderStyle: TextStyle(color: c.textSecondary, fontSize: 15),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: c.iconBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.border),
          ),
        ),
      ],
    );
  }
}

double? _metricValue(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  return double.tryParse(value.replaceAll(',', '.'));
}

// ── Annual body profile reminder ──────────────────────────────────────────────

class _AnnualWeightDialog extends StatefulWidget {
  final RankingRepository ranking;
  final RankProfile profile;
  final Future<void> Function() onDismiss;

  const _AnnualWeightDialog({
    required this.ranking,
    required this.profile,
    required this.onDismiss,
  });

  @override
  State<_AnnualWeightDialog> createState() => _AnnualWeightDialogState();
}

class _AnnualWeightDialogState extends State<_AnnualWeightDialog> {
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  bool get _isRussian => Localizations.localeOf(context).languageCode == 'ru';

  @override
  void initState() {
    super.initState();
    if (widget.profile.weightKg != null) {
      _weightCtrl.text = widget.profile.weightKg!.toStringAsFixed(1);
    }
    if (widget.profile.heightCm != null) {
      _heightCtrl.text = widget.profile.heightCm!.toStringAsFixed(0);
    }
  }

  Future<void> _save() async {
    final w = _metricValue(_weightCtrl.text);
    final h = _metricValue(_heightCtrl.text);
    if (w == null && h == null) {
      await _dismiss();
      return;
    }
    if ((w != null && (w < 20 || w > 500)) ||
        (h != null && (h < 80 || h > 260))) {
      setState(
        () => _error = _isRussian
            ? 'Введите вес 20–500 кг и рост 80–260 см.'
            : 'Enter weight between 20–500 kg and height between 80–260 cm.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.ranking.updateProfile(weightKg: w, heightCm: h);
      if (mounted) await _dismiss();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = _isRussian
              ? 'Не удалось сохранить. Проверьте соединение и попробуйте снова.'
              : 'Could not save. Check your connection and try again.';
        });
      }
    }
  }

  Future<void> _dontAsk() async {
    try {
      await widget.ranking.updateProfile(dontAskWeight: true);
      if (mounted) await _dismiss();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _dismiss() async {
    await widget.onDismiss();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 340,
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: c.border),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x40000000),
                  blurRadius: 40,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.updateYourWeight,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.weightReminderBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                CupertinoTextField(
                  controller: _weightCtrl,
                  placeholder: l.weightKgLabel,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(color: c.textPrimary, fontSize: 15),
                  placeholderStyle: TextStyle(
                    color: c.textSecondary,
                    fontSize: 15,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: c.iconBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.border),
                  ),
                ),
                const SizedBox(height: 10),
                CupertinoTextField(
                  controller: _heightCtrl,
                  placeholder: l.heightCmLabel,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(color: c.textPrimary, fontSize: 15),
                  placeholderStyle: TextStyle(
                    color: c.textSecondary,
                    fontSize: 15,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: c.iconBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.border),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: TextStyle(color: c.accent, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 18),
                Pressable(
                  onTap: _saving ? null : _save,
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: _saving
                        ? const CupertinoActivityIndicator()
                        : Text(
                            l.update,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: c.textOnAccent,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Pressable(
                  onTap: _dismiss,
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.iconBg,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      l.notNow,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Pressable(
                  onTap: _dontAsk,
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    child: Text(
                      l.dontAskAgain,
                      style: TextStyle(fontSize: 13, color: c.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _YearCalendarSheet extends StatelessWidget {
  final StreakData streak;
  const _YearCalendarSheet({required this.streak});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final russian = Localizations.localeOf(context).languageCode == 'ru';
    final year = DateTime.now().year;
    final activeSet = streak.activeWeeks.toSet();
    final currentWeek = _isoWeekNumber(DateTime.now());

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$year  •  ${streak.currentStreakWorkouts} ${_workoutWord(context, streak.currentStreakWorkouts)} ${russian ? 'в цепочке' : 'in chain'}',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            russian
                ? '${streak.activeWeeks.length} ${_weekWord(context, streak.activeWeeks.length)} активности в этом году'
                : '${streak.activeWeeks.length} ${_weekWord(context, streak.activeWeeks.length)} active this year',
            style: TextStyle(color: c.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _WeekGrid(
                totalWeeks: _weeksInYear(year),
                activeWeeks: activeSet,
                currentWeek: currentWeek,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  static int _isoWeekNumber(DateTime d) {
    final thursday = d.add(Duration(days: 4 - d.weekday));
    final jan1 = DateTime(thursday.year, 1, 1);
    final firstThursday = jan1.add(Duration(days: (4 - jan1.weekday + 7) % 7));
    return ((thursday.difference(firstThursday).inDays) / 7).floor() + 1;
  }

  static int _weeksInYear(int year) => _isoWeekNumber(DateTime(year, 12, 28));
}

String _weekWord(BuildContext context, int value) {
  if (Localizations.localeOf(context).languageCode != 'ru') {
    return value == 1 ? 'week' : 'weeks';
  }
  final mod10 = value % 10;
  final mod100 = value % 100;
  if (mod10 == 1 && mod100 != 11) return 'неделя';
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return 'недели';
  }
  return 'недель';
}

String _workoutWord(BuildContext context, int value) {
  if (Localizations.localeOf(context).languageCode != 'ru') {
    return value == 1 ? 'workout' : 'workouts';
  }
  final mod10 = value % 10;
  final mod100 = value % 100;
  if (mod10 == 1 && mod100 != 11) return 'тренировка';
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return 'тренировки';
  }
  return 'тренировок';
}

class _WeekGrid extends StatelessWidget {
  final int totalWeeks;
  final Set<int> activeWeeks;
  final int currentWeek;

  const _WeekGrid({
    required this.totalWeeks,
    required this.activeWeeks,
    required this.currentWeek,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const cols = 13;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: totalWeeks,
      itemBuilder: (_, i) {
        final week = i + 1;
        final isActive = activeWeeks.contains(week);
        final isCurrent = week == currentWeek;

        Color bg;
        Color numColor;
        if (isActive) {
          bg = c.accent;
          numColor = c.textOnAccent;
        } else {
          bg = c.iconBg;
          numColor = c.textSecondary;
        }

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(3),
            border: isCurrent ? Border.all(color: c.accent, width: 1.5) : null,
          ),
          child: Center(
            child: Text(
              '$week',
              style: TextStyle(
                color: isCurrent && !isActive ? c.accent : numColor,
                fontSize: 7,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                height: 1,
              ),
            ),
          ),
        );
      },
    );
  }
}
