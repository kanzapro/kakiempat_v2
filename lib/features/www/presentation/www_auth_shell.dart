import 'package:flutter/material.dart';
import 'package:kaki_empat/core/models/auth_user_v2.dart';
import 'package:kaki_empat/core/services/auth_service_v2.dart';
import 'package:kaki_empat/core/web/sso_nav.dart';
import 'package:kaki_empat/core/web/sso_uri.dart';
import 'package:kaki_empat/features/auth/presentation/auth_logout.dart';
import 'package:kaki_empat/features/auth/presentation/forgot_password_page.dart';
import 'package:kaki_empat/features/auth/presentation/login_page.dart';
import 'package:kaki_empat/features/auth/presentation/register_page.dart';
import 'package:kaki_empat/features/auth/presentation/reset_password_page.dart';
import 'package:kaki_empat/features/www/presentation/www_landing_scope.dart';
import 'package:kaki_empat/features/www/presentation/www_navbar.dart';
import 'package:kaki_empat/features/www/presentation/www_router_page.dart';

/// Pusat autentikasi www — navbar, landing, SSO ke subdomain.
class WwwAuthShell extends StatefulWidget {
  const WwwAuthShell({super.key});

  @override
  State<WwwAuthShell> createState() => _WwwAuthShellState();
}

class _WwwAuthShellState extends State<WwwAuthShell> {
  final _scrollController = ScrollController();
  late final Map<WwwSection, GlobalKey> _sectionKeys = {
    for (final s in WwwSection.values) s: GlobalKey(),
  };

  bool _loading = true;
  AuthUserV2? _user;
  String? _returnTarget;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _returnTarget = readReturnTargetFromUri();
    final authAction = readAuthActionFromUri();
    clearAuthParamsFromUri();

    await AuthServiceV2.instance.bootstrapSso();

    try {
      final token = await AuthServiceV2.instance.getToken();
      if (token != null && token.isNotEmpty) {
        final user = await AuthServiceV2.instance.validateToken(token: token);
        if (!mounted) return;
        setState(() {
          _user = user;
          _loading = false;
        });
        if (_returnTarget != null && _isAllowedReturnTarget(_returnTarget!)) {
          await SsoNav.openSubdomain(_returnTarget!);
        }
        return;
      }
    } catch (_) {
      await AuthServiceV2.instance.logout();
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (authAction == 'login') {
      _openLogin();
    } else if (authAction == 'register') {
      _openRegister();
    } else if (authAction == 'forgot') {
      _openForgot();
    } else if (authAction == 'reset') {
      _openReset();
    }
  }

  bool _isAllowedReturnTarget(String target) =>
      const {'owner', 'sitter', 'admin', 'staging'}.contains(target);

  Future<void> _refreshUser() async {
    setState(() => _loading = true);
    try {
      final user = await AuthServiceV2.instance.validateToken();
      if (!mounted) return;
      setState(() {
        _user = user;
        _loading = false;
      });
      if (_returnTarget != null && _isAllowedReturnTarget(_returnTarget!)) {
        await SsoNav.openSubdomain(_returnTarget!);
        _returnTarget = null;
      }
    } catch (_) {
      await AuthServiceV2.instance.logout();
      if (mounted) {
        setState(() {
          _user = null;
          _loading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await performAuthLogout(context);
    if (mounted) setState(() => _user = null);
  }

  void _openLogin() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LoginPage(onSuccess: _refreshUser),
      ),
    );
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegisterPage(onSuccess: _refreshUser),
      ),
    );
  }

  void _openForgot() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ForgotPasswordPage()),
    );
  }

  void _openReset() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ResetPasswordPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: WwwNavbar(
        user: _user,
        onLogin: _openLogin,
        onRegister: _openRegister,
        onLogout: _logout,
      ),
      body: WwwLandingScope(
        scrollController: _scrollController,
        sectionKeys: _sectionKeys,
        child: WwwRouterPage(
          scrollController: _scrollController,
          sectionKeys: _sectionKeys,
        ),
      ),
    );
  }
}
