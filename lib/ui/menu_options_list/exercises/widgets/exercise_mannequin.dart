import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';

/// The movement family an exercise belongs to. Each maps to two key poses the
/// mannequin animates between — a rep.
enum MovePattern {
  squat,
  hinge,
  horizontalPress,
  overheadPress,
  curl,
  tricepsExtension,
  row,
  pulldown,
  lateralRaise,
  calfRaise,
  crunch,
  generic,
}

/// Picks a movement pattern from an exercise's name / muscle / equipment.
MovePattern patternFor({
  required String name,
  required String muscle,
  required String equipment,
}) {
  final n = name.toLowerCase();
  final m = muscle.toLowerCase();
  bool inName(List<String> k) => k.any(n.contains);

  if (inName([
    'deadlift',
    'romanian',
    'good morning',
    'hip thrust',
    'swing',
    'hyperextension',
    'rdl',
  ]))
    return MovePattern.hinge;
  if (inName([
    'squat',
    'lunge',
    'leg press',
    'split squat',
    'step up',
    'pistol',
  ]))
    return MovePattern.squat;
  if (inName([
    'bench press',
    'push-up',
    'pushup',
    'push up',
    'chest press',
    'dips',
    'dip',
    'fly',
    'flye',
  ]))
    return MovePattern.horizontalPress;
  if (inName([
    'overhead press',
    'shoulder press',
    'military',
    'ohp',
    'push press',
    'arnold',
  ]))
    return MovePattern.overheadPress;
  if (inName([
    'lateral raise',
    'front raise',
    'side raise',
    'reverse fly',
    'lateral',
  ]))
    return MovePattern.lateralRaise;
  if (inName(['curl'])) return MovePattern.curl;
  if (inName([
    'pushdown',
    'triceps extension',
    'skullcrusher',
    'kickback',
    'overhead extension',
    'triceps',
  ]))
    return MovePattern.tricepsExtension;
  if (inName([
    'pulldown',
    'pull-up',
    'pullup',
    'pull up',
    'chin-up',
    'chin up',
  ]))
    return MovePattern.pulldown;
  if (inName(['row'])) return MovePattern.row;
  if (inName(['calf', 'calve'])) return MovePattern.calfRaise;
  if (inName(['crunch', 'sit-up', 'situp', 'leg raise', 'plank', 'ab ']))
    return MovePattern.crunch;

  // fall back on the muscle group
  if (m.contains('quad') ||
      m.contains('glute') ||
      m.contains('hamstring') ||
      m.contains('leg'))
    return MovePattern.squat;
  if (m.contains('chest') || m.contains('pec'))
    return MovePattern.horizontalPress;
  if (m.contains('shoulder') || m.contains('delt'))
    return MovePattern.overheadPress;
  if (m.contains('bicep')) return MovePattern.curl;
  if (m.contains('tricep')) return MovePattern.tricepsExtension;
  if (m.contains('lat') || m.contains('back')) return MovePattern.row;
  if (m.contains('calf')) return MovePattern.calfRaise;
  if (m.contains('ab') || m.contains('core')) return MovePattern.crunch;
  return MovePattern.generic;
}

/// One pose = absolute segment angles in degrees (screen space, 0 = right,
/// 90 = down, -90 = up). The figure faces right, drawn in profile.
class _Pose {
  final double torso, neck, upperArm, foreArm, thigh, shin;
  const _Pose({
    this.torso = -90,
    this.neck = -90,
    this.upperArm = 90,
    this.foreArm = 90,
    this.thigh = 90,
    this.shin = 90,
  });

  static _Pose lerp(_Pose a, _Pose b, double t) => _Pose(
    torso: a.torso + (b.torso - a.torso) * t,
    neck: a.neck + (b.neck - a.neck) * t,
    upperArm: a.upperArm + (b.upperArm - a.upperArm) * t,
    foreArm: a.foreArm + (b.foreArm - a.foreArm) * t,
    thigh: a.thigh + (b.thigh - a.thigh) * t,
    shin: a.shin + (b.shin - a.shin) * t,
  );
}

class _Move {
  final _Pose a;
  final _Pose b;
  final Set<String> highlight; // segment keys emphasised in the accent colour
  const _Move(this.a, this.b, this.highlight);
}

