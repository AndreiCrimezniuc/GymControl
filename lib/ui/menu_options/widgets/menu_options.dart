import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymboss/data/repositories/ranking_repository.dart';
import 'package:gymboss/data/repositories/sessions_repository.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/domain/models/ranking/rank_data.dart';
import 'package:gymboss/domain/models/streak/streak_data.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_bottom_nav.dart';
import 'package:gymboss/ui/core/ui/widgets/app_scaffold.dart';
import 'package:gymboss/ui/core/ui/widgets/menu_card.dart';
import 'package:gymboss/ui/core/ui/widgets/pill_button.dart';
import 'package:gymboss/ui/core/ui/widgets/streak_ring.dart';
import 'package:gymboss/ui/core/ui/widgets/theme_toggle.dart';
import 'package:gymboss/ui/menu_options_list/exercises/widgets/exercises.dart';
import 'package:gymboss/ui/menu_options_list/program/widgets/program.dart';
import 'package:gymboss/ui/menu_options_list/ranking/widgets/ranking.dart';
import 'package:gymboss/ui/menu_options_list/settings/widgets/settings.dart';
import 'package:gymboss/ui/menu_options_list/statistics/widgets/statistics.dart';
import 'package:gymboss/ui/menu_options_list/training/widgets/training.dart';

class MenuOptions extends StatefulWidget {
  const MenuOptions({super.key});

  @override
  State<MenuOptions> createState() => _MenuOptionsState();
}

class _MenuOptionsState extends State<MenuOptions> {
  late final SessionsRepository _sessions;
  late final RankingRepository _ranking;
  StreakData _streak = StreakData.empty;

  @override
  void initState() {
    super.initState();
    final client = context.read<AuthenticatedClient>();
    _sessions = SessionsRepository(client: client);
    _ranking = RankingRepository(client: client);
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    try {
      await _sessions.recordSession();
    } catch (_) {
      // non-critical — already recorded today or backend rebuilding
    }
    try {
      final data = await _sessions.getStreakData();
      if (mounted) {
        setState(() => _streak = data.currentStreakWeeks > 0
            ? data
            : StreakData(currentStreakWeeks: 1, activeWeeks: data.activeWeeks));
      }
    } catch (_) {
      // backend unreachable — show 1 week since user just opened the app
      if (mounted) {
        setState(() => _streak = const StreakData(currentStreakWeeks: 1, activeWeeks: []));
      }
    }
    _checkWeightPrompt();
  }

  Future<void> _checkWeightPrompt() async {
    try {
      final profile = await _ranking.getProfile();
      if (!mounted) return;
      if (profile.dontAskWeight) return;

      // First-time: no weight set
      if (profile.weightKg == null) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) _showFirstTimeWeightSheet();
        return;
      }

