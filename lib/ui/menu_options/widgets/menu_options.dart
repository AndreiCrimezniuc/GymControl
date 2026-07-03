import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymboss/data/repositories/ranking_repository.dart';
import 'package:gymboss/data/repositories/sessions_repository.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/domain/models/ranking/rank_data.dart';
import 'package:gymboss/domain/models/streak/streak_data.dart';
import 'package:gymboss/ui/core/ui/button/option_button.dart';
import 'package:gymboss/ui/core/ui/icons/icons_options_menu.dart';
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Gym | Control",
                  style: TextStyle(fontSize: 35, color: CupertinoColors.black),
                ),
                const SizedBox(height: 35),
                const Text(
                  "Your fitness companion",
                  style: TextStyle(fontSize: 25, color: CupertinoColors.black),
                ),
                const SizedBox(height: 20),
                OptionButtonMenu(
                  title: "Current streak",
                  borderColor: const Color.fromRGBO(99, 32, 36, 1),
                  subtitle: "${_streak.currentStreakWeeks} week${_streak.currentStreakWeeks == 1 ? '' : 's'}",
                  icon: Image.asset(
                    IconsOptionsMenu.fire,
                    width: 24,
                    height: 24,
                  ),
                  backgroundColor: const Color.fromRGBO(99, 32, 36, 1),
                  callBack: () => _showYearCalendar(context),
                ),
                const SizedBox(height: 70),
                OptionButtonMenu(
                  title: "Start training",
                  subtitle: "Begin your workout",
                  borderColor: const Color(0xFF0D1F2D),
                  icon: Image.asset(
                    IconsOptionsMenu.play,
                    width: 24,
                    height: 24,
                  ),
                  backgroundColor: const Color(0xFF0D1F2D),
                  callBack: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (context) => const Training(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                OptionButtonMenu(
                  title: "My Program",
                  borderColor: const Color(0xFF0D1F2D),
                  subtitle: "View routines",
                  icon: Image.asset(
                    IconsOptionsMenu.calender,
                    width: 24,
                    height: 24,
                  ),
                  backgroundColor: const Color(0xFF0D1F2D),
                  callBack: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (context) => const Program(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                OptionButtonMenu(
                  title: "Statistics",
                  subtitle: "Track progress",
                  borderColor: const Color(0xFF0D1F2D),
                  icon: Image.asset(
                    IconsOptionsMenu.statictics,
                    width: 24,
                    height: 24,
                  ),
                  backgroundColor: const Color(0xFF0D1F2D),
                  callBack: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (context) => const Statistics(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                OptionButtonMenu(
                  title: "Rank",
                  subtitle: "See where you stand",
                  borderColor: const Color(0xFF4C1D95),
                  icon: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Text('🏆', style: TextStyle(fontSize: 20)),
                  ),
                  backgroundColor: const Color(0xFF4C1D95),
                  callBack: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (context) => const Ranking(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                OptionButtonMenu(
                  title: "Exercises",
                  subtitle: "Browse library",
                  borderColor: const Color(0xFF0D1F2D),
                  icon: Image.asset(
                    IconsOptionsMenu.barbell,
                    width: 24,
                    height: 24,
                  ),
                  backgroundColor: const Color(0xFF0D1F2D),
                  callBack: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (context) => const Exercises(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                OptionButtonMenu(
                  title: "Settings",
                  subtitle: "Customize app or profile",
                  borderColor: const Color(0xFF0D1F2D),
                  icon: Image.asset(
                    IconsOptionsMenu.gear,
                    width: 24,
                    height: 24,
                  ),
                  backgroundColor: const Color(0xFF0D1F2D),
                  callBack: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (context) => const Settings(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
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
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1F2D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              decoration: BoxDecoration(color: const Color(0xFF546A7B), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Quick setup 🏋',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: CupertinoColors.white, fontFamily: 'Rubik')),
          const SizedBox(height: 4),
          const Text('Optional — helps calculate your strength rank',
              style: TextStyle(fontSize: 12, color: Color(0xFF8B9EAE), fontFamily: 'Rubik')),
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
                  decoration: BoxDecoration(color: const Color(0xFF152A3A), borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('Skip', style: TextStyle(color: Color(0xFF8B9EAE), fontFamily: 'Rubik'))),
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
                  decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: _saving
                        ? const CupertinoActivityIndicator()
                        : const Text('Save', style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w600, fontFamily: 'Rubik')),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8B9EAE), fontFamily: 'Rubik')),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: CupertinoColors.white, fontSize: 15, fontFamily: 'Rubik'),
          placeholderStyle: const TextStyle(color: Color(0xFF546A7B), fontSize: 15),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF152A3A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1E3A50)),
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
    final year = DateTime.now().year;
    final activeSet = streak.activeWeeks.toSet();
    final currentWeek = _isoWeekNumber(DateTime.now());

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1F2D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF546A7B),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$year  •  ${streak.currentStreakWeeks} week${streak.currentStreakWeeks == 1 ? '' : 's'} streak',
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Rubik',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${streak.activeWeeks.length} week${streak.activeWeeks.length == 1 ? '' : 's'} active this year',
            style: const TextStyle(
              color: Color(0xFF8B9EAE),
              fontSize: 12,
              fontFamily: 'Rubik',
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _StreakProgressBar(
              activeWeeks: streak.activeWeeks.length,
              totalWeeks: _weeksInYear(year),
              currentWeek: currentWeek,
              streakWeeks: streak.currentStreakWeeks,
            ),
          ),
          const SizedBox(height: 16),
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

class _StreakProgressBar extends StatelessWidget {
  final int activeWeeks;
  final int totalWeeks;
  final int currentWeek;
  final int streakWeeks;

  const _StreakProgressBar({
    required this.activeWeeks,
    required this.totalWeeks,
    required this.currentWeek,
    required this.streakWeeks,
  });

  @override
  Widget build(BuildContext context) {
    final yearFraction = currentWeek / totalWeeks;
    final activeFraction = activeWeeks / totalWeeks;
    final streakFraction = streakWeeks / totalWeeks;

    const barH = 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'W$currentWeek of $totalWeeks  •  $activeWeeks active',
          style: const TextStyle(
            color: Color(0xFF8B9EAE),
            fontSize: 11,
            fontFamily: 'Rubik',
          ),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (ctx, constraints) {
            final w = constraints.maxWidth;
            return Stack(
              children: [
                // base track
                Container(
                  height: barH,
                  decoration: BoxDecoration(
                    color: const Color(0xFF152A3A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                // year elapsed (very faint)
                FractionallySizedBox(
                  widthFactor: yearFraction.clamp(0.0, 1.0),
                  child: Container(
                    height: barH,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A50),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                // active weeks fill
                FractionallySizedBox(
                  widthFactor: activeFraction.clamp(0.0, 1.0),
                  child: Container(
                    height: barH,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                // streak highlight (brighter tip)
                if (streakWeeks > 0)
                  Positioned(
                    right: w * (1 - activeFraction).clamp(0.0, 1.0),
                    child: Container(
                      width: w * streakFraction.clamp(0.0, 1.0),
                      height: barH,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF22C55E), Color(0xFF4ADE80)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x8022C55E),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
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
          bg = const Color(0xFF22C55E);
          numColor = const Color(0xFFDCFCE7);
        } else if (week < currentWeek) {
          bg = const Color(0xFF1E3A50);
          numColor = const Color(0xFF3A5A70);
        } else {
          bg = const Color(0xFF152A3A);
          numColor = const Color(0xFF2A4050);
        }

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(3),
            border: isCurrent
                ? Border.all(color: const Color(0xFF60A5FA), width: 1.5)
                : null,
          ),
          child: Center(
            child: Text(
              '$week',
              style: TextStyle(
                color: isCurrent ? const Color(0xFF60A5FA) : numColor,
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
