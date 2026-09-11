import 'package:flutter/cupertino.dart';

import 'package:gymboss/data/sync/sync_service.dart';
import 'package:gymboss/l10n/app_localizations.dart';
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
        final needsAttention = s.rejected > 0;
        if (s.online && !s.hasPending && !needsAttention) {
          return const SizedBox.shrink();
        }

        final c = context.colors;
        final offline = !s.online;
        final bg = needsAttention
            ? const Color(0xFF9C4B36)
            : offline
            ? const Color(0xFF8A6D3B)
            : c.accent;
        final icon = needsAttention
            ? CupertinoIcons.exclamationmark_triangle_fill
            : offline
            ? CupertinoIcons.wifi_slash
            : CupertinoIcons.arrow_2_circlepath;

        final l10n = AppLocalizations.of(context);
        final label = needsAttention
            ? l10n.syncRejected(s.rejected)
            : offline
            ? (s.hasPending
                  ? l10n.offlinePending(s.pending)
                  : l10n.offlineSaved)
            : l10n.syncingChanges(s.pending);

        return Semantics(
          liveRegion: true,
          label: label,
          button: needsAttention,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: needsAttention
                ? () => SyncService.instance.retryRejected()
                : null,
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
          ),
        );
      },
    );
  }
}
