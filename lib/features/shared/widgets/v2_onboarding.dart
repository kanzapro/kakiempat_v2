import 'package:flutter/material.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Short first-run tutorial — owner or sitter.
abstract final class V2Onboarding {
  static const _ownerKey = 'v2_onboarding_owner_v1';
  static const _sitterKey = 'v2_onboarding_sitter_v1';

  static Future<void> maybeShowOwner(BuildContext context) =>
      _maybeShow(context, _ownerKey, isOwner: true);

  static Future<void> maybeShowSitter(BuildContext context) =>
      _maybeShow(context, _sitterKey, isOwner: false);

  static Future<void> showOwnerTutorial(BuildContext context) =>
      _showTutorial(context, isOwner: true, persist: false);

  static Future<void> showSitterTutorial(BuildContext context) =>
      _showTutorial(context, isOwner: false, persist: false);

  static Future<void> resetOwner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ownerKey);
  }

  static Future<void> resetSitter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sitterKey);
  }

  static Future<void> _maybeShow(
    BuildContext context,
    String key, {
    required bool isOwner,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(key) == true) return;
    if (!context.mounted) return;
    await _showTutorial(context, isOwner: isOwner, persist: true, prefsKey: key);
  }

  static Future<void> _showTutorial(
    BuildContext context, {
    required bool isOwner,
    required bool persist,
    String? prefsKey,
  }) async {
    if (!context.mounted) return;
    final prefs = prefsKey != null ? await SharedPreferences.getInstance() : null;
    final l10n = AppLocalizations.of(context)!;
    final steps = isOwner
        ? [
            l10n.onboardingOwnerStep1,
            l10n.onboardingOwnerStep2,
            l10n.onboardingOwnerStep3,
            l10n.ownerGuideTip1,
          ]
        : [
            l10n.onboardingSitterStep1,
            l10n.onboardingSitterStep2,
            l10n.onboardingSitterStep3,
            l10n.sitterOnboardingStepVerify,
          ];
    final title =
        isOwner ? l10n.onboardingOwnerTitle : l10n.onboardingSitterTitle;

    var step = 0;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            final last = step >= steps.length - 1;
            return AlertDialog(
              icon: Icon(isOwner ? Icons.pets : Icons.handshake_outlined),
              title: Text(title),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: (step + 1) / steps.length,
                    ),
                    const SizedBox(height: 16),
                    Text(steps[step]),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (persist && prefs != null && prefsKey != null) {
                      await prefs.setBool(prefsKey, true);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(l10n.onboardingSkip),
                ),
                FilledButton(
                  onPressed: () async {
                    if (last) {
                      if (persist && prefs != null && prefsKey != null) {
                        await prefs.setBool(prefsKey, true);
                      }
                      if (context.mounted) Navigator.pop(context);
                    } else {
                      setLocal(() => step++);
                    }
                  },
                  child: Text(last ? l10n.onboardingGotIt : l10n.onboardingNext),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
