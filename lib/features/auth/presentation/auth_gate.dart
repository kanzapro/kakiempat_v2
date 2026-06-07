import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:kaki_empat/core/config/mvp_scope.dart';
import 'package:kaki_empat/core/models/auth_user_v2.dart';
import 'package:kaki_empat/core/services/auth_service_v2.dart';

import 'package:kaki_empat/core/web/domain_kind.dart';

import 'package:kaki_empat/core/web/domain_router.dart';

import 'package:kaki_empat/core/web/sso_bootstrap.dart';
import 'package:kaki_empat/core/web/sso_nav.dart';

import 'package:kaki_empat/features/shared/widgets/event_notification_shell.dart';

import 'package:kaki_empat/features/shared/presentation/subdomain_coming_soon_page.dart';
import 'package:kaki_empat/features/sitter/presentation/sitter_landing_page.dart';


/// Gate auth terpadu untuk owner, sitter, admin, staging.

class AuthGate extends StatefulWidget {

  const AuthGate({super.key, required this.domain, required this.child});



  final WebDomain domain;

  final Widget child;



  @override

  State<AuthGate> createState() => _AuthGateState();

}



class _AuthGateState extends State<AuthGate> {

  bool _loading = true;

  bool _authenticated = false;

  String? _denied;

  AuthUserV2? _user;



  @override

  void initState() {

    super.initState();

    _load();

  }



  Future<void> _load() async {

    setState(() => _loading = true);

    await SsoBootstrap.tryConsumeUriCode();
    await AuthServiceV2.instance.bootstrapSso();

    try {

      final token = await AuthServiceV2.instance.getToken();
      if (token != null && token.isNotEmpty) {

        final user = await AuthServiceV2.instance.validateToken(token: token);

        if (!mounted) return;

        final denied = DomainRouter.accessDenied(widget.domain, user);

        setState(() {

          _authenticated = denied == null;

          _denied = denied;

          _user = user;

          _loading = false;

        });

        return;

      }

    } catch (_) {

      await AuthServiceV2.instance.logout();

    }

    if (mounted) {

      setState(() {

        _authenticated = false;

        _denied = null;

        _user = null;

        _loading = false;

      });

    }

  }



  bool get _usesNotifications =>

      widget.domain == WebDomain.owner ||

      widget.domain == WebDomain.sitter ||

      widget.domain == WebDomain.staging;



  @override

  Widget build(BuildContext context) {

    if (_loading) {

      return const Scaffold(

        body: Center(child: CircularProgressIndicator()),

      );

    }

    if (_denied != null) {

      return Scaffold(

        body: Center(child: Text(_denied!, textAlign: TextAlign.center)),

      );

    }

    if (!_authenticated) {

      if (DomainRouter.requiresLogin(widget.domain)) {
        if (kIsWeb) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            SsoNav.redirectToWwwLogin(returnTarget: widget.domain.name);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      }
      if (widget.domain == WebDomain.sitter) {

        return SitterLandingPage(onAuthSuccess: _load);

      }

      return widget.child;

    }



    if (!MvpScope.canAccessSubdomain(widget.domain, _user)) {
      return SubdomainComingSoonPage(domain: widget.domain);
    }

    final child = widget.child;

    if (_usesNotifications) {

      return EventNotificationShell(child: child);

    }

    return child;

  }

}


