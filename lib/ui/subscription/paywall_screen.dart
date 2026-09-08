import 'package:flutter/cupertino.dart';
import 'package:gymboss/l10n/app_localizations.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_page.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l = AppLocalizations.of(context);
    return AppPage(
      title: 'GymControl Pro',
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(CupertinoIcons.bolt_fill, size: 64, color: colors.accent),
          const SizedBox(height: 20),
          Text(
            l.proTrainWithoutLimits,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l.proDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          for (final feature in [
            l.proUnlimitedWorkouts,
            l.proCustomFolders,
            l.proOrganizeLibrary,
            l.proAiReview,
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.checkmark_alt_circle_fill,
                    color: colors.accent,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    feature,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.accent, width: 2),
            ),
            child: Column(
              children: [
                Text(
                  l.proPriceMonthly,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  l.proCancelAnytime,
                  style: TextStyle(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.iconBg,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              l.proPurchasesSoon,
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
