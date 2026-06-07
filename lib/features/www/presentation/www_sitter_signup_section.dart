import 'package:flutter/material.dart';
import 'package:kaki_empat/core/services/auth_service_v2.dart';
import 'package:kaki_empat/core/web/sso_nav.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

/// Form pendaftaran mitra pengasuh di halaman www.
class WwwSitterSignupSection extends StatefulWidget {
  const WwwSitterSignupSection({super.key});

  @override
  State<WwwSitterSignupSection> createState() => _WwwSitterSignupSectionState();
}

class _WwwSitterSignupSectionState extends State<WwwSitterSignupSection> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _done = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthServiceV2.instance.register(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text,
        role: 'sitter',
      );
      if (!mounted) return;
      setState(() => _done = true);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = AppLocalizations.of(context)!.authFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_done) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.check_circle, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(l10n.wwwSignupSuccess, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => SsoNav.openSubdomain('sitter'),
                child: Text(l10n.wwwSignupGoSitter),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.wwwSignupSitterTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                l10n.wwwSignupSitterDesc,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: l10n.authName,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l10n.authNameRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.authPhone,
                  hintText: l10n.authPhoneHint,
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
                decoration: InputDecoration(
                  labelText: l10n.authPassword,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    !AuthServiceV2.isValidPassword(v ?? '')
                        ? l10n.authInvalidPassword
                        : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.sitterRegisterCta),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
