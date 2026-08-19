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
  int _workouts = 0;

  @override
  void initState() {
    super.initState();
    final client = context.read<AuthenticatedClient>();
    _sessions = SessionsRepository(client: client);
    _ranking = RankingRepository(client: client);
    _workoutsRepo = WorkoutsRepository(client: client);
    _loadStreak();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    try {
      final w = await _workoutsRepo.listOwned();
      if (mounted) setState(() => _workouts = w.length);
    } catch (_) {}
  }

  Future<void> _loadStreak() async {
    try {
      await _sessions.recordSession();
    } catch (_) {}
    try {
      final data = await _sessions.getStreakData();
      if (mounted) {
        setState(
          () =>
              _streak =
                  data.currentStreakWeeks > 0
                      ? data
                      : StreakData(
                        currentStreakWeeks: 1,
                        activeWeeks: data.activeWeeks,
                      ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _streak = const StreakData(
                currentStreakWeeks: 1,
                activeWeeks: [],
              ),
        );
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
      builder:
          (_) => _MonthlyWeightDialog(
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
    final weeks = _streak.currentStreakWeeks;
    final weeksToGoal = 4 - (weeks % 4);

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
                  ('$weeks', 'WEEK STREAK'),
                  ('$weeksToGoal wk', 'NEXT GOAL'),
                  ('$_workouts', 'ROUTINES'),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Text(
              'Explore',
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
                    accentTile: true,
                    title: 'Workouts',
                    subtitle: 'Programs and routines',
                    onTap: () => _pushAndReload(const Workouts()),
                  ),
                  _MenuRow(
                    icon: Icons.insights_rounded,
                    title: 'Progress',
                    subtitle: 'History and personal records',
                    onTap: () => _push(const Statistics()),
                  ),
                  _MenuRow(
                    icon: Icons.military_tech_rounded,
                    title: 'Achievements',
                    subtitle: 'Ranks and milestones',
                    onTap: () => _push(const Ranking()),
                  ),
                  _MenuRow(
                    icon: Icons.fitness_center_rounded,
                    title: 'Exercises',
                    subtitle: 'Movement library',
                    onTap: () => _push(const Exercises()),
                  ),
                  _MenuRow(
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    subtitle: 'Preferences and account',
                    onTap: () => _push(const Settings()),
                    last: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _StartButton(onTap: () => _pushAndReload(const Workouts())),
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
                Text(
                  segments[i].$1,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    letterSpacing: -0.8,
                    color: c.textPrimary,
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

// ── Flat menu row ─────────────────────────────────────────────────────────────

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool accentTile;
  final bool last;

  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accentTile = false,
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color:
                        accentTile
                            ? c.accent.withValues(alpha: 0.12)
                            : c.iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: accentTile ? c.accent : c.textSecondary,
                  ),
                ),
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
                Icon(
                  CupertinoIcons.arrow_right,
                  size: 18,
                  color: c.textSecondary,
                ),
              ],
            ),
          ),
          if (!last) Container(height: 1, color: c.border),
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
    return Pressable(
      semanticLabel: 'Choose a workout',
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
          'Choose a workout',
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
                  label: 'Weight (kg)',
                  placeholder: '80',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricField(
                  controller: _heightCtrl,
                  label: 'Height (cm)',
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
                      child:
                          _saving
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
                    child:
                        _saving
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
            '$year  •  ${streak.currentStreakWeeks} week${streak.currentStreakWeeks == 1 ? '' : 's'} streak',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${streak.activeWeeks.length} week${streak.activeWeeks.length == 1 ? '' : 's'} active this year',
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
