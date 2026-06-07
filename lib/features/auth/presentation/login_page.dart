import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kaki_empat/core/services/auth_service_v2.dart';
import 'package:kaki_empat/core/web/domain_kind.dart';
import 'package:kaki_empat/core/web/domain_router.dart';
import 'package:kaki_empat/core/web/sso_nav.dart';
import 'package:kaki_empat/core/web/sso_uri.dart';
import 'package:kaki_empat/core/web/web_nav.dart';
import 'package:kaki_empat/features/auth/presentation/forgot_password_page.dart';
import 'package:kaki_empat/features/auth/presentation/register_page.dart';
import 'package:kaki_empat/features/auth/presentation/widgets/auth_form_scaffold.dart';
import 'package:kaki_empat/features/auth/presentation/widgets/auth_locale_toggle.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.onSuccess});

  final VoidCallback? onSuccess;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  Locale _locale = const Locale('id');
  bool _loading = false;
  bool _success = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _success = false;
    });
    try {
      final session = await AuthServiceV2.instance.login(
        phone: _phone.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _success = true;
      });
      final l10n = lookupAppLocalizations(_locale);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.authLoginSuccess)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      if (widget.onSuccess != null) {
        widget.onSuccess!();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } else if (kIsWeb && DomainRouter.resolve() == WebDomain.www) {
        final target = readReturnTargetFromUri() ??
            (session.user.isSitter ? 'sitter' : 'owner');
        await SsoNav.openSubdomain(target);
      } else {
        DomainRouter.navigateAfterAuth(context, session.user);
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = lookupAppLocalizations(_locale).authFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      locale: _locale,
      child: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _success ? 0.92 : 1,
            child: AuthFormScaffold(
              title: l10n.authLogin,
              subtitle: l10n.authLoginSubtitle,
              illustration: Icons.waving_hand_outlined,
              formKey: _formKey,
              loading: _loading,
              error: _error,
              submitLabel: l10n.authLogin,
              onSubmit: _submit,
              appBarActions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AuthLocaleToggle(
                    locale: _locale,
                    onChanged: (l) => setState(() => _locale = l),
                  ),
                ),
              ],
              fields: [
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: InputDecoration(
                    labelText: l10n.authPhone,
                    hintText: l10n.authPhoneHint,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      AuthServiceV2.normalizePhone(v ?? '') == null
                          ? l10n.authInvalidPhone
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _loading ? null : _submit(),
                  decoration: InputDecoration(
                    labelText: l10n.authPassword,
                    hintText: l10n.authPasswordHint,
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => !AuthServiceV2.isValidPassword(v ?? '')
                      ? l10n.authInvalidPassword
                      : null,
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                            if (kIsWeb &&
                                DomainRouter.resolve() == WebDomain.www) {
                              navigateToUrl(SsoNav.loginUrlOnWww(
                                auth: 'forgot',
                                returnTarget: readReturnTargetFromUri(),
                              ));
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ForgotPasswordPage(
                                    locale: _locale,
                                  ),
                                ),
                              );
                            }
                          },
                    child: Text(l10n.authForgotPassword),
                  ),
                ),
              ],
              footer: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${l10n.authNoAccount} '),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                            if (kIsWeb &&
                                DomainRouter.resolve() == WebDomain.www) {
                              navigateToUrl(SsoNav.loginUrlOnWww(
                                auth: 'register',
                                returnTarget: readReturnTargetFromUri(),
                              ));
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => RegisterPage(
                                    locale: _locale,
                                    onSuccess: widget.onSuccess,
                                  ),
                                ),
                              );
                            }
                          },
                    child: Text(l10n.authRegister),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
