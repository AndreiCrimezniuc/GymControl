import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gymboss/config/api_config.dart';
import 'package:gymboss/core/errors/app_error.dart';
import 'package:gymboss/data/diagnostics/diagnostic_service.dart';
import 'package:gymboss/data/repositories/ranking_repository.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/domain/models/ranking/rank_data.dart';
import 'package:gymboss/l10n/app_localizations.dart';
import 'package:gymboss/ui/auth/view_model/auth_view_model.dart';
import 'package:gymboss/ui/core/locale/locale_controller.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/units/units_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_dialog.dart';
import 'package:gymboss/ui/core/ui/widgets/app_page.dart';
import 'package:gymboss/ui/core/subscription/pro_controller.dart';
import 'package:gymboss/ui/subscription/paywall_screen.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late final RankingRepository _ranking;
  RankProfile? _profile;
  bool _sendingDiagnostics = false;
  bool _automaticDiagnostics = true;

  @override
  void initState() {
    super.initState();
    _ranking = RankingRepository(client: context.read<AuthenticatedClient>());
    _loadProfile();
    _loadDiagnosticsPreference();
  }

  Future<void> _loadDiagnosticsPreference() async {
    final enabled = await DiagnosticService.instance.automaticUploadEnabled;
    if (mounted) setState(() => _automaticDiagnostics = enabled);
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
      builder:
          (_) => _BodyMetricsSheet(
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

  void _openAbout() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => const _AboutSheet(),
    );
  }

  Future<void> _openExternal(Uri url) async {
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      await showAppDialog<void>(
        context,
        title: 'Could not open link',
        message: url.toString(),
        actions: [
          AppDialogAction('OK', onPressed: () => Navigator.pop(context)),
        ],
      );
    }
  }

  Future<void> _sendDiagnostics() async {
    final diagnostics = DiagnosticService.instance;
    final count = diagnostics.eventCount;
    if (count == 0) {
      await showAppDialog<void>(
        context,
        title: 'No diagnostics to send',
        message: 'The local diagnostic buffer is currently empty.',
        actions: [
          AppDialogAction('OK', onPressed: () => Navigator.pop(context)),
        ],
      );
      return;
    }
    final confirmed = await showAppDialog<bool>(
      context,
      title: 'Send diagnostics?',
      message:
          'This sends $count technical event${count == 1 ? '' : 's'} to GymBoss support. '
          'Tokens, email, workout contents, comments and stack traces are not included.',
      actions: [
        AppDialogAction(
          'Cancel',
          onPressed: () => Navigator.pop(context, false),
        ),
        AppDialogAction('Send', onPressed: () => Navigator.pop(context, true)),
      ],
    );
    if (confirmed != true || !mounted) return;

    setState(() => _sendingDiagnostics = true);
    try {
      final result = await diagnostics.send(
        context.read<AuthenticatedClient>(),
      );
      if (!mounted) return;
      setState(() => _sendingDiagnostics = false);
      await showAppDialog<void>(
        context,
        title: 'Diagnostics sent',
        message:
            '${result.eventCount} event${result.eventCount == 1 ? '' : 's'} sent. '
            'Reference: ${result.reportId.substring(0, 8)}',
        actions: [
          AppDialogAction('OK', onPressed: () => Navigator.pop(context)),
        ],
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _sendingDiagnostics = false);
      await showAppDialog<void>(
        context,
        title: 'Could not send diagnostics',
        message:
            'The events remain on this device. Check your connection and try again.',
        actions: [
          AppDialogAction('OK', onPressed: () => Navigator.pop(context)),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final l = AppLocalizations.of(context);
    final weight = _profile?.weightKg;
    final height = _profile?.heightCm;
    final dontAsk = _profile?.dontAskWeight ?? false;
    final pro = context.watch<ProController>();

    return AppPage(
      title: l.settingsTitle,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          const SizedBox(height: 4),
          _Section(
            title: l.sectionBodyMetrics,
            children: [
              _ValueTile(
                icon: CupertinoIcons.chart_bar_circle_fill,
                label: l.labelWeight,
                value:
                    weight != null
                        ? '${weight.toStringAsFixed(1)} kg'
                        : 'Not set',
                onTap: _openBodyMetrics,
              ),
              _ValueTile(
                icon: CupertinoIcons.person_fill,
                label: l.labelHeight,
                value:
                    height != null
                        ? '${height.toStringAsFixed(0)} cm'
                        : 'Not set',
                onTap: _openBodyMetrics,
              ),
              if (dontAsk)
                _SettingsTile(
                  icon: CupertinoIcons.bell_slash_fill,
                  label: l.labelReenableWeightReminders,
                  onTap: _resetWeightPrompt,
                ),
            ],
          ),
          const SizedBox(height: 20),
          _Section(
            title: l.sectionAppearance,
            children: [
              _SwitchTile(
                icon:
                    theme.isDark
                        ? CupertinoIcons.moon_fill
                        : CupertinoIcons.sun_max_fill,
                label: l.labelDarkMode,
                value: theme.isDark,
                onChanged: (_) => theme.toggle(),
              ),
              const _UnitsTile(),
            ],
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'GymBoss Pro · Development',
            children: [
              _SwitchTile(
                icon: CupertinoIcons.bolt_fill,
                label:
                    pro.isKnown
                        ? 'Pro account'
                        : pro.loading
                        ? 'Checking Pro access…'
                        : 'Pro status unavailable',
                value: pro.isPro,
                onChanged:
                    !pro.isKnown || pro.loading
                        ? null
                        : (value) async {
                          try {
                            await pro.setPro(value);
                          } catch (_) {
                            if (!context.mounted) return;
                            showAppDialog<void>(
                              context,
                              title: 'Could not update Pro status',
                              actions: [
                                AppDialogAction(
                                  'OK',
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            );
                          }
                        },
              ),
              if (pro.state == ProAccessState.unavailable)
                _SettingsTile(
                  icon: CupertinoIcons.refresh,
                  label: 'Retry Pro status',
                  onTap: () => pro.load(force: true),
                ),
              _SettingsTile(
                icon: CupertinoIcons.creditcard_fill,
                label: 'Preview paywall',
                onTap:
                    () => Navigator.of(context, rootNavigator: true).push(
                      CupertinoPageRoute(builder: (_) => const PaywallScreen()),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Section(title: l.sectionLanguage, children: [const _LanguageTile()]),
          const SizedBox(height: 20),
          _Section(
            title: l.sectionAccount,
            children: [
              _SettingsTile(
                icon: CupertinoIcons.bell_fill,
                label: l.labelNotifications,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Section(
            title: l.sectionApp,
            children: [
              _SettingsTile(
                icon: CupertinoIcons.info_circle_fill,
                label: l.labelAbout,
                onTap: _openAbout,
              ),
              _SettingsTile(
                icon: CupertinoIcons.hand_raised_fill,
                label: 'Privacy policy',
                onTap: () => _openExternal(ApiConfig.privacyPolicyUrl),
              ),
              _SettingsTile(
                icon: CupertinoIcons.doc_text_fill,
                label: 'Terms of use',
                onTap: () => _openExternal(ApiConfig.termsUrl),
              ),
              _SettingsTile(
                icon: CupertinoIcons.question_circle_fill,
                label: 'Support',
                onTap: () => _openExternal(ApiConfig.supportUrl),
              ),
              _SettingsTile(
                icon: CupertinoIcons.waveform_path_ecg,
                label:
                    _sendingDiagnostics
                        ? 'Sending diagnostics…'
                        : 'Send diagnostics (${DiagnosticService.instance.eventCount})',
                onTap: _sendingDiagnostics ? () {} : _sendDiagnostics,
              ),
              _SwitchTile(
                icon: CupertinoIcons.shield_lefthalf_fill,
                label: 'Share technical diagnostics automatically',
                value: _automaticDiagnostics,
                onChanged: (value) async {
                  await DiagnosticService.instance.setAutomaticUploadEnabled(
                    value,
                  );
                  if (mounted) {
                    setState(() => _automaticDiagnostics = value);
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'Helps us detect app errors. Includes only event codes, app version and platform; never email, workout content, tokens or stack traces.',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontFamily: 'Rubik',
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const _LogoutButton(),
          const SizedBox(height: 12),
          const _DeleteAccountButton(),
        ],
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
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
              fontFamily: 'Rubik',
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: children.length,
            separatorBuilder:
                (_, __) => Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: c.border,
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
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: c.textPrimary,
                  fontFamily: 'Rubik',
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 14,
              color: c.textSecondary,
            ),
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
  const _ValueTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: c.textPrimary,
                  fontFamily: 'Rubik',
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: c.textSecondary,
                fontFamily: 'Rubik',
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 14,
              color: c.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: c.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: c.textPrimary,
                fontFamily: 'Rubik',
              ),
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: c.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Language picker: System / English / Russian. Writes through LocaleController,
/// which persists the choice and re-localizes the whole app immediately.
class _LanguageTile extends StatelessWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final ctrl = context.watch<LocaleController>();
    final code = ctrl.locale?.languageCode; // null → system

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _pick(context, ctrl, l),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(CupertinoIcons.globe, size: 18, color: c.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l.labelLanguage,
                style: TextStyle(
                  fontSize: 15,
                  color: c.textPrimary,
                  fontFamily: 'Rubik',
                ),
              ),
            ),
            Text(
              _name(l, code),
              style: TextStyle(
                fontSize: 14,
                color: c.textSecondary,
                fontFamily: 'Rubik',
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 14,
              color: c.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String _name(AppLocalizations l, String? code) => switch (code) {
    'en' => l.languageEnglish,
    'ru' => l.languageRussian,
    _ => l.languageSystem,
  };

  void _pick(BuildContext context, LocaleController ctrl, AppLocalizations l) {
    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (_) => CupertinoActionSheet(
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  ctrl.setLocale(null);
                  Navigator.pop(context);
                },
                child: Text(l.languageSystem),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  ctrl.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
                child: Text(l.languageEnglish),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  ctrl.setLocale(const Locale('ru'));
                  Navigator.pop(context);
                },
                child: Text(l.languageRussian),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
    );
  }
}

class _UnitsTile extends StatelessWidget {
  const _UnitsTile();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final units = context.units;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(CupertinoIcons.gauge, size: 18, color: c.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Weight units',
              style: TextStyle(
                fontSize: 15,
                color: c.textPrimary,
                fontFamily: 'Rubik',
              ),
            ),
          ),
          SizedBox(
            width: 132,
            child: CupertinoSlidingSegmentedControl<bool>(
              groupValue: units.isLb,
              backgroundColor: c.iconBg,
              thumbColor: c.accent,
              onValueChanged: (v) => context.unitsController.setLb(v ?? false),
              children: {
                false: _seg('kg', !units.isLb, c),
                true: _seg('lb', units.isLb, c),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _seg(String label, bool active, dynamic c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: active ? c.textOnAccent : c.textSecondary,
        fontFamily: 'Rubik',
      ),
    ),
  );
}

class _BodyMetricsSheet extends StatefulWidget {
  final RankingRepository ranking;
  final RankProfile? profile;
  final void Function(RankProfile) onSaved;
  const _BodyMetricsSheet({
    required this.ranking,
    this.profile,
    required this.onSaved,
  });

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
            'Body Metrics',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
              fontFamily: 'Rubik',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricInput(
                  controller: _weightCtrl,
                  label: 'Weight (kg)',
                  placeholder: '80',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricInput(
                  controller: _heightCtrl,
                  label: 'Height (cm)',
                  placeholder: '175',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _saving ? null : _save,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: _saving ? c.iconBg : c.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child:
                      _saving
                          ? const CupertinoActivityIndicator()
                          : Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: c.textOnAccent,
                              fontFamily: 'Rubik',
                            ),
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutSheet extends StatelessWidget {
  const _AboutSheet();

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
        bottom: MediaQuery.of(context).padding.bottom + 24,
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
            'About',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
              fontFamily: 'Rubik',
            ),
          ),
          const SizedBox(height: 16),
          _Credit(
            title: 'Exercise illustrations',
            body:
                'Muscle-highlight illustrations © Everkinetic, used under '
                'the Creative Commons Attribution-ShareAlike license (CC BY-SA).',
            url: 'https://github.com/everkinetic/data',
          ),
          const SizedBox(height: 14),
          _Credit(
            title: 'Exercise data',
            body:
                'Exercise catalog based on the free-exercise-db, released '
                'into the public domain under The Unlicense.',
            url: 'https://github.com/yuhonas/free-exercise-db',
          ),
        ],
      ),
    );
  }
}

class _Credit extends StatelessWidget {
  final String title;
  final String body;
  final String url;
  const _Credit({required this.title, required this.body, required this.url});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: c.textSecondary,
            fontFamily: 'Rubik',
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: TextStyle(
            fontSize: 13,
            color: c.textPrimary,
            height: 1.4,
            fontFamily: 'Rubik',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          url,
          style: TextStyle(fontSize: 12, color: c.accent, fontFamily: 'Rubik'),
        ),
      ],
    );
  }
}

class _MetricInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  const _MetricInput({
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
            fontFamily: 'Rubik',
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 15,
            fontFamily: 'Rubik',
          ),
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

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFEF4444);
    return GestureDetector(
      onTap: () => _confirmLogout(context),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0x14EF4444),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x33EF4444), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.square_arrow_left, color: red, size: 18),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).logOut,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: red,
                fontFamily: 'Rubik',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showAppDialog<void>(
      context,
      title: 'Log Out',
      message: 'Are you sure you want to log out?',
      actions: [
        AppDialogAction('Cancel', onPressed: () => Navigator.pop(context)),
        AppDialogAction(
          'Log Out',
          isDestructive: true,
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            context.read<AuthViewModel>().logout();
          },
        ),
      ],
    );
  }
}

class _DeleteAccountButton extends StatelessWidget {
  const _DeleteAccountButton();

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFEF4444);
    return Column(
      children: [
        GestureDetector(
          onTap: () => _confirmDelete(context),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0x14EF4444),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x33EF4444), width: 1),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.trash_fill, color: red, size: 18),
                SizedBox(width: 8),
                Text(
                  'Delete Account',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: red,
                    fontFamily: 'Rubik',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Permanently deletes your workouts, exercise history and profile. This cannot be undone.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: context.colors.textSecondary,
            fontFamily: 'Rubik',
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showAppDialog<bool>(
      context,
      title: 'Delete Account',
      message:
          'This will permanently delete your account, workouts, exercise history and profile. This cannot be undone.',
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
    if (ok != true || !context.mounted) return;

    final vm = context.read<AuthViewModel>();
    await vm.deleteAccount();
    if (!context.mounted) return;

    if (vm.errorCode != null) {
      final code = vm.errorCode!;
      vm.clearError();
      showAppDialog<void>(
        context,
        title: 'Could not delete account',
        message: AppErrorCodeExt.messageFor(code),
        actions: [
          AppDialogAction(
            'OK',
            isDefault: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
