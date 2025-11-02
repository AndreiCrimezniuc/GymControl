import 'package:flutter/cupertino.dart';

class OptionButtonMenu extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  // final Widget rightSubIcon;
  final VoidCallback callBack;
  final Color backgroundColor;
  final Color borderColor;

  const OptionButtonMenu({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.borderColor,
    // required this.rightSubIcon,
    required this.backgroundColor,
    required this.callBack,
  });

  @override
  Widget build(context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: callBack,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 3),
          // boxShadow: [
          //   BoxShadow(
          //     color: Color(0xFF632024),
          //     blurRadius: 2,
          //     spreadRadius: 2,
          //     offset: const Offset(2, 2),
          // ),
          // ],
        ),
        child: Row(
          children: [
            icon,
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_forward,
              size: 20,
              color: CupertinoColors.systemGrey,
            ),
          ],
        ),
      ),
    );
  }
}
