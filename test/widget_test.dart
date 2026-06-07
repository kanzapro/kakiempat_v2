import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaki_empat/app.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('KakiEmpatV2App memuat login owner (dev default)', (
    WidgetTester tester,
  ) async {
    await tester.binding.setLocale('id', 'ID');
    await tester.pumpWidget(const KakiEmpatV2App());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final l10n = lookupAppLocalizations(const Locale('id'));
    expect(find.text(l10n.authLogin), findsWidgets);
  });
}
