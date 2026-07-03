import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:gymboss/data/repositories/ranking_repository.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/domain/models/ranking/rank_data.dart';
import 'package:gymboss/ui/auth/view_model/auth_view_model.dart';
import 'package:gymboss/ui/core/ui/colors/main_dark_blue.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late final RankingRepository _ranking;
  RankProfile? _profile;

  @override
  void initState() {
    super.initState();
    _ranking = RankingRepository(client: context.read<AuthenticatedClient>());
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await _ranking.getProfile();
      if (mounted) setState(() => _profile = p);
    } catch (_) {}
  }

  void _openBodyMetrics() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => _BodyMetricsSheet(
        ranking: _ranking,
        profile: _profile,
        onSaved: (p) => setState(() => _profile = p),
      ),
    );
  }

  void _resetWeightPrompt() async {
    try {
      await _ranking.updateProfile(dontAskWeight: false);
      final p = await _ranking.getProfile();
      if (mounted) setState(() => _profile = p);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final weight = _profile?.weightKg;
    final height = _profile?.heightCm;
    final dontAsk = _profile?.dontAskWeight ?? false;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFCAE9FF),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings'),
        backgroundColor: Color(0xFFCAE9FF),
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            _Section(
              title: 'Body Metrics',
              children: [
                _ValueTile(
                  icon: CupertinoIcons.chart_bar_circle_fill,
                  label: 'Weight',
                  value: weight != null ? '${weight.toStringAsFixed(1)} kg' : 'Not set',
                  onTap: _openBodyMetrics,
                ),
                _ValueTile(
                  icon: CupertinoIcons.person_fill,
                  label: 'Height',
                  value: height != null ? '${height.toStringAsFixed(0)} cm' : 'Not set',
                  onTap: _openBodyMetrics,
                ),
                if (dontAsk)
                  _SettingsTile(
                    icon: CupertinoIcons.bell_slash_fill,
                    label: 'Re-enable weight reminders',
                    onTap: _resetWeightPrompt,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'Account',
              children: [
                _SettingsTile(
                  icon: CupertinoIcons.bell_fill,
                  label: 'Notifications',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'App',
              children: [
                _SettingsTile(
                  icon: CupertinoIcons.info_circle_fill,
                  label: 'About',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),
            _LogoutButton(),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF546A7B),
              fontFamily: 'Rubik',
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: mainDarkBlue,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: children.length,
            separatorBuilder: (_, __) => Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: const Color(0xFF1E3A50),
            ),
            itemBuilder: (_, i) => children[i],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF8B9EAE)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: CupertinoColors.white,
                  fontFamily: 'Rubik',
                ),
              ),
            ),
            const Icon(CupertinoIcons.chevron_forward, size: 14, color: Color(0xFF546A7B)),
          ],
        ),
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  const _ValueTile({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF8B9EAE)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 15, color: CupertinoColors.white, fontFamily: 'Rubik')),
            ),
            Text(value,
                style: const TextStyle(fontSize: 14, color: Color(0xFF8B9EAE), fontFamily: 'Rubik')),
            const SizedBox(width: 6),
            const Icon(CupertinoIcons.chevron_forward, size: 14, color: Color(0xFF546A7B)),
          ],
        ),
      ),
    );
  }
}

class _BodyMetricsSheet extends StatefulWidget {
  final RankingRepository ranking;
  final RankProfile? profile;
  final void Function(RankProfile) onSaved;
  const _BodyMetricsSheet({required this.ranking, this.profile, required this.onSaved});

  @override
  State<_BodyMetricsSheet> createState() => _BodyMetricsSheetState();
}

class _BodyMetricsSheetState extends State<_BodyMetricsSheet> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: widget.profile?.weightKg?.toStringAsFixed(1) ?? '',
    );
    _heightCtrl = TextEditingController(
      text: widget.profile?.heightCm?.toStringAsFixed(0) ?? '',
    );
  }

  Future<void> _save() async {
    final w = double.tryParse(_weightCtrl.text);
    final h = double.tryParse(_heightCtrl.text);
    setState(() => _saving = true);
    try {
      final p = await widget.ranking.updateProfile(weightKg: w, heightCm: h);
      widget.onSaved(p);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
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
          const Text('Body Metrics',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: CupertinoColors.white, fontFamily: 'Rubik')),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _MetricInput(controller: _weightCtrl, label: 'Weight (kg)', placeholder: '80')),
            const SizedBox(width: 12),
            Expanded(child: _MetricInput(controller: _heightCtrl, label: 'Height (cm)', placeholder: '175')),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _saving ? null : _save,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: _saving ? const Color(0xFF1E3A50) : const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _saving
                      ? const CupertinoActivityIndicator()
                      : const Text('Save',
                          style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: CupertinoColors.white, fontFamily: 'Rubik',
                          )),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  const _MetricInput({required this.controller, required this.label, required this.placeholder});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: Color(0xFF8B9EAE), fontFamily: 'Rubik',
            )),
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

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _confirmLogout(context),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF3D1818),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF632024), width: 1),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.square_arrow_left, color: Color(0xFFEF4444), size: 18),
            SizedBox(width: 8),
            Text(
              'Log Out',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEF4444),
                fontFamily: 'Rubik',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              context.read<AuthViewModel>().logout();
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
