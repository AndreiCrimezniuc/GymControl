import 'package:flutter/cupertino.dart';

class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;

  const AuthField({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162534),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E3A50), width: 1),
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        obscureText: obscureText,
        keyboardType: keyboardType,
        autocorrect: false,
        style: const TextStyle(
          color: CupertinoColors.white,
          fontFamily: 'Rubik',
          fontSize: 15,
        ),
        placeholderStyle: const TextStyle(
          color: Color(0xFF546A7B),
          fontFamily: 'Rubik',
          fontSize: 15,
        ),
        decoration: null,
        padding: const EdgeInsets.only(left: 0, right: 16, top: 14, bottom: 14),
        prefix: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, color: const Color(0xFF3B82F6), size: 18),
        ),
      ),
    );
  }
}
