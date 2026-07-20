import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/pressable.dart';

/// One button in a themed dialog. [onPressed] is responsible for closing the
/// dialog (usually `Navigator.pop(context, ...)`), mirroring how Cupertino
/// dialog actions behave.
class AppDialogAction {
  final String label;
  final VoidCallback? onPressed;
  final bool isDefault;
  final bool isDestructive;
  const AppDialogAction(
    this.label, {
    this.onPressed,
    this.isDefault = false,
    this.isDestructive = false,
  });
}

/// A theme-aware replacement for [CupertinoAlertDialog] — uses the app palette
/// (card surface, accent, text tokens) instead of the OS default chrome.
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required String title,
  String? message,
  Widget? content,
  List<AppDialogAction> actions = const [],
  bool barrierDismissible = true,
}) {
  return showCupertinoDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder:
        (_) => _AppDialog(
          title: title,
          message: message,
          content: content,
          actions: actions,
        ),
  );
}

class _AppDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final List<AppDialogAction> actions;
  const _AppDialog({
    required this.title,
    this.message,
    this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final width = math.min(360.0, MediaQuery.of(context).size.width - 56);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: width,
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: c.border),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x40000000),
                  blurRadius: 40,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                    fontFamily: 'Rubik',
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: c.textSecondary,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ],
                if (content != null) ...[const SizedBox(height: 14), content!],
                const SizedBox(height: 18),
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _DialogButton(action: actions[i], colors: c),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final AppDialogAction action;
  final AppColors colors;
  const _DialogButton({required this.action, required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    late final Color bg;
    late final Color fg;
    if (action.isDefault) {
      bg = c.accent;
      fg = c.textOnAccent;
    } else if (action.isDestructive) {
      bg = c.accent.withValues(alpha: 0.12);
      fg = c.accent;
    } else {
      bg = c.iconBg;
      fg = c.textPrimary;
    }
    return Pressable(
      onTap: action.onPressed,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Text(
          action.label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: fg,
            fontFamily: 'Rubik',
          ),
        ),
      ),
    );
  }
}

/// One row in a themed action sheet.
class AppSheetAction {
  final String label;
  final VoidCallback? onPressed;
  final bool isDestructive;
  const AppSheetAction(
    this.label, {
    this.onPressed,
    this.isDestructive = false,
  });
}

/// A theme-aware replacement for [CupertinoActionSheet].
Future<void> showAppActionSheet(
  BuildContext context, {
  String? title,
  required List<AppSheetAction> actions,
}) {
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => _AppActionSheet(title: title, actions: actions),
  );
}

class _AppActionSheet extends StatelessWidget {
  final String? title;
  final List<AppSheetAction> actions;
  const _AppActionSheet({this.title, required this.actions});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.border),
            ),
            child: Column(
              children: [
                if (title != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Text(
                      title!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: c.textSecondary,
                        fontFamily: 'Rubik',
                      ),
                    ),
                  ),
                  Container(height: 1, color: c.border),
                ],
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) Container(height: 1, color: c.border),
                  _sheetRow(c, actions[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          _sheetRow(
            c,
            AppSheetAction('Cancel', onPressed: () => Navigator.pop(context)),
            standalone: true,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _sheetRow(
    AppColors c,
    AppSheetAction a, {
    bool standalone = false,
    bool bold = false,
  }) {
    final color = a.isDestructive ? c.accent : c.textPrimary;
    final row = Pressable(
      onTap: a.onPressed,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration:
            standalone
                ? BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.border),
                )
                : null,
        child: Text(
          a.label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: color,
            fontFamily: 'Rubik',
          ),
        ),
      ),
    );
    return row;
  }
}
