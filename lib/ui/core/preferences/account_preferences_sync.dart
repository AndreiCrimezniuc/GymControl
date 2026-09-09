import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:gymboss/data/repositories/ranking_repository.dart';
import 'package:gymboss/domain/models/training/training_prescription.dart';
import 'package:gymboss/ui/core/locale/locale_controller.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/training/training_preferences_controller.dart';
import 'package:gymboss/ui/core/units/units_controller.dart';

/// Keeps account-wide presentation and calculation preferences in the profile
/// endpoint. Each controller remains durable locally for instant/offline use;
/// this bridge makes the server copy authoritative after authentication and
/// queues later changes through the normal local-first mutation ledger.
class AccountPreferencesSync {
  final RankingRepository _ranking;
  final ThemeController _theme;
  final LocaleController _locale;
  final UnitsController _units;
  final TrainingPreferencesController _training;
  bool _applyingRemote = false;
  bool _listening = false;

  AccountPreferencesSync({
    required RankingRepository ranking,
    required ThemeController theme,
    required LocaleController locale,
    required UnitsController units,
    required TrainingPreferencesController training,
  }) : _ranking = ranking,
       _theme = theme,
       _locale = locale,
       _units = units,
       _training = training;

  /// Returns true only once the server copy has been applied. An offline
  /// launch keeps local preferences and deliberately retries next foreground.
  Future<bool> hydrate() async {
    await Future.wait([
      _theme.restored,
      _locale.ready,
      _units.ready,
      _training.ready,
    ]);
    if (!await _ranking.isOnline) {
      _attach();
      return false;
    }
    final profile = await (() async {
      try {
        return await _ranking.getProfile(forceRefresh: true);
      } catch (_) {
        _attach();
        return null;
      }
    })();
    if (profile == null) return false;
    // A brand-new offline installation has no server document yet. Never
    // replace a real local choice with defaults solely because it is offline.
    if (profile.updatedAt.year <= 2000) {
      _attach();
      return false;
    }
    _applyingRemote = true;
    try {
      await Future.wait([
        _theme.applyRemote(
          isDark: profile.appearanceDark,
          lightAccent: _accent(profile.lightAccent),
          darkAccent: _accent(profile.darkAccent),
        ),
        _locale.applyRemote(
          profile.locale == null ? null : Locale(profile.locale!),
        ),
        _units.applyRemote(isLb: profile.unit == 'lb'),
        _training.applyRemote(
          formula: _formula(profile.oneRmFormula),
          deloadFactor: profile.deloadFactor,
        ),
      ]);
    } finally {
      _applyingRemote = false;
    }
    _attach();
    return true;
  }

  void _attach() {
    if (_listening) return;
    _listening = true;
    _theme.addListener(_queueAppearance);
    _locale.addListener(_queueLocale);
    _units.addListener(_queueUnits);
    _training.addListener(_queueTraining);
  }

  void dispose() {
    if (!_listening) return;
    _theme.removeListener(_queueAppearance);
    _locale.removeListener(_queueLocale);
    _units.removeListener(_queueUnits);
    _training.removeListener(_queueTraining);
    _listening = false;
  }

  void _queueAppearance() {
    if (_applyingRemote) return;
    unawaited(
      _ranking.updateProfile(
        appearanceDark: _theme.isDark,
        lightAccent: _theme.lightAccent.name,
        darkAccent: _theme.darkAccent.name,
      ),
    );
  }

  void _queueLocale() {
    if (_applyingRemote) return;
    // An explicit system sentinel preserves the distinction between “follow
    // this phone” and “force English” across devices.
    unawaited(
      _ranking.updateProfile(locale: _locale.locale?.languageCode ?? 'system'),
    );
  }

  void _queueUnits() {
    if (_applyingRemote) return;
    unawaited(_ranking.updateProfile(unit: _units.label));
  }

  void _queueTraining() {
    if (_applyingRemote) return;
    unawaited(
      _ranking.updateProfile(
        oneRmFormula: _training.formula.name,
        deloadFactor: _training.deloadFactor,
      ),
    );
  }

  static AppAccent _accent(String value) => AppAccent.values.firstWhere(
    (item) => item.name == value,
    orElse: () => AppAccent.red,
  );

  static OneRmFormula _formula(String value) => OneRmFormula.values.firstWhere(
    (item) => item.name == value,
    orElse: () => OneRmFormula.epley,
  );
}
