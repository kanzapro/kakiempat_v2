import 'package:flutter/material.dart';
import 'package:kaki_empat/core/services/auth_service_v2.dart';
import 'package:kaki_empat/features/auth/presentation/reset_password_page.dart';
import 'package:kaki_empat/features/auth/presentation/widgets/auth_form_scaffold.dart';
import 'package:kaki_empat/features/auth/presentation/widgets/auth_locale_toggle.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.locale = const Locale('id')});

  final Locale locale;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  late Locale _locale;
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _locale = widget.locale;
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      final message = await AuthServiceV2.instance.forgotPassword(
        phone: _phone.text.trim(),
      );
      if (!mounted) return;
      setState(() => _success = message);
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
            title: l10n.authForgotPassword,
            subtitle: l10n.authForgotPasswordSubtitle,
            illustration: Icons.lock_reset_outlined,
            formKey: _formKey,
            loading: _loading,
            error: _error,
            submitLabel: l10n.authSendResetCode,
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
              if (_success != null) ...[
                MaterialBanner(
                  content: Text(_success!),
                  leading: const Icon(Icons.mark_email_read_outlined),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  actions: const [SizedBox.shrink()],
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.telephoneNumber],
                onFieldSubmitted: (_) => _loading ? null : _submit(),
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
            ],
            footer: Column(
              children: [
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ResetPasswordPage(locale: _locale),
                            ),
                          ),
                  child: Text(l10n.authHaveResetCode),
                ),
                TextButton(
                  onPressed: _loading ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.authBackToLogin),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
