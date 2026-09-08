import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymboss/data/repositories/ranking_repository.dart';
import 'package:gymboss/data/repositories/sessions_repository.dart';
import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/domain/models/ranking/rank_data.dart';
import 'package:gymboss/domain/models/streak/streak_data.dart';
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
import 'package:gymboss/l10n/app_localizations.dart';

class MenuOptions extends StatefulWidget {
  const MenuOptions({super.key});

  @override
  State<MenuOptions> createState() => _MenuOptionsState();
}

class _MenuOptionsState extends State<MenuOptions> {
  late final SessionsRepository _sessions;
  late final RankingRepository _ranking;
  late final WorkoutsRepository _workoutsRepo;
  StreakData _streak = StreakData.empty;
  UserRanks? _passport;
  int _workouts = 0;

  @override
  void initState() {
    super.initState();
    final client = context.read<AuthenticatedClient>();
    _sessions = SessionsRepository(client: client);
    _ranking = RankingRepository(client: client);
    _workoutsRepo = WorkoutsRepository(client: client);
    _loadStreak();
    _loadPassport();
    _loadWorkouts();
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
      final profile = await _ranking.getProfile();
      if (!mounted) return;
      if (profile.dontAskWeight) return;

      if (profile.weightKg == null) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) _showFirstTimeWeightSheet();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastCheckMs = prefs.getInt('weight_last_asked') ?? 0;
      final lastCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckMs);
      if (DateTime.now().difference(lastCheck).inDays >= 30) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) _showMonthlyWeightPopup(profile);
      }
    } catch (_) {}
  }

  void _showFirstTimeWeightSheet() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => _FirstTimeWeightSheet(ranking: _ranking),
    );
  }

  void _showMonthlyWeightPopup(RankProfile profile) {
    showCupertinoDialog<void>(
      context: context,
      builder: (_) => _MonthlyWeightDialog(
        ranking: _ranking,
        profile: profile,
        onDismiss: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(
            'weight_last_asked',
            DateTime.now().millisecondsSinceEpoch,
          );
        },
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
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final weeks = _streak.currentStreakWeeks;
    final nextMilestone = _streak.nextMilestoneWeeks;
    final nextMilestoneLabel =
        '$nextMilestone ${_weekWord(context, nextMilestone)}';

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
            AppGlassSurface(
              onTap: () => _showYearCalendar(context),
              child: _StatStrip(
                segments: [
                  ('$weeks', l10n.weekStreak),
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
  const _FirstTimeWeightSheet({required this.ranking});

  @override
  State<_FirstTimeWeightSheet> createState() => _FirstTimeWeightSheetState();
}

class _FirstTimeWeightSheetState extends State<_FirstTimeWeightSheet> {
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    final w = double.tryParse(_weightCtrl.text);
    final h = double.tryParse(_heightCtrl.text);
    if (w == null && h == null) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.ranking.updateProfile(weightKg: w, heightCm: h);
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
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
            'Quick setup 🏋',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Optional — helps calculate your strength rank',
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Skip',
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
                              'Save',
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

// ── Monthly weight dialog ─────────────────────────────────────────────────────

class _MonthlyWeightDialog extends StatefulWidget {
  final RankingRepository ranking;
  final RankProfile profile;
  final VoidCallback onDismiss;

  const _MonthlyWeightDialog({
    required this.ranking,
    required this.profile,
    required this.onDismiss,
  });

  @override
  State<_MonthlyWeightDialog> createState() => _MonthlyWeightDialogState();
}

class _MonthlyWeightDialogState extends State<_MonthlyWeightDialog> {
  final _weightCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.profile.weightKg != null) {
      _weightCtrl.text = widget.profile.weightKg!.toStringAsFixed(1);
    }
  }

  Future<void> _save() async {
    final w = double.tryParse(_weightCtrl.text);
    if (w == null) {
      _dismiss();
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.ranking.updateProfile(weightKg: w);
    } catch (_) {}
    widget.onDismiss();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _dontAsk() async {
    try {
      await widget.ranking.updateProfile(dontAskWeight: true);
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  void _dismiss() {
    widget.onDismiss();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
                  'Update your weight?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your weight helps keep rankings accurate. Takes 5 seconds.',
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
                  placeholder: 'Weight (kg)',
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
                            'Update',
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
                      'Not now',
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
                      "Don't ask again",
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
            '$year  •  ${streak.currentStreakWeeks} ${_weekWord(context, streak.currentStreakWeeks)} ${russian ? 'подряд' : 'streak'}',
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
