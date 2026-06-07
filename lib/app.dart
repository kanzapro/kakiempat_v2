import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kaki_empat/core/theme/app_colors.dart';
import 'package:kaki_empat/core/theme/app_theme.dart';
import 'package:kaki_empat/core/theme/theme_notifier.dart';
import 'package:kaki_empat/core/web/domain_router.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class KakiEmpatV2App extends StatefulWidget {
  const KakiEmpatV2App({super.key});

  @override
  State<KakiEmpatV2App> createState() => _KakiEmpatV2AppState();
}

class _KakiEmpatV2AppState extends State<KakiEmpatV2App> {
  @override
  void initState() {
    super.initState();
    ThemeNotifier.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeNotifier.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Kaki Empat',
          theme: AppTheme.light.copyWith(
            scaffoldBackgroundColor: AppColors.surfaceWarm,
          ),
          darkTheme: AppTheme.dark,
          themeMode: ThemeNotifier.instance.mode,
          locale: WidgetsBinding.instance.platformDispatcher.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DomainRouter(),
        );
      },
    );
  }
}
