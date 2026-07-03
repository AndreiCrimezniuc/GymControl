import 'package:flutter/cupertino.dart';
import 'package:gymboss/core/errors/app_error.dart';

class ErrorBanner extends StatelessWidget {
  final String errorCode;

  const ErrorBanner(this.errorCode, {super.key});

  @override
  Widget build(BuildContext context) {
    final message = AppErrorCodeExt.messageFor(errorCode);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3D1818),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF632024), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            color: Color(0xFFFF6B6B),
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontSize: 13,
                    fontFamily: 'Rubik',
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  errorCode,
                  style: const TextStyle(
                    color: Color(0xFF8B4040),
                    fontSize: 10,
                    fontFamily: 'Rubik',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
