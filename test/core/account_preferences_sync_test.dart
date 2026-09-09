import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymboss/data/local/local_store.dart';
import 'package:gymboss/data/repositories/ranking_repository.dart';
import 'package:gymboss/data/services/auth/auth_service.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/services/auth/token_storage.dart';
import 'package:gymboss/domain/models/training/training_prescription.dart';
import 'package:gymboss/ui/core/locale/locale_controller.dart';
import 'package:gymboss/ui/core/preferences/account_preferences_sync.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/training/training_preferences_controller.dart';
import 'package:gymboss/ui/core/units/units_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final store = LocalStore.instance;

  setUpAll(() async {
    final directory = Directory.systemTemp.createTempSync(
      'gymboss_preferences',
    );
    await store.init(path: directory.path);
  });

  setUp(() async {
    await store.clear();
    SharedPreferences.setMockInitialValues(const {});
  });

  test('account profile hydrates every cross-device preference', () async {
    final client = AuthenticatedClient(
      storage: TokenStorage(),
      authService: AuthService(),
      inner: MockClient((request) async {
        expect(request.url.path, endsWith('/rankings/profile'));
        return http.Response(
          jsonEncode({
            'appearance_dark': true,
            'light_accent': 'purple',
            'dark_accent': 'green',
            'locale': 'ru',
            'unit': 'lb',
            'one_rm_formula': 'wathan',
            'deload_factor': .6,
            'dont_ask_weight': false,
            'updated_at': '2026-09-09T00:00:00Z',
          }),
          200,
        );
      }),
    );
    addTearDown(client.dispose);
    final theme = ThemeController();
    final locale = LocaleController();
    final units = UnitsController();
    final training = TrainingPreferencesController();
    addTearDown(theme.dispose);
    addTearDown(locale.dispose);
    addTearDown(units.dispose);
    addTearDown(training.dispose);
    final sync = AccountPreferencesSync(
      ranking: RankingRepository(client: client, isOnline: () async => true),
      theme: theme,
      locale: locale,
      units: units,
      training: training,
    );
    addTearDown(sync.dispose);

    expect(await sync.hydrate(), isTrue);
    expect(theme.isDark, isTrue);
    expect(theme.lightAccent, AppAccent.purple);
    expect(theme.darkAccent, AppAccent.green);
    expect(locale.locale, const Locale('ru'));
    expect(units.isLb, isTrue);
    expect(training.formula, OneRmFormula.wathan);
    expect(training.deloadFactor, .6);

    await units.setLb(false);
    await Future<void>.delayed(Duration.zero);
    expect(
      store.pending().any(
        (mutation) =>
            mutation.kind == 'ranking.profile' && mutation.args['unit'] == 'kg',
      ),
      isTrue,
    );
  });
}