_Move _moveFor(MovePattern p) {
  switch (p) {
    case MovePattern.squat:
      return const _Move(
        _Pose(
          torso: -82,
          neck: -86,
          upperArm: 2,
          foreArm: -6,
          thigh: 90,
          shin: 90,
        ),
        _Pose(
          torso: -62,
          neck: -78,
          upperArm: -2,
          foreArm: -6,
          thigh: 25,
          shin: 118,
        ),
        {'thigh', 'shin'},
      );
    case MovePattern.hinge:
      return const _Move(
        _Pose(
          torso: -85,
          neck: -86,
          upperArm: 90,
          foreArm: 90,
          thigh: 88,
          shin: 90,
        ),
        _Pose(
          torso: -22,
          neck: -28,
          upperArm: 90,
          foreArm: 90,
          thigh: 72,
          shin: 96,
        ),
        {'torso', 'thigh'},
      );
    case MovePattern.horizontalPress:
      // profile "plank press" proxy: near-horizontal body, elbows bend
      return const _Move(
        _Pose(
          torso: -12,
          neck: -20,
          upperArm: 90,
          foreArm: 90,
          thigh: 172,
          shin: 176,
        ),
        _Pose(
          torso: -12,
          neck: -20,
          upperArm: 66,
          foreArm: 112,
          thigh: 172,
          shin: 176,
        ),
        {'upperArm', 'foreArm'},
      );
    case MovePattern.overheadPress:
      return const _Move(
        _Pose(
          torso: -90,
          neck: -90,
          upperArm: -58,
          foreArm: -118,
          thigh: 90,
          shin: 90,
        ),
        _Pose(
          torso: -90,
          neck: -90,
          upperArm: -90,
          foreArm: -90,
          thigh: 90,
          shin: 90,
        ),
        {'upperArm', 'foreArm'},
      );
    case MovePattern.curl:
      return const _Move(
        _Pose(
          torso: -90,
          neck: -90,
          upperArm: 88,
          foreArm: 92,
          thigh: 90,
          shin: 90,
        ),
        _Pose(
          torso: -90,
          neck: -90,
          upperArm: 88,
          foreArm: -62,
          thigh: 90,
          shin: 90,
        ),
        {'foreArm'},
      );
    case MovePattern.tricepsExtension:
      return const _Move(
        _Pose(
          torso: -90,
          neck: -90,
          upperArm: 92,
          foreArm: 32,
          thigh: 90,
          shin: 90,
        ),
        _Pose(
          torso: -90,
          neck: -90,
          upperArm: 92,
          foreArm: 92,
          thigh: 90,
          shin: 90,
        ),
        {'foreArm'},
      );
    case MovePattern.row:
      return const _Move(
        _Pose(
          torso: -28,
          neck: -34,
          upperArm: 96,
          foreArm: 96,
          thigh: 82,
          shin: 92,
        ),
        _Pose(
          torso: -28,
          neck: -34,
          upperArm: 140,
          foreArm: 96,
          thigh: 82,
          shin: 92,
        ),
        {'upperArm', 'torso'},
      );
    case MovePattern.pulldown:
      return const _Move(
        _Pose(
          torso: -92,
          neck: -92,
          upperArm: -74,
          foreArm: -80,
          thigh: 90,
          shin: 90,
        ),
        _Pose(
          torso: -96,
          neck: -96,
          upperArm: -26,
          foreArm: 34,
          thigh: 90,
          shin: 90,
        ),
        {'upperArm'},
      );
    case MovePattern.lateralRaise:
      return const _Move(
        _Pose(
          torso: -90,
          neck: -90,
          upperArm: 88,
          foreArm: 88,
          thigh: 90,
          shin: 90,
        ),
        _Pose(
          torso: -90,
          neck: -90,
          upperArm: 3,
          foreArm: 1,
          thigh: 90,
          shin: 90,
        ),
        {'upperArm'},
      );
    case MovePattern.calfRaise:
      return const _Move(
        _Pose(
          torso: -90,
          neck: -90,
          upperArm: 88,
          foreArm: 90,
          thigh: 90,
          shin: 90,
        ),
        _Pose(
          torso: -90,
          neck: -90,
          upperArm: 88,
          foreArm: 90,
          thigh: 90,
          shin: 84,
        ),
        {'shin'},
      );
    case MovePattern.crunch:
      return const _Move(
        _Pose(
          torso: -78,
          neck: -78,
          upperArm: -40,
          foreArm: -70,
          thigh: 44,
          shin: 128,
        ),
        _Pose(
          torso: -52,
          neck: -52,
          upperArm: -34,
          foreArm: -64,
          thigh: 44,
          shin: 128,
        ),
        {'torso'},
      );
    case MovePattern.generic:
      return const _Move(
        _Pose(
          torso: -90,
          neck: -90,
          upperArm: 86,
          foreArm: 89,
          thigh: 90,
          shin: 90,
        ),
        _Pose(
          torso: -90,
          neck: -90,
          upperArm: 84,
          foreArm: 88,
          thigh: 84,
          shin: 94,
        ),
        {},
      );
  }
}

/// An animated, on-brand "how it's done" figure: a jointed mannequin that
/// performs the exercise's movement pattern. [animate] runs the rep loop; when
/// false it holds a mid-rep pose (for small thumbnails).
class ExerciseMannequin extends StatefulWidget {
  final MovePattern pattern;
  final bool animate;
  const ExerciseMannequin({
    super.key,
    required this.pattern,
    this.animate = false,
  });

  @override
  State<ExerciseMannequin> createState() => _ExerciseMannequinState();
}

