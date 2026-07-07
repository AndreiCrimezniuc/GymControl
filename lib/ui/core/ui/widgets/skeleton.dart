import 'package:flutter/cupertino.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';

/// A shimmering placeholder block used while content loads. Reads nicer than a
/// bare spinner because it previews the shape of what's coming.
class Skeleton extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final double opacity;
  const Skeleton({super.key, this.width, this.height = 14, this.radius = 8, this.opacity = 1});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: c.iconBg, borderRadius: BorderRadius.circular(radius)),
      ),
    );
  }
}

/// A pulsing list of card-shaped skeletons for a loading list screen.
class SkeletonList extends StatefulWidget {
  final int rows;
  final double rowHeight;
  const SkeletonList({super.key, this.rows = 7, this.rowHeight = 74});

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final o = 0.55 + 0.45 * Curves.easeInOut.transform(_ctrl.value);
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.rows,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, __) => Opacity(
            opacity: o,
            child: Container(
              height: widget.rowHeight,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: widget.rowHeight - 24,
                    height: widget.rowHeight - 24,
                    decoration: BoxDecoration(color: c.iconBg, borderRadius: BorderRadius.circular(12)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Skeleton(width: 160, height: 13, radius: 6),
                        const SizedBox(height: 8),
                        Skeleton(width: 90, height: 11, radius: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
