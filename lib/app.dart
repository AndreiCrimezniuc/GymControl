import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:gymboss/data/repositories/auth_repository.dart';
import 'package:gymboss/data/diagnostics/diagnostic_service.dart';
import 'package:gymboss/data/services/auth/auth_service.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/services/auth/token_storage.dart';
import 'package:gymboss/data/sync/sync_service.dart';
import 'package:gymboss/ui/auth/login_screen.dart';
import 'package:gymboss/ui/auth/register_screen.dart';
import 'package:gymboss/ui/auth/widgets/gym_logo.dart';
import 'package:gymboss/ui/auth/view_model/auth_view_model.dart';
import 'package:gymboss/l10n/app_localizations.dart';
import 'package:gymboss/ui/core/locale/locale_controller.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/units/units_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_scaffold.dart';
import 'package:gymboss/ui/core/subscription/pro_controller.dart';
import 'package:gymboss/ui/home_screen/home_screen.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/resume_bar.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/workout_session_controller.dart';
import 'package:gymboss/ui/menu_options_list/workouts/widgets/workout_runner.dart';

class GymBossApp extends StatefulWidget {
  const GymBossApp({super.key});

  @override
  State<GymBossApp> createState() => _GymBossAppState();
}

class _GymBossAppState extends State<GymBossApp> {
  final _storage = TokenStorage();
  final _authService = AuthService();
  final _navKey = GlobalKey<NavigatorState>();
  late final AuthenticatedClient _client;
  late final AuthViewModel _authVm;
  late final ProController _pro;

  @override
  void initState() {
    super.initState();
    _client = AuthenticatedClient(storage: _storage, authService: _authService);
    // Drain any queued offline mutations once we have an authenticated client
    // and whenever connectivity returns.
    SyncService.instance.bind(_client);
    _authVm = AuthViewModel(
      AuthRepository(service: _authService, storage: _storage, client: _client),
    )..checkAuth();
    _pro = ProController(_client);
  }

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController(),
        ),
        ChangeNotifierProvider<UnitsController>(
          create: (_) => UnitsController(),
        ),
        ChangeNotifierProvider<WorkoutSessionController>(
          create: (_) => WorkoutSessionController(),
        ),
        ChangeNotifierProvider<LocaleController>(
          create: (_) => LocaleController(),
        ),
        ChangeNotifierProvider<AuthViewModel>.value(value: _authVm),
        ChangeNotifierProvider<ProController>.value(value: _pro),
        Provider<AuthenticatedClient>.value(value: _client),
      ],
      child: Consumer2<ThemeController, LocaleController>(
        builder: (context, theme, localeCtrl, _) {
          return CupertinoApp(
            navigatorKey: _navKey,
            theme: CupertinoThemeData(
              brightness: theme.isDark ? Brightness.dark : Brightness.light,
              scaffoldBackgroundColor: theme.colors.bg,
              textTheme: const CupertinoTextThemeData(
                textStyle: TextStyle(fontFamily: 'Rubik'),
              ),
            ),
            debugShowCheckedModeBanner: false,
            locale: localeCtrl.locale,
            supportedLocales: LocaleController.supported,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const _AuthGate(),
            // The resume bar sits *below* the app content in a Column (not as a
            // floating overlay) so every screen's content shifts up above it
            // instead of being covered — otherwise bottom inputs/buttons (e.g.
            // body metrics) become untappable while a workout is minimized.
            builder:
                (context, child) => Column(
                  children: [
                    Expanded(child: child ?? const SizedBox.shrink()),
                    Consumer<WorkoutSessionController>(
                      builder: (ctx, session, __) {
                        if (!session.isActive ||
                            !session.isMinimized ||
                            session.isFinished) {
                          return const SizedBox.shrink();
                        }
                        return SafeArea(
                          top: false,
                          child: WorkoutResumeBar(
                            session: session,
                            onTap: () {
                              session.resume();
                              _navKey.currentState?.push(
                                CupertinoPageRoute(
                                  builder: (_) => const WorkoutRunnerScreen(),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
          );
        },
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  StreamSubscription<void>? _sessionSub;
  Timer? _slowTimer;
  Timer? _stalledTimer;
  bool _slow = false;
  bool _stalled = false;
  bool _diagnosticUploadStarted = false;

  @override
  void initState() {
    super.initState();
    _startBootTimers();
  }

  void _startBootTimers() {
    _slowTimer?.cancel();
    _stalledTimer?.cancel();
    _slow = false;
    _stalled = false;
    _slowTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _slow = true);
    });
    _stalledTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _stalled = true);
    });
  }

  void _retryAuth() {
    setState(_startBootTimers);
    context.read<AuthViewModel>().checkAuth();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionSub != null) return;
    final client = context.read<AuthenticatedClient>();
    final vm = context.read<AuthViewModel>();
    _sessionSub = client.onSessionExpired.listen((_) => vm.logout());
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _slowTimer?.cancel();
    _stalledTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (ctx, vm, _) {
        if (vm.status == AuthStatus.unknown) {
          return AppScaffold(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const GymLogo(),
                    const SizedBox(height: 28),
                    const CupertinoActivityIndicator(radius: 12),
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _slow
                            ? 'Restoring your session…'
                            : 'Getting things ready…',
                        key: ValueKey(_slow),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontFamily: 'Rubik',
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (_stalled) ...[
                      const SizedBox(height: 12),
                      Text(
                        'This is taking longer than expected.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontFamily: 'Rubik',
                          fontSize: 13,
                        ),
                      ),
                      CupertinoButton(
                        onPressed: _retryAuth,
                        child: const Text('Try again'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }
        _slowTimer?.cancel();
        _stalledTimer?.cancel();
        if (vm.status == AuthStatus.authenticated) {
          context.read<ProController>().load();
          if (!_diagnosticUploadStarted) {
            _diagnosticUploadStarted = true;
            unawaited(
              DiagnosticService.instance.tryAutomaticSend(
                context.read<AuthenticatedClient>(),
              ),
            );
          }
          return const HomeScreen();
        }
        _diagnosticUploadStarted = false;
        return const _AuthFlow();
      },
    );
  }
}

class _AuthFlow extends StatefulWidget {
  const _AuthFlow();

  @override
  State<_AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<_AuthFlow> {
  bool _showLogin = true;

  @override
  Widget build(BuildContext context) {
    if (_showLogin) {
      return LoginScreen(
        onGoToRegister: () => setState(() => _showLogin = false),
      );
    }
    return RegisterScreen(onGoToLogin: () => setState(() => _showLogin = true));
  }
}
