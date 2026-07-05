import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:gymboss/data/repositories/auth_repository.dart';
import 'package:gymboss/data/services/auth/auth_service.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/services/auth/token_storage.dart';
import 'package:gymboss/ui/auth/login_screen.dart';
import 'package:gymboss/ui/auth/register_screen.dart';
import 'package:gymboss/ui/auth/view_model/auth_view_model.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_scaffold.dart';
import 'package:gymboss/ui/home_screen/home_screen.dart';

class GymBossApp extends StatefulWidget {
  const GymBossApp({super.key});

  @override
  State<GymBossApp> createState() => _GymBossAppState();
}

class _GymBossAppState extends State<GymBossApp> {
  final _storage = TokenStorage();
  final _authService = AuthService();
  late final AuthenticatedClient _client;
  late final AuthViewModel _authVm;

  @override
  void initState() {
    super.initState();
    _client = AuthenticatedClient(storage: _storage, authService: _authService);
    _authVm = AuthViewModel(
      AuthRepository(service: _authService, storage: _storage),
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
        ChangeNotifierProvider<ThemeController>(create: (_) => ThemeController()),
        ChangeNotifierProvider<AuthViewModel>.value(value: _authVm),
        Provider<AuthenticatedClient>.value(value: _client),
      ],
      child: Consumer<ThemeController>(
        builder: (context, theme, _) {
          return CupertinoApp(
            theme: CupertinoThemeData(
              brightness: theme.isDark ? Brightness.dark : Brightness.light,
              scaffoldBackgroundColor: theme.colors.bg,
              textTheme: const CupertinoTextThemeData(
                textStyle: TextStyle(fontFamily: 'Rubik'),
              ),
            ),
            debugShowCheckedModeBanner: false,
            home: const _AuthGate(),
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
    return RegisterScreen(
      onGoToLogin: () => setState(() => _showLogin = true),
    );
  }
}
