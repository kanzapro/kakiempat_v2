import 'package:flutter/material.dart';
import 'package:kaki_empat/core/models/v2_domain_models.dart';
import 'package:kaki_empat/core/services/service_catalog_v2_service.dart';
import 'package:kaki_empat/core/services/sitter_v2_service.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';

class SitterProfileSetupPage extends StatefulWidget {
  const SitterProfileSetupPage({super.key, this.initial});

  final SitterProfileResult? initial;

  @override
  State<SitterProfileSetupPage> createState() => _SitterProfileSetupPageState();
}

class _SitterProfileSetupPageState extends State<SitterProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  late final _address = TextEditingController(
    text: widget.initial?.profile?.address ?? '',
  );
  late final _bio = TextEditingController(
    text: widget.initial?.profile?.bio ?? '',
  );
  List<ServiceCatalogItem> _catalog = [];
  final Set<String> _selectedServices = {};
  bool _loadingCatalog = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedServices.addAll(widget.initial?.services ?? []);
    _loadCatalog();
  }

  @override
  void dispose() {
    _address.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    try {
      final items = await ServiceCatalogV2Service.instance.getCatalogItems();
      if (!mounted) return;
      setState(() {
        _catalog = items;
        _loadingCatalog = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingCatalog = false;
        _error = 'Gagal memuat layanan.';
      });
    }
  }

  Future<void> _submit({bool submitVerification = false}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServices.isEmpty) {
      setState(() => _error = 'Pilih minimal satu layanan.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await SitterV2Service.instance.saveProfile(
        address: _address.text.trim(),
        bio: _bio.text.trim(),
        services: _selectedServices.toList(),
      );
      if (submitVerification) {
        await SitterV2Service.instance.submitVerification();
      }
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
        _error = 'Gagal menyimpan profil.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Pengasuh')),
      body: _loadingCatalog
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _address,
                      decoration: const InputDecoration(
                        labelText: 'Alamat *',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 2,
                      maxLines: 3,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Alamat wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bio,
                      decoration: const InputDecoration(
                        labelText: 'Cerita & pengalaman *',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 3,
                      maxLines: 5,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Bio wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    Text('Layanan yang ditawarkan',
                        style: Theme.of(context).textTheme.titleSmall),
                    ..._catalog.map(
                      (item) => CheckboxListTile(
                        value: _selectedServices.contains(item.code),
                        title: Text(item.label),
                        subtitle: Text(item.categoryLabel),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedServices.add(item.code);
                            } else {
                              _selectedServices.remove(item.code);
                            }
                          });
                        },
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _submitting ? null : () => _submit(),
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Simpan Profil'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () => _submit(submitVerification: true),
                      child: const Text('Simpan & Ajukan Verifikasi'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
