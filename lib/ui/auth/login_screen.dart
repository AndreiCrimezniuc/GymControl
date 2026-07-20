import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:gymboss/config/api_config.dart';
import 'package:gymboss/ui/auth/view_model/auth_view_model.dart';
import 'package:gymboss/ui/core/ui/widgets/app_scaffold.dart';
import 'package:gymboss/ui/auth/widgets/auth_card.dart';
import 'package:gymboss/ui/auth/widgets/auth_field.dart';
import 'package:gymboss/ui/auth/widgets/error_banner.dart';
import 'package:gymboss/ui/auth/widgets/gradient_button.dart';
import 'package:gymboss/ui/auth/widgets/gym_logo.dart';
import 'package:gymboss/ui/auth/widgets/social_button.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onGoToRegister;
  const LoginScreen({super.key, required this.onGoToRegister});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // Dev-only quick login: typing "test" as the email signs into the shared
  // test account without a password. Gated to the dev backend so it never
  // ships in a prod build.
  static const _testAccountEmail = 'kib69dev19@gmail.com';
  static const _testAccountPassword = 'gymboss-test-2026';

  void _submit(AuthViewModel vm) {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (ApiConfig.isDev && email.toLowerCase() == 'test') {
      vm.login(_testAccountEmail, _testAccountPassword);
      return;
    }

    if (email.isEmpty || pass.isEmpty) return;
    vm.login(email, pass);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder:
          (ctx, vm, _) => AppScaffold(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 64),
                  const GymLogo(),
                  const SizedBox(height: 48),
                  AuthCard(
                    children: [
                      const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: CupertinoColors.white,
                          fontFamily: 'Rubik',
                        ),
                      ),
                      const SizedBox(height: 28),
                      AuthField(
                        controller: _emailCtrl,
                        placeholder: 'Email',
                        icon: CupertinoIcons.envelope_fill,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      AuthField(
                        controller: _passCtrl,
                        placeholder: 'Password',
                        icon: CupertinoIcons.lock_fill,
                        obscureText: true,
                      ),
                      if (vm.errorCode != null) ...[
                        const SizedBox(height: 12),
                        ErrorBanner(vm.errorCode!),
                      ],
                      const SizedBox(height: 28),
                      GradientButton(
                        label: 'Sign In',
                        loading: vm.loading,
                        onTap: () => _submit(vm),
                      ),
                      const SizedBox(height: 16),
                      SocialButton(
                        label: 'Continue with Google',
                        loading: vm.loading,
                        onTap: () => vm.loginWithGoogle(),
                        icon: const GoogleIcon(),
                      ),
                      const SizedBox(height: 20),
                      _Divider(),
                      const SizedBox(height: 16),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: widget.onGoToRegister,
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Rubik',
                              color: Color(0xFF8B9EAE),
                            ),
                            children: [
                              TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: 'Register',
                                style: TextStyle(
                                  color: Color(0xFF06B6D4),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0xFF1E3A50))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(
              color: Color(0xFF546A7B),
              fontFamily: 'Rubik',
              fontSize: 13,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: const Color(0xFF1E3A50))),
      ],
    );
  }
}