      // Monthly check: weight not updated in 30+ days
      final prefs = await SharedPreferences.getInstance();
      final lastCheckMs = prefs.getInt('weight_last_asked') ?? 0;
      final lastCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckMs);
      if (DateTime.now().difference(lastCheck).inDays >= 30) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) _showMonthlyWeightPopup(profile);
      }
    } catch (_) {
      // non-critical
    }
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
          await prefs.setInt('weight_last_asked', DateTime.now().millisecondsSinceEpoch);
        },
      ),
    );
  }

  void _push(Widget page) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final weeks = _streak.currentStreakWeeks;
    final ringProgress =
        weeks <= 0 ? 0.0 : (weeks % 7 == 0 ? 1.0 : (weeks % 7) / 7);

    return AppScaffold(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: c.accent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'GYM CONTROL',
                        style: TextStyle(
                          fontFamily: 'Rubik',
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: c.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: c.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'READY',
                        style: TextStyle(
                          fontFamily: 'Rubik',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const ThemeToggle(),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // ── Streak ring ─────────────────────────────────────────
                  Center(
                    child: StreakRing(
                      value: weeks,
                      caption: 'Week Streak',
                      progress: ringProgress,
                      onTap: () => _showYearCalendar(context),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ── Action pills ────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: PillButton(
                          label: 'Start',
                          filled: true,
                          onTap: () => _push(const Training()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PillButton(
                          label: 'Program',
                          onTap: () => _push(const Program()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PillButton(
                          label: 'Stats',
                          onTap: () => _push(const Statistics()),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Menu cards ──────────────────────────────────────────
                  MenuCard(
                    icon: Icons.emoji_events_rounded,
                    iconColor: c.accent,
                    title: 'My Program',
                    subtitle: 'View routines',
                    onTap: () => _push(const Program()),
                  ),
                  const SizedBox(height: 12),
                  MenuCard(
                    icon: Icons.bar_chart_rounded,
                    title: 'Statistics',
                    subtitle: 'Track progress',
                    onTap: () => _push(const Statistics()),
                  ),
                  const SizedBox(height: 12),
                  MenuCard(
                    icon: Icons.emoji_events_outlined,
                    title: 'Rank',
                    subtitle: 'See where you stand',
                    onTap: () => _push(const Ranking()),
                  ),
                  const SizedBox(height: 12),
                  MenuCard(
                    icon: Icons.fitness_center_rounded,
                    title: 'Exercises',
                    subtitle: 'Browse library',
                    onTap: () => _push(const Exercises()),
                  ),
                  const SizedBox(height: 12),
                  MenuCard(
                    icon: Icons.wb_sunny_outlined,
                    title: 'Settings',
                    subtitle: 'Customize app',
                    onTap: () => _push(const Settings()),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom navigation ───────────────────────────────────────────
          AppBottomNav(
            activeIndex: 0,
            items: [
              const BottomNavItem(icon: Icons.home_outlined),
              BottomNavItem(
                icon: Icons.fitness_center_rounded,
                onTap: () => _push(const Exercises()),
              ),
              BottomNavItem(
                icon: Icons.bar_chart_rounded,
                onTap: () => _push(const Statistics()),
              ),
              BottomNavItem(
                icon: Icons.person_outline,
                onTap: () => _push(const Settings()),
              ),
            ],
          ),
        ],
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
    if (w == null && h == null) { Navigator.pop(context); return; }
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
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Quick setup 🏋',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.textPrimary, fontFamily: 'Rubik')),
          const SizedBox(height: 4),
          Text('Optional — helps calculate your strength rank',
              style: TextStyle(fontSize: 12, color: c.textSecondary, fontFamily: 'Rubik')),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _MetricField(controller: _weightCtrl, label: 'Weight (kg)', placeholder: '80')),
            const SizedBox(width: 12),
            Expanded(child: _MetricField(controller: _heightCtrl, label: 'Height (cm)', placeholder: '175')),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(color: c.iconBg, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text('Skip', style: TextStyle(color: c.textSecondary, fontFamily: 'Rubik'))),
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
                  decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: _saving
                        ? const CupertinoActivityIndicator()
                        : Text('Save', style: TextStyle(color: c.textOnAccent, fontWeight: FontWeight.w600, fontFamily: 'Rubik')),
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _MetricField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  const _MetricField({required this.controller, required this.label, required this.placeholder});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.textSecondary, fontFamily: 'Rubik')),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: c.textPrimary, fontSize: 15, fontFamily: 'Rubik'),
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

  const _MonthlyWeightDialog({required this.ranking, required this.profile, required this.onDismiss});

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
    if (w == null) { _dismiss(); return; }
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
    return CupertinoAlertDialog(
      title: const Text('Update your weight?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Your weight helps keep rankings accurate.\nTakes 5 seconds.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: _weightCtrl,
            placeholder: 'Weight (kg)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: _dontAsk,
          isDestructiveAction: false,
          child: const Text("Don't ask again", style: TextStyle(fontSize: 13)),
        ),
        CupertinoDialogAction(
          onPressed: _dismiss,
          child: const Text('Not now'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _saving ? null : _save,
          child: _saving ? const CupertinoActivityIndicator() : const Text('Update'),
        ),
      ],
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
              fontFamily: 'Rubik',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${streak.activeWeeks.length} week${streak.activeWeeks.length == 1 ? '' : 's'} active this year',
            style: TextStyle(
              color: c.textSecondary,
              fontSize: 12,
              fontFamily: 'Rubik',
            ),
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
    final firstThursday = jan1.add(
      Duration(days: (4 - jan1.weekday + 7) % 7),
    );
    return ((thursday.difference(firstThursday).inDays) / 7).floor() + 1;
  }

  static int _weeksInYear(int year) {
    return _isoWeekNumber(DateTime(year, 12, 28));
  }
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
                fontFamily: 'Rubik',
                height: 1,
              ),
            ),
          ),
        );
      },
    );
  }
}