class _ExerciseMannequinState extends State<ExerciseMannequin>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;

  @override
  void initState() {
    super.initState();
    if (widget.animate) _startCtrl();
  }

  void _startCtrl() {
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant ExerciseMannequin old) {
    super.didUpdateWidget(old);
    if (widget.animate && _ctrl == null) {
      _startCtrl();
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
    final move = _moveFor(widget.pattern);
    if (_ctrl == null) {
      return SizedBox.expand(
        child: CustomPaint(
          painter: _MannequinPainter(move: move, colors: c, t: 0.5),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _ctrl!,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_ctrl!.value);
        return SizedBox.expand(
          child: CustomPaint(
            painter: _MannequinPainter(move: move, colors: c, t: t),
          ),
        );
      },
    );
  }
}

// abstract skeleton lengths (unitless; the fit transform scales them)
const double _torsoLen = 26,
    _neckLen = 6,
    _headR = 6.5,
    _upperArm = 16,
    _foreArm = 15,
    _thigh = 20,
    _shin = 20,
    _footLen = 9;

class _MannequinPainter extends CustomPainter {
  final _Move move;
  final AppColors colors;
  final double t; // 0..1 between pose A and B

  _MannequinPainter({
    required this.move,
    required this.colors,
    required this.t,
  });

  Map<String, Offset> _joints(_Pose p) {
    Offset dir(double deg) {
      final r = deg * math.pi / 180;
      return Offset(math.cos(r), math.sin(r));
    }

    final hip = Offset.zero;
    final shoulder = hip + dir(p.torso) * _torsoLen;
    final head = shoulder + dir(p.neck) * (_neckLen + _headR);
    final elbow = shoulder + dir(p.upperArm) * _upperArm;
    final wrist = elbow + dir(p.foreArm) * _foreArm;
    final knee = hip + dir(p.thigh) * _thigh;
    final ankle = knee + dir(p.shin) * _shin;
    final toe = ankle + const Offset(1, 0) * _footLen;
    return {
      'hip': hip,
      'shoulder': shoulder,
      'head': head,
      'elbow': elbow,
      'wrist': wrist,
      'knee': knee,
      'ankle': ankle,
      'toe': toe,
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ja = _joints(move.a);
    final jb = _joints(move.b);
    // union bounding box across both key poses → stable framing
    var minX = double.infinity,
        minY = double.infinity,
        maxX = -double.infinity,
        maxY = -double.infinity;
    for (final set in [ja, jb]) {
      for (final o in set.values) {
        minX = math.min(minX, o.dx);
        minY = math.min(minY, o.dy - _headR);
        maxX = math.max(maxX, o.dx);
        maxY = math.max(maxY, o.dy + _headR);
      }
    }
    final bboxW = (maxX - minX).clamp(1.0, double.infinity);
    final bboxH = (maxY - minY).clamp(1.0, double.infinity);
    const pad = 10.0;
    final scale = math.min(
      (size.width - pad * 2) / bboxW,
      (size.height - pad * 2) / bboxH,
    );
    final drawnW = bboxW * scale, drawnH = bboxH * scale;
    final ox = (size.width - drawnW) / 2 - minX * scale;
    final oy = (size.height - drawnH) / 2 - minY * scale;
    Offset tf(Offset p) => Offset(ox + p.dx * scale, oy + p.dy * scale);

    final j = _joints(_Pose.lerp(move.a, move.b, t));
    final limb = colors.textPrimary;
    final accent = colors.accent;
    final thick = math.max(3.0, scale * 3.2);

    void seg(String key, Offset p1, Offset p2) {
      final on = move.highlight.contains(key);
      final paint =
          Paint()
            ..color = on ? accent : limb
            ..strokeWidth = on ? thick * 1.15 : thick
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke;
      canvas.drawLine(tf(p1), tf(p2), paint);
    }

    // ground line
    final groundY = tf(Offset(0, maxY)).dy;
    canvas.drawLine(
      Offset(size.width * 0.12, groundY),
      Offset(size.width * 0.88, groundY),
      Paint()
        ..color = colors.border
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    seg('thigh', j['hip']!, j['knee']!);
    seg('shin', j['knee']!, j['ankle']!);
    seg('foot', j['ankle']!, j['toe']!);
    seg('torso', j['hip']!, j['shoulder']!);
    seg('upperArm', j['shoulder']!, j['elbow']!);
    seg('foreArm', j['elbow']!, j['wrist']!);

    // head
    canvas.drawCircle(tf(j['head']!), _headR * scale, Paint()..color = limb);
    // hip + shoulder joints for a solid look
    final jointPaint = Paint()..color = limb;
    canvas.drawCircle(tf(j['hip']!), thick * 0.55, jointPaint);
    canvas.drawCircle(tf(j['shoulder']!), thick * 0.55, jointPaint);
  }

  @override
  bool shouldRepaint(covariant _MannequinPainter old) =>
      old.t != t || old.colors.isDark != colors.isDark || old.move != move;
}
