import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kaki_empat/core/models/v2_domain_models.dart';
import 'package:kaki_empat/core/services/service_catalog_v2_service.dart';
import 'package:kaki_empat/core/services/sitter_v2_service.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';
import 'package:kaki_empat/core/utils/geolocation_capture.dart';
import 'package:kaki_empat/features/shared/widgets/service_category_icon.dart';
import 'package:kaki_empat/features/shared/widgets/event_notification_shell.dart';
import 'package:kaki_empat/features/sitter/presentation/sitter_home_page.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

/// Onboarding pengasuh: layanan → profil → verifikasi.
class SitterOnboardingPage extends StatefulWidget {
  const SitterOnboardingPage({super.key, this.editOnly = false, this.onComplete});

  /// Mode edit profil: simpan tanpa ajukan verifikasi ulang.
  final bool editOnly;
  final VoidCallback? onComplete;

  @override
  State<SitterOnboardingPage> createState() => _SitterOnboardingPageState();
}

class _SitterOnboardingPageState extends State<SitterOnboardingPage> {
  int _step = 0;
  bool _submitted = false;

  List<ServiceCatalogItem> _catalog = [];
  final Set<String> _selectedServices = {};
  bool _loadingCatalog = true;

  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _bio = TextEditingController();

  bool _submitting = false;
  String? _error;
  String? _ktpData;
  String? _selfieData;
  double? _storedLatitude;
  double? _storedLongitude;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await SitterV2Service.instance.getProfile();
      if (!mounted) return;
      _address.text = profile.profile?.address ?? '';
      _bio.text = profile.profile?.bio ?? '';
      _storedLatitude = profile.profile?.latitude;
      _storedLongitude = profile.profile?.longitude;
      _selectedServices.addAll(profile.services);
      if (profile.profile?.isPending == true) {
        setState(() => _submitted = true);
      }
    } catch (_) {
      // Profil baru — lanjut dengan form kosong.
    }
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
        _error = AppLocalizations.of(context)!.catalogLoadFailed;
      });
    }
  }

  @override
  void dispose() {
    _address.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _nextStep() {
    final l10n = AppLocalizations.of(context)!;
    if (_step == 0) {
      if (_selectedServices.isEmpty) {
        setState(() => _error = l10n.sitterOnboardingServicesRequired);
        return;
      }
    }
    if (_step == 1 && !_formKey.currentState!.validate()) {
      return;
    }
    final maxStep = widget.editOnly ? 1 : 2;
    setState(() {
      _error = null;
      _step = (_step + 1).clamp(0, maxStep);
    });
  }

  void _backStep() {
    setState(() {
      _error = null;
      _step = (_step - 1).clamp(0, 2);
    });
  }

  Future<void> _saveProfileOnly() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServices.isEmpty) {
      setState(() => _error = AppLocalizations.of(context)!.sitterOnboardingServicesRequired);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final coords = await resolveCoordinates(
        storedLatitude: _storedLatitude,
        storedLongitude: _storedLongitude,
      );
      await SitterV2Service.instance.saveProfile(
        address: _address.text.trim(),
        bio: _bio.text.trim(),
        services: _selectedServices.toList(),
        latitude: coords?.latitude,
        longitude: coords?.longitude,
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

  Future<void> _pickDoc({required bool ktp}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;
    final mime = result.files.first.extension == 'png' ? 'image/png' : 'image/jpeg';
    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
    setState(() {
      if (ktp) {
        _ktpData = dataUrl;
      } else {
        _selfieData = dataUrl;
      }
    });
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServices.isEmpty) {
      setState(() => _error = AppLocalizations.of(context)!.sitterOnboardingServicesRequired);
      return;
    }
    if (_ktpData == null || _selfieData == null) {
      setState(() => _error = AppLocalizations.of(context)!.sitterVerificationDocsRequired);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final coords = await resolveCoordinates(
        storedLatitude: _storedLatitude,
        storedLongitude: _storedLongitude,
      );
      await SitterV2Service.instance.saveProfile(
        address: _address.text.trim(),
        bio: _bio.text.trim(),
        services: _selectedServices.toList(),
        latitude: coords?.latitude,
        longitude: coords?.longitude,
      );
      await SitterV2Service.instance.uploadVerification(
        ktpData: _ktpData!,
        selfieData: _selfieData!,
      );
      await SitterV2Service.instance.submitVerification();
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _submitting = false;
      });
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

  void _goHome() {
    if (widget.onComplete != null) {
      widget.onComplete!();
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const EventNotificationShell(child: SitterHomePage()),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_submitted && !widget.editOnly) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.sitterOnboardingTitle)),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_top_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.sitterOnboardingWaitingTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.sitterOnboardingWaitingMessage,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _goHome,
                child: Text(l10n.actionContinue),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editOnly ? l10n.actionEditProfile : l10n.sitterOnboardingTitle,
        ),
      ),
      body: _loadingCatalog
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Stepper(
                    currentStep: _step,
                    controlsBuilder: (context, details) => const SizedBox.shrink(),
                    steps: [
                      Step(
                        title: Text(l10n.sitterOnboardingStepServices),
                        content: const SizedBox.shrink(),
                        isActive: _step >= 0,
                      ),
                      Step(
                        title: Text(l10n.sitterOnboardingStepProfile),
                        content: const SizedBox.shrink(),
                        isActive: _step >= 1,
                      ),
                      if (!widget.editOnly)
                        Step(
                          title: Text(l10n.sitterOnboardingStepVerify),
                          content: const SizedBox.shrink(),
                          isActive: _step >= 2,
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildStepContent(l10n),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildActions(l10n),
                ),
              ],
            ),
    );
  }

  Widget _buildStepContent(AppLocalizations l10n) {
    return switch (_step) {
      0 => _buildServicesStep(l10n),
      1 => _buildProfileStep(l10n),
      _ => _buildVerifyStep(l10n),
    };
  }

  Widget _buildServicesStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.sitterOnboardingSelectServices,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: _catalog.length,
          itemBuilder: (context, index) {
            final item = _catalog[index];
            final selected = _selectedServices.contains(item.code);
            return InkWell(
              onTap: () {
                setState(() {
                  if (selected) {
                    _selectedServices.remove(item.code);
                  } else {
                    _selectedServices.add(item.code);
                  }
                  _error = null;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Card(
                color: selected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        serviceCategoryIcon(item.category),
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (selected)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Icon(
                            Icons.check_circle,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProfileStep(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _address,
            decoration: InputDecoration(
              labelText: l10n.sitterOnboardingAddress,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
            minLines: 2,
            maxLines: 3,
            validator: (v) => v == null || v.trim().isEmpty
                ? l10n.sitterOnboardingAddressRequired
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bio,
            decoration: InputDecoration(
              labelText: l10n.sitterOnboardingBio,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.notes_outlined),
            ),
            minLines: 3,
            maxLines: 5,
            validator: (v) =>
                v == null || v.trim().isEmpty ? l10n.sitterOnboardingBioRequired : null,
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyStep(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.work_outline),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedServices.length} ${l10n.sitterProfileServices.toLowerCase()}',
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _selectedServices.map((code) {
                    final label = _catalog
                        .where((c) => c.code == code)
                        .map((c) => c.label)
                        .firstOrNull;
                    return Chip(
                      avatar: const Icon(Icons.pets, size: 16),
                      label: Text(label ?? code),
                    );
                  }).toList(),
                ),
                const Divider(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(l10n.sitterProfileAddress),
                  subtitle: Text(_address.text.trim()),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notes_outlined),
                  title: Text(l10n.sitterProfileBio),
                  subtitle: Text(_bio.text.trim()),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.sitterVerificationUpload, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _submitting ? null : () => _pickDoc(ktp: true),
          icon: Icon(_ktpData != null ? Icons.check_circle : Icons.badge_outlined),
          label: Text(l10n.sitterVerificationKtp),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _submitting ? null : () => _pickDoc(ktp: false),
          icon: Icon(_selfieData != null ? Icons.check_circle : Icons.face_outlined),
          label: Text(l10n.sitterVerificationSelfie),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.sitterOnboardingWaitingMessage,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildActions(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Row(
          children: [
            if (_step > 0)
              OutlinedButton(
                onPressed: _submitting ? null : _backStep,
                child: Text(l10n.actionBack),
              ),
            if (_step > 0) const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: _submitting
                    ? null
                    : () {
                        final lastStep = widget.editOnly ? 1 : 2;
                        if (_step < lastStep) {
                          _nextStep();
                        } else if (widget.editOnly) {
                          _saveProfileOnly();
                        } else {
                          _submitVerification();
                        }
                      },
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _step < (widget.editOnly ? 1 : 2)
                            ? l10n.actionNext
                            : widget.editOnly
                                ? l10n.actionSave
                                : l10n.sitterOnboardingSubmit,
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
