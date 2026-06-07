import 'package:flutter/material.dart';
import 'package:kaki_empat/app.dart';
import 'package:overlay_support/overlay_support.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const OverlaySupport.global(
      child: KakiEmpatV2App(),
    ),
  );
}
