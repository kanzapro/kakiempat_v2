import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kaki_empat/core/config/mvp_scope.dart';
import 'package:kaki_empat/core/services/auth_service_v2.dart';
import 'package:kaki_empat/core/web/domain_kind.dart';
import 'package:kaki_empat/core/web/domain_router.dart';
import 'package:kaki_empat/core/web/sso_nav.dart';
import 'package:kaki_empat/core/web/sso_uri.dart';
import 'package:kaki_empat/features/auth/presentation/widgets/auth_form_scaffold.dart';
import 'package:kaki_empat/features/auth/presentation/widgets/auth_locale_toggle.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    this.onSuccess,
    this.defaultRole = 'owner',
    this.locale = const Locale('id'),
  });

  final VoidCallback? onSuccess;
  final String defaultRole;
  final Locale locale;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _referral = TextEditingController();
  late String _role;
  late Locale _locale;
  bool _loading = false;
  bool _success = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _locale = widget.locale;
    _role = widget.defaultRole == 'sitter' ? 'sitter' : 'owner';
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _name.dispose();
    _referral.dispose();
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
      final session = await AuthServiceV2.instance.register(
        phone: _phone.text.trim(),
        password: _password.text,
        name: _name.text.trim(),
        role: _role,
        referralCode: _referral.text.trim(),
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
              const Icon(Icons.celebration_outlined, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.authRegisterSuccess)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      if (widget.onSuccess != null) {
        widget.onSuccess!();
        Navigator.of(context).pop();
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
              title: l10n.authRegister,
              subtitle: l10n.authRegisterSubtitle,
              illustration: _role == 'sitter'
                  ? Icons.handshake_outlined
                  : Icons.pets_outlined,
              formKey: _formKey,
              loading: _loading,
              error: _error,
              submitLabel: l10n.authRegister,
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
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  decoration: InputDecoration(
                    labelText: l10n.authName,
                    hintText: l10n.authNameHint,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.authNameRequired
                      : null,
                ),
                const SizedBox(height: 12),
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
                  autofillHints: const [AutofillHints.newPassword],
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
                const SizedBox(height: 12),
                if (!MvpScope.hideLoyaltyReferral)
                  TextFormField(
                    controller: _referral,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: l10n.referralTitle,
                      hintText: 'KE12345678',
                      prefixIcon: const Icon(Icons.card_giftcard_outlined),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                if (!MvpScope.hideLoyaltyReferral) const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: InputDecoration(
                    labelText: l10n.authRole,
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'owner',
                      child: Text(l10n.authRoleOwner),
                    ),
                    DropdownMenuItem(
                      value: 'sitter',
                      child: Text(l10n.authRoleSitter),
                    ),
                  ],
                  onChanged: _loading ? null : (v) => setState(() => _role = v!),
                ),
              ],
              footer: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.authHasAccount),
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.of(context).pop(),
                    child: Text(l10n.authLogin),
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
