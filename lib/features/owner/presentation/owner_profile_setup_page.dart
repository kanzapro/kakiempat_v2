import 'package:flutter/material.dart';
import 'package:kaki_empat/core/config/denpasar_kecamatan.dart';
import 'package:kaki_empat/core/services/owner_v2_service.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';
import 'package:kaki_empat/features/shared/widgets/kecamatan_dropdown.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class OwnerProfileSetupPage extends StatefulWidget {
  const OwnerProfileSetupPage({super.key, this.initialAddress = ''});

  final String initialAddress;

  @override
  State<OwnerProfileSetupPage> createState() => _OwnerProfileSetupPageState();
}

class _OwnerProfileSetupPageState extends State<OwnerProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  late final _address = TextEditingController(text: widget.initialAddress);
  String? _kecamatan;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!DenpasarKecamatan.isValid(_kecamatan)) {
      setState(() => _error = 'Pilih kecamatan Denpasar.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await OwnerV2Service.instance.saveProfile(
        address: _address.text.trim(),
        kecamatan: _kecamatan!,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on V2ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.saveFailed;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ownerProfileTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Kaki Empat MVP beroperasi di 4 kecamatan Kota Denpasar.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              KecamatanDropdown(
                value: _kecamatan,
                onChanged: (value) => setState(() => _kecamatan = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                decoration: InputDecoration(
                  labelText: l10n.ownerProfileAddress,
                  border: const OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
                validator: (v) => v == null || v.trim().isEmpty
                    ? l10n.sitterOnboardingAddressRequired
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.actionSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
