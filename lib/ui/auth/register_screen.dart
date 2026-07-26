import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:gymboss/core/errors/app_error.dart';
import 'package:gymboss/ui/auth/view_model/auth_view_model.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_scaffold.dart';
import 'package:gymboss/ui/auth/widgets/auth_card.dart';
import 'package:gymboss/ui/auth/widgets/auth_field.dart';
import 'package:gymboss/ui/auth/widgets/error_banner.dart';
import 'package:gymboss/ui/auth/widgets/gradient_button.dart';
import 'package:gymboss/ui/auth/widgets/gym_logo.dart';
import 'package:gymboss/ui/auth/widgets/social_button.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onGoToLogin;
  const RegisterScreen({super.key, required this.onGoToLogin});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();
  String? _localError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _submit(AuthViewModel vm) {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      setState(() => _localError = AppErrorCode.validationRequired.code);
      return;
    }
    if (pass.length < 8) {
      setState(
        () => _localError = AppErrorCode.validationPasswordTooShort.code,
      );
      return;
    }
    if (pass != confirm) {
      setState(
        () => _localError = AppErrorCode.validationPasswordMismatch.code,
      );
      return;
    }

    setState(() => _localError = null);
    vm.clearError();
    vm.register(email, pass);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (ctx, vm, _) {
        final errorMsg = _localError ?? vm.errorCode;
        return AppScaffold(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),
                const GymLogo(),
                const SizedBox(height: 40),
                AuthCard(
                  children: [
                    Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: ctx.colors.textPrimary,
                        fontFamily: 'Rubik',
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
                            placeholder: 'Password (min 8 chars)',
                            icon: CupertinoIcons.lock_fill,
                            obscureText: true,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            onSubmitted: (_) => _confirmFocus.requestFocus(),
                          ),
                          const SizedBox(height: 14),
                          AuthField(
                            controller: _confirmCtrl,
                            focusNode: _confirmFocus,
                            placeholder: 'Confirm Password',
                            icon: CupertinoIcons.lock_shield_fill,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            onSubmitted: (_) => _submit(vm),
                          ),
                        ],
                      ),
                    ),
                    if (errorMsg != null) ...[
                      const SizedBox(height: 12),
                      ErrorBanner(errorMsg),
                    ],
                    const SizedBox(height: 28),
                    GradientButton(
                      label: 'Create Account',
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
                      onPressed: widget.onGoToLogin,
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Rubik',
                            color: ctx.colors.textSecondary,
                          ),
                          children: [
                            const TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Sign In',
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
        );
      },
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
            style: TextStyle(
              color: c.textSecondary,
              fontFamily: 'Rubik',
              fontSize: 13,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: c.border)),
      ],
    );
  }
}
