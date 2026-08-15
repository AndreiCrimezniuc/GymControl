import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:gymboss/config/api_config.dart';
import 'package:gymboss/ui/auth/view_model/auth_view_model.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
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
  final _passFocus = FocusNode();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _passFocus.dispose();
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
                      Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: ctx.colors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 28),
                      AutofillGroup(
                        child: Column(
                          children: [
                            AuthField(
                              controller: _emailCtrl,
                              placeholder: 'Email',
                              icon: CupertinoIcons.envelope_fill,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.username],
                              onSubmitted: (_) => _passFocus.requestFocus(),
                            ),
                            const SizedBox(height: 14),
                            AuthField(
                              controller: _passCtrl,
                              focusNode: _passFocus,
                              placeholder: 'Password',
                              icon: CupertinoIcons.lock_fill,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onSubmitted: (_) => _submit(vm),
                            ),
                          ],
                        ),
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
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: ctx.colors.textSecondary,
                            ),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: 'Register',
                                style: TextStyle(
                                  color: ctx.colors.accent,
                                  fontWeight: FontWeight.w700,
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
    final c = context.colors;
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: c.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(color: c.textSecondary, fontSize: 13),
          ),
        ),
        Expanded(child: Container(height: 1, color: c.border)),
      ],
    );
  }
}
