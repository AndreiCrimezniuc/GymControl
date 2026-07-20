import 'package:flutter/cupertino.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/pressable.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/workout_session_controller.dart';

/// A persistent bar shown over the app while a workout is minimized. Tapping it
/// re-opens the runner with the session intact.
class WorkoutResumeBar extends StatelessWidget {
  final WorkoutSessionController session;
  final VoidCallback onTap;
  const WorkoutResumeBar({super.key, required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final progress = session.totalSets == 0 ? 0.0 : (session.doneSets / session.totalSets).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Pressable(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: c.invBg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: const Color(0x40000000), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(11)),
                      child: Icon(CupertinoIcons.play_arrow_solid, size: 18, color: c.textOnAccent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(session.workout?.name ?? 'Workout',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.invText, fontFamily: 'Rubik')),
                          const SizedBox(height: 2),
                          Text('${session.elapsed}  ·  ${session.doneSets}/${session.totalSets} sets  ·  tap to resume',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: c.invText.withValues(alpha: 0.7), fontFamily: 'Rubik')),
                        ],
                      ),
                    ),
                    Icon(CupertinoIcons.chevron_up, size: 18, color: c.invText.withValues(alpha: 0.7)),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                child: Stack(children: [
                  Container(height: 4, color: const Color(0x22FFFFFF)),
                  FractionallySizedBox(widthFactor: progress, child: Container(height: 4, color: c.accent)),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
