import 'package:flutter/material.dart';
import 'package:kaki_empat/core/services/auth_service_v2.dart';
import 'package:kaki_empat/features/auth/presentation/widgets/auth_form_scaffold.dart';
import 'package:kaki_empat/features/auth/presentation/widgets/auth_locale_toggle.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, this.locale = const Locale('id')});

  final Locale locale;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _resetCode = TextEditingController();
  final _password = TextEditingController();
  late Locale _locale;
  bool _loading = false;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _locale = widget.locale;
  }

  @override
  void dispose() {
    _phone.dispose();
    _resetCode.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _done = false;
    });
    try {
      await AuthServiceV2.instance.resetPassword(
        phone: _phone.text.trim(),
        resetCode: _resetCode.text.trim(),
        newPassword: _password.text,
      );
      if (!mounted) return;
      setState(() => _done = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lookupAppLocalizations(_locale).authResetSuccess)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
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
          return AuthFormScaffold(
            title: l10n.authResetPassword,
            subtitle: l10n.authResetPasswordSubtitle,
            illustration: Icons.vpn_key_outlined,
            formKey: _formKey,
            loading: _loading,
            error: _error,
            submitLabel: l10n.authResetPassword,
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
                controller: _resetCode,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.authResetCode,
                  hintText: 'reset_...',
                  prefixIcon: const Icon(Icons.confirmation_number_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final code = v?.trim() ?? '';
                  if (!RegExp(r'^reset_[a-f0-9]{48}$').hasMatch(code)) {
                    return l10n.authResetCodeRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _loading ? null : _submit(),
                decoration: InputDecoration(
                  labelText: l10n.authNewPassword,
                  hintText: l10n.authPasswordHint,
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => !AuthServiceV2.isValidPassword(v ?? '')
                    ? l10n.authInvalidPassword
                    : null,
              ),
              if (_done)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l10n.authResetSuccess,
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
            ],
            footer: TextButton(
              onPressed: _loading ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.authBackToLogin),
            ),
          );
        },
      ),
    );
  }
}
