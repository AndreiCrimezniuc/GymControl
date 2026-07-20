import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/net_image.dart';
import 'package:gymboss/ui/menu_options_list/exercises/widgets/exercise_mannequin.dart';

/// Which body region an exercise works. Used to highlight our own drawn figure
/// instead of shipping stock demonstration photos.
enum MuscleZone {
  chest,
  shoulders,
  arms,
  core,
  back,
  legs,
  glutes,
  calves,
  fullBody,
}

/// Maps a free-form muscle-group string (from the catalog) to a drawable zone.
MuscleZone zoneForMuscle(String raw) {
  final m = raw.toLowerCase();
  bool has(List<String> keys) => keys.any(m.contains);
  if (has(['chest', 'pec'])) return MuscleZone.chest;
  if (has(['shoulder', 'delt', 'trap', 'neck'])) return MuscleZone.shoulders;
  if (has(['bicep', 'tricep', 'forearm', 'arm'])) return MuscleZone.arms;
  if (has(['ab', 'core', 'oblique', 'waist'])) return MuscleZone.core;
  if (has(['lat', 'back'])) return MuscleZone.back;
  if (has(['glute', 'hip'])) return MuscleZone.glutes;
  if (has(['calf', 'calve'])) return MuscleZone.calves;
  if (has(['quad', 'hamstring', 'leg', 'adductor', 'abductor', 'thigh'])) {
    return MuscleZone.legs;
  }
  return MuscleZone.fullBody;
}

/// Decides what to show for an exercise: our own drawn muscle map for catalog
/// exercises (never a stock photo), or the user's uploaded image for a custom
/// exercise that has one. Frames it in a rounded, themed tile.
class ExerciseVisual extends StatelessWidget {
  final String name;
  final String muscleGroup;
  final String equipment;
  final String category;
  final String imageUrl;
  final String imageUrl2;
  final bool animate;
  final double radius;
  final double figurePadding;
  const ExerciseVisual({
    super.key,
    this.name = '',
    required this.muscleGroup,
    this.equipment = '',
    required this.category,
    required this.imageUrl,
    this.imageUrl2 = '',
    this.animate = false,
    this.radius = 12,
    this.figurePadding = 6,
  });

  bool get _custom => category.toLowerCase() == 'custom';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mannequin = ExerciseMannequin(
      pattern: patternFor(
        name: name,
        muscle: muscleGroup,
        equipment: equipment,
      ),
      animate: animate,
    );

    Widget child;
    if (_custom && imageUrl.isNotEmpty) {
      // user-uploaded custom image
      child = NetImage(
        url: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: 640,
        fallback: (_) => mannequin,
      );
    } else if (!_custom && imageUrl.isNotEmpty) {
      // Everkinetic 2-frame muscle-highlight illustration
      child = Padding(
        padding: EdgeInsets.all(figurePadding * 0.6),
        child: _TwoFrame(
          url1: imageUrl,
          url2: imageUrl2,
          animate: animate,
          fallback: mannequin,
        ),
      );
    } else {
      child = Padding(padding: EdgeInsets.all(figurePadding), child: mannequin);
    }

