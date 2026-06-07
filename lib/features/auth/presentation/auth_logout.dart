import 'package:flutter/material.dart';
import 'package:kaki_empat/core/services/auth_service_v2.dart';
import 'package:kaki_empat/core/web/domain_router.dart';

/// Keluar dan reset navigator ke root domain (AuthGate / landing).
Future<void> performAuthLogout(BuildContext context) async {
  await AuthServiceV2.instance.logout();
  if (!context.mounted) return;
  final domain = DomainRouter.resolve();
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => DomainRouter.homeFor(domain)),
    (_) => false,
  );
}
