import 'package:flutter/cupertino.dart';

import 'package:gymboss/data/sync/sync_service.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';

/// A thin status strip shown app-wide when the device is offline and/or there
/// are local changes still waiting to sync. Renders nothing (zero height) when
/// everything is online and synced, so it never shifts layout in the happy path.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: SyncService.instance.status,
      builder: (context, s, _) {
        if (s.online && !s.hasPending) return const SizedBox.shrink();

        final c = context.colors;
        final offline = !s.online;
        final bg = offline ? const Color(0xFF8A6D3B) : c.accent;
        final icon = offline
            ? CupertinoIcons.wifi_slash
            : CupertinoIcons.arrow_2_circlepath;

        final label = offline
            ? (s.hasPending
                  ? 'Offline · ${s.pending} change${s.pending == 1 ? '' : 's'} will sync later'
                  : 'Offline · changes are saved on this device')
            : 'Syncing ${s.pending} change${s.pending == 1 ? '' : 's'}…';

        return Semantics(
          liveRegion: true,
          label: label,
          child: Container(
            width: double.infinity,
            color: bg,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 13, color: c.textOnAccent),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.textOnAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