    return Semantics(
      image: true,
      label: name.isNotEmpty ? '$name demonstration' : 'Exercise demonstration',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          color: c.iconBg,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

/// Alternates two illustration frames (relaxation ↔ tension) to animate the
/// movement; holds the first frame when [animate] is false.
class _TwoFrame extends StatefulWidget {
  final String url1;
  final String url2;
  final bool animate;
  final Widget fallback;
  const _TwoFrame({
    required this.url1,
    required this.url2,
    required this.animate,
    required this.fallback,
  });

  @override
  State<_TwoFrame> createState() => _TwoFrameState();
}

class _TwoFrameState extends State<_TwoFrame> {
  bool _second = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.animate && widget.url2.isNotEmpty) {
      _timer = Timer.periodic(const Duration(milliseconds: 850), (_) {
        if (mounted) setState(() => _second = !_second);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = (_second && widget.url2.isNotEmpty) ? widget.url2 : widget.url1;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: NetImage(
        key: ValueKey(url),
        url: url,
        fit: BoxFit.contain,
        cacheWidth: 500,
        fallback: (_) => widget.fallback,
      ),
    );
  }
}

/// A themed, on-brand exercise illustration: a minimal human figure with the
/// worked muscle group highlighted in the accent colour. Set [animate] for the
/// "how it works" demo — the worked muscle pulses to draw the eye.
class MuscleIllustration extends StatefulWidget {
  final MuscleZone zone;
  final bool animate;
  const MuscleIllustration({
    super.key,
    required this.zone,
    this.animate = false,
  });

  /// Convenience: build straight from a muscle-group string.
  factory MuscleIllustration.fromMuscle(
    String muscle, {
    bool animate = false,
    Key? key,
  }) => MuscleIllustration(
    key: key,
    zone: zoneForMuscle(muscle),
    animate: animate,
  );

  @override
  State<MuscleIllustration> createState() => _MuscleIllustrationState();
}

class _MuscleIllustrationState extends State<MuscleIllustration>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100),
      )..repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant MuscleIllustration old) {
    super.didUpdateWidget(old);
    if (widget.animate && _ctrl == null) {
      _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100),
      )..repeat(reverse: true);
    } else if (!widget.animate && _ctrl != null) {
      _ctrl!.dispose();
      _ctrl = null;
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // SizedBox.expand so the painter fills the box even under loose constraints
    // (e.g. inside a Container with alignment); a bare CustomPaint would collapse
    // to Size.zero and render nothing.
    if (_ctrl == null) {
      return SizedBox.expand(
        child: CustomPaint(
          painter: _MusclePainter(zone: widget.zone, colors: c, pulse: 1),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _ctrl!,
      builder: (_, __) {
        // strong ease-out pulse between emphasis 0.55 and 1.0
        final t = Curves.easeInOut.transform(_ctrl!.value);
        return SizedBox.expand(
          child: CustomPaint(
            painter: _MusclePainter(
              zone: widget.zone,
              colors: c,
              pulse: 0.55 + 0.45 * t,
            ),
          ),
        );
      },
    );
  }
}

class _MusclePainter extends CustomPainter {
  final MuscleZone zone;
  final AppColors colors;
  final double pulse; // 0..1 emphasis on the worked muscle

  _MusclePainter({
    required this.zone,
    required this.colors,
    required this.pulse,
  });

  bool _isActive(MuscleZone part) {
    if (zone == MuscleZone.fullBody) {
      return part != MuscleZone.arms && part != MuscleZone.calves;
    }
    if (zone == MuscleZone.glutes) {
      return part == MuscleZone.legs; // approximate on a front figure
    }
    if (zone == MuscleZone.back) {
      return part == MuscleZone.chest || part == MuscleZone.shoulders;
    }
    return part == zone;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2;
    // A clearly-visible silhouette colour (the old border tone was almost
    // identical to the iconBg tile behind it, so the figure looked empty).
    final body = colors.navInactive;
    final accent = colors.accent;

    Paint fill(bool active) => Paint()
      ..style = PaintingStyle.fill
      ..color = active ? accent.withValues(alpha: pulse) : body;

    RRect rr(double l, double t, double r, double b, double radius) =>
        RRect.fromLTRBR(l, t, r, b, Radius.circular(radius));

    final tw = w * 0.30; // torso half-context
    final left = cx - tw * 0.5, right = cx + tw * 0.5;

    // legs (thighs)
    canvas.drawRRect(
      rr(cx - tw * 0.46, h * 0.52, cx - tw * 0.04, h * 0.72, w * 0.05),
      fill(_isActive(MuscleZone.legs)),
    );
    canvas.drawRRect(
      rr(cx + tw * 0.04, h * 0.52, cx + tw * 0.46, h * 0.72, w * 0.05),
      fill(_isActive(MuscleZone.legs)),
    );
    // calves
    canvas.drawRRect(
      rr(cx - tw * 0.42, h * 0.72, cx - tw * 0.08, h * 0.93, w * 0.05),
      fill(_isActive(MuscleZone.calves)),
    );
    canvas.drawRRect(
      rr(cx + tw * 0.08, h * 0.72, cx + tw * 0.42, h * 0.93, w * 0.05),
      fill(_isActive(MuscleZone.calves)),
    );

    // arms (upper + fore), straight down at sides
    final armActive = _isActive(MuscleZone.arms);
    canvas.drawRRect(
      rr(left - w * 0.11, h * 0.24, left - w * 0.02, h * 0.40, w * 0.045),
      fill(armActive),
    );
    canvas.drawRRect(
      rr(right + w * 0.02, h * 0.24, right + w * 0.11, h * 0.40, w * 0.045),
      fill(armActive),
    );
    canvas.drawRRect(
      rr(left - w * 0.10, h * 0.40, left - w * 0.03, h * 0.54, w * 0.04),
      fill(armActive),
    );
    canvas.drawRRect(
      rr(right + w * 0.03, h * 0.40, right + w * 0.10, h * 0.54, w * 0.04),
      fill(armActive),
    );

    // shoulders
    final shActive = _isActive(MuscleZone.shoulders);
    canvas.drawCircle(Offset(left, h * 0.24), w * 0.055, fill(shActive));
    canvas.drawCircle(Offset(right, h * 0.24), w * 0.055, fill(shActive));

    // chest (upper torso) + core (lower torso)
    canvas.drawRRect(
      rr(left, h * 0.22, right, h * 0.37, w * 0.04),
      fill(_isActive(MuscleZone.chest)),
    );
    canvas.drawRRect(
      rr(cx - tw * 0.42, h * 0.37, cx + tw * 0.42, h * 0.52, w * 0.035),
      fill(_isActive(MuscleZone.core)),
    );

    // head (never a target)
    canvas.drawCircle(Offset(cx, h * 0.115), h * 0.072, Paint()..color = body);
  }

  @override
  bool shouldRepaint(covariant _MusclePainter old) =>
      old.zone != zone ||
      old.pulse != pulse ||
      old.colors.isDark != colors.isDark;
}
