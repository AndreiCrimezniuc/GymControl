import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// Wraps a tappable widget with tactile press feedback: a subtle scale-down on
/// press-in, released with a strong ease-out curve, plus a light haptic tick.
/// Applies Emil Kowalski's "buttons must feel responsive" principle — the
/// interface acknowledges the press the moment the finger lands.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;

  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.97, this.haptic = true});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!();
            },
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 140),
        // Strong ease-out (cubic-bezier(0.23, 1, 0.32, 1)) — snappy release.
        curve: const Cubic(0.23, 1, 0.32, 1),
        child: widget.child,
      ),
    );
  }
}
