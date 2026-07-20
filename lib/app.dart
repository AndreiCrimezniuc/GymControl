import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:gymboss/data/repositories/auth_repository.dart';
import 'package:gymboss/data/services/auth/auth_service.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/services/auth/token_storage.dart';
import 'package:gymboss/data/sync/sync_service.dart';
import 'package:gymboss/ui/auth/login_screen.dart';
import 'package:gymboss/ui/auth/register_screen.dart';
import 'package:gymboss/ui/auth/view_model/auth_view_model.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/units/units_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_scaffold.dart';
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
        ChangeNotifierProvider<AuthViewModel>.value(value: _authVm),
        Provider<AuthenticatedClient>.value(value: _client),
      ],
      child: Consumer<ThemeController>(
        builder: (context, theme, _) {
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
            home: const _AuthGate(),
            builder: (context, child) => Stack(
              children: [
                child ?? const SizedBox.shrink(),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Consumer<WorkoutSessionController>(
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (ctx, vm, _) {
        if (vm.status == AuthStatus.unknown) {
          return const AppScaffold(
            child: Center(child: CupertinoActivityIndicator()),
          );
        }
        if (vm.status == AuthStatus.authenticated) {
          return const HomeScreen();
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
