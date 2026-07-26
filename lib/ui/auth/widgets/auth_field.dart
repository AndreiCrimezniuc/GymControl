import 'package:flutter/cupertino.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';

class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final List<String>? autofillHints;

  const AuthField({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.iconBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border, width: 1),
      ),
      child: CupertinoTextField(
        controller: controller,
        focusNode: focusNode,
        placeholder: placeholder,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        autofillHints: autofillHints,
        autocorrect: false,
        enableSuggestions: !obscureText,
        style: TextStyle(
          color: c.textPrimary,
          fontFamily: 'Rubik',
          fontSize: 15,
        ),
        placeholderStyle: TextStyle(
          color: c.textSecondary,
          fontFamily: 'Rubik',
          fontSize: 15,
        ),
        decoration: null,
        padding: const EdgeInsets.only(left: 0, right: 16, top: 14, bottom: 14),
        prefix: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, color: c.accent, size: 18),
        ),
      ),
    );
  }
}
