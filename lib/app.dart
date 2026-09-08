import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:gymboss/data/repositories/auth_repository.dart';
import 'package:gymboss/data/repositories/exercises_repository.dart';
import 'package:gymboss/data/repositories/measurements_repository.dart';
import 'package:gymboss/data/repositories/ranking_repository.dart';
import 'package:gymboss/data/repositories/sessions_repository.dart';
import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/data/diagnostics/diagnostic_service.dart';
import 'package:gymboss/data/services/auth/auth_service.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/services/auth/token_storage.dart';
import 'package:gymboss/data/sync/sync_service.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';
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
import 'package:gymboss/ui/menu_options_list/workouts/session/workout_live_activity.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/workout_session_controller.dart';
import 'package:gymboss/ui/menu_options_list/workouts/widgets/workout_runner.dart';

class GymControlApp extends StatefulWidget {
  const GymControlApp({super.key});

  @override
  State<GymControlApp> createState() => _GymControlAppState();
}

class _GymControlAppState extends State<GymControlApp>
    with WidgetsBindingObserver {
  final _storage = TokenStorage();
  final _authService = AuthService();
  final _navKey = GlobalKey<NavigatorState>();
  late final AuthenticatedClient _client;
  late final AuthViewModel _authVm;
  late final ProController _pro;
  late final ExercisesRepository _exercises;
  late final WorkoutsRepository _workouts;
  late final MeasurementsRepository _measurements;
  late final RankingRepository _ranking;
  late final SessionsRepository _sessions;
  late final UnitsController _units;
  late final WorkoutSessionController _session;
  Future<void> _sessionSync = Future.value();
  bool _restoreAttempted = false;
  bool _cacheWarmStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _client = AuthenticatedClient(storage: _storage, authService: _authService);
    // Register every mutation handler eagerly. Repositories are otherwise
    // created lazily by screens, which could leave durable changes blocked
    // after a cold start until the user happened to revisit that screen.
    _workouts = WorkoutsRepository(client: _client);
    _exercises = ExercisesRepository(client: _client);
    _measurements = MeasurementsRepository(client: _client);
    _ranking = RankingRepository(client: _client);
    _sessions = SessionsRepository(client: _client);
    // Drain any queued offline mutations once we have an authenticated client
    // and whenever connectivity returns.
    SyncService.instance.bind(_client);
    _authVm = AuthViewModel(
      AuthRepository(service: _authService, storage: _storage, client: _client),
    );
    _pro = ProController(_client);
    _units = UnitsController();
    _session = WorkoutSessionController();
    _authVm.addListener(_queueSessionSync);
    unawaited(_authVm.checkAuth());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queueSessionSync();
    });
  }

  void _queueSessionSync() {
    _sessionSync = _sessionSync.then((_) => _syncSessionWithAuth());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // ActivityKit outlives the Flutter process. Retry reconciliation every
      // time the app becomes interactive so an interrupted best-effort end
      // can never leave a timer running without a local workout.
      _queueSessionSync();
    }
  }

  Future<void> _syncSessionWithAuth() async {
    final status = _authVm.status;
    if (status != AuthStatus.authenticated) {
      if (status == AuthStatus.unauthenticated) {
        _restoreAttempted = false;
        _cacheWarmStarted = false;
        if (_session.isActive) _session.clear();
      }
      await WorkoutLiveActivity.end();
      return;
    }
    if (_session.isActive) return;
    // Reconcile even after the one allowed restore attempt. A Live Activity
    // can survive a killed/suspended process while local state is already
    // gone, so every later foreground transition must retry this cleanup.
    await WorkoutLiveActivity.end();
    if (_restoreAttempted) return;
    _restoreAttempted = true;
    await _session.restore(
      exercises: _exercises,
      ranking: _ranking,
      sessions: _sessions,
      workouts: _workouts,
      units: _units,
    );
    if (!_cacheWarmStarted) {
      _cacheWarmStarted = true;
      unawaited(_warmOfflineCache());
    }
  }

  /// Hydrates every core local snapshot after authentication. Failures are
  /// isolated because this is background preparation, never a launch gate.
  Future<void> _warmOfflineCache() async {
    Future<T?> safe<T>(Future<T> Function() load) async {
      try {
        return await load();
      } catch (_) {
        return null;
      }
    }

    Future<void> bounded<T>(
      Iterable<T> items,
      int concurrency,
      Future<void> Function(T item) run,
    ) async {
      final iterator = items.iterator;
      Future<void> worker() async {
        while (iterator.moveNext()) {
          await run(iterator.current);
        }
      }

      await Future.wait(List.generate(concurrency, (_) => worker()));
    }

    final results = await Future.wait([
      safe(() => _workouts.listOwned(forceRefresh: true)),
      safe(() => _workouts.listFolders(forceRefresh: true)),
      safe(() => _exercises.getCatalog(forceRefresh: true)),
      safe(() => _measurements.list(forceRefresh: true)),
      safe(() => _ranking.getProfile(forceRefresh: true)),
      safe(() => _ranking.getUserRanks(forceRefresh: true)),
      safe(() => _sessions.getStreakData(forceRefresh: true)),
      safe(() => _workouts.statsSummary(period: 'all', forceRefresh: true)),
      safe(() => _workouts.statsSummary(period: 'year', forceRefresh: true)),
      safe(() => _workouts.activity(period: 'all', forceRefresh: true)),
      safe(() => _workouts.activity(period: 'year', forceRefresh: true)),
      safe(() => _pro.load(force: true)),
    ]);
    final owned = results.first;
    if (owned is! List<Workout>) return;
    // Warm each routine once with bounded concurrency. Exercise analytics are
    // deduplicated across routines; otherwise a large library can issue the
    // same two requests hundreds of times and trip its own rate limit.
    final fullWorkouts = <Workout>[];
    await bounded<Workout>(owned, 3, (workout) async {
      final full = await safe(
        () => _workouts.get(workout.id, forceRefresh: true),
      );
      if (full != null) fullWorkouts.add(full);
    });
    final exerciseIds = fullWorkouts
        .expand((workout) => workout.exercises)
        .map((exercise) => exercise.exerciseId)
        .toSet();
    await bounded<int>(exerciseIds, 4, (id) async {
      await Future.wait([
        safe(() => _exercises.getStats(id, forceRefresh: true)),
        safe(() => _exercises.getHistory(id, forceRefresh: true)),
      ]);
    });
    await bounded<Workout>(fullWorkouts, 3, (workout) async {
      final stats = await safe(
        () => _workouts.stats(workout.id, forceRefresh: true),
      );
      if (stats == null) return;
      // Five exact recent sessions are enough to train for weeks offline while
      // keeping first-sign-in bandwidth bounded for long-lived accounts.
      for (final run in stats.history.take(5)) {
        await safe(
          () => _workouts.runDetail(
            workout.id,
            run.date,
            sessionId: run.sessionId,
            forceRefresh: true,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authVm.removeListener(_queueSessionSync);
    _client.dispose();
    _session.dispose();
    _units.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController(),
        ),
        ChangeNotifierProvider<UnitsController>.value(value: _units),
        ChangeNotifierProvider<WorkoutSessionController>.value(value: _session),
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
              brightness: theme.colors.usesLightForeground
                  ? Brightness.dark
                  : Brightness.light,
              scaffoldBackgroundColor: theme.colors.bg,
              primaryColor: theme.colors.accent,
              barBackgroundColor: theme.colors.card,
              textTheme: CupertinoTextThemeData(
                textStyle: TextStyle(
                  color: theme.colors.textPrimary,
                  fontSize: 16,
                  letterSpacing: -0.2,
                ),
                navTitleTextStyle: TextStyle(
                  color: theme.colors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.35,
                ),
                actionTextStyle: TextStyle(
                  color: theme.colors.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
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
            builder: (context, child) => Column(
              children: [
                Expanded(child: child ?? const SizedBox.shrink()),
                Consumer2<WorkoutSessionController, AuthViewModel>(
                  builder: (ctx, session, auth, __) {
                    if (!session.isActive ||
                        auth.status != AuthStatus.authenticated ||
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
  bool _proLoadStarted = false;

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
        final l10n = AppLocalizations.of(context);
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
                        _slow ? l10n.restoringSession : l10n.gettingReady,
                        key: ValueKey(_slow),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (_stalled) ...[
                      const SizedBox(height: 12),
                      Text(
                        l10n.takingLonger,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      CupertinoButton(
                        onPressed: _retryAuth,
                        child: Text(l10n.tryAgain),
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
          if (!_proLoadStarted) {
            _proLoadStarted = true;
            // ProController notifies listeners as loading begins. Starting it
            // after this frame avoids mutating Provider state during build.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                unawaited(context.read<ProController>().load());
              }
            });
          }
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
        _proLoadStarted = false;
        _diagnosticUploadStarted = false;
        final session = context.read<WorkoutSessionController>();
        if (session.isActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) => session.clear());
        }
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
