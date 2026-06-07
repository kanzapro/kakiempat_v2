import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kaki_empat/core/config/app_config.dart';
import 'package:kaki_empat/core/formatters/v2_formatters.dart';
import 'package:kaki_empat/core/models/v2_domain_models.dart';
import 'package:kaki_empat/core/services/marketplace_v2_service.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';
import 'package:kaki_empat/core/utils/geolocation_capture.dart';
import 'package:kaki_empat/features/shared/widgets/v2_pet_avatar.dart';
import 'package:kaki_empat/core/utils/v2_feedback.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class CreateRequestPage extends StatefulWidget {
  const CreateRequestPage({
    super.key,
    required this.service,
    required this.pets,
    this.defaultLocation,
  });

  final ServiceCatalogItem service;
  final List<PetV2> pets;
  final OwnerProfileV2? defaultLocation;

  @override
  State<CreateRequestPage> createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage> {
  final Set<String> _selectedPetIds = {};
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime? _date;
  TimeOfDay? _startTime;
  int _durationHours = 2;
  bool _submitting = false;
  bool _estimatingSitters = false;
  int? _estimatedSitterCount;
  String? _error;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    final profile = widget.defaultLocation;
    if (profile != null && profile.address.isNotEmpty) {
      _locationController.text = profile.address;
    }
    _latitude = profile?.latitude;
    _longitude = profile?.longitude;
    if (widget.pets.length == 1) {
      _selectedPetIds.add(widget.pets.first.id);
    }
    _initCoordinates();
  }

  Future<void> _initCoordinates() async {
    final coords = await resolveCoordinates(
      storedLatitude: _latitude,
      storedLongitude: _longitude,
    );
    if (!mounted) return;
    setState(() {
      _latitude = coords?.latitude ?? _latitude;
      _longitude = coords?.longitude ?? _longitude;
    });
    await _refreshSitterEstimate();
  }

  double? get _requestLatitude => _latitude;

  double? get _requestLongitude => _longitude;

  Future<void> _refreshSitterEstimate() async {
    final lat = _requestLatitude;
    final lng = _requestLongitude;
    if (lat == null || lng == null) {
      if (!mounted) return;
      setState(() {
        _estimatedSitterCount = null;
        _estimatingSitters = false;
      });
      return;
    }

    setState(() => _estimatingSitters = true);
    try {
      final estimate = await MarketplaceV2Service.instance.estimateBroadcast(
        serviceType: widget.service.code,
        latitude: lat,
        longitude: lng,
      );
      if (!mounted) return;
      setState(() {
        _estimatedSitterCount = estimate.sitterCountInRadius;
        _estimatingSitters = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _estimatedSitterCount = null;
        _estimatingSitters = false;
      });
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _date ?? now.add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  String _timeRangeLabel() {
    if (_startTime == null) return '';
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = startMinutes + _durationHours * 60;
    final endHour = (endMinutes ~/ 60) % 24;
    final endMinute = endMinutes % 60;
    final start = _formatClock(_startTime!.hour, _startTime!.minute);
    final end = _formatClock(endHour, endMinute);
    return '$start–$end';
  }

  String _formatClock(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String? _pricePreview(AppLocalizations l10n) {
    final rate = int.tryParse(_priceController.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    if (rate <= 0) return l10n.createRequestPriceHint;
    final fee = AppConfig.platformFeeOwner(rate);
    final total = AppConfig.ownerTotalFromRate(rate);
    return l10n.createRequestTotalPreview(
      V2Formatters.money(total),
      V2Formatters.money(fee),
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedPetIds.isEmpty) {
      setState(() => _error = l10n.createRequestSelectPet);
      return;
    }
    if (_date == null) {
      setState(() => _error = l10n.createRequestSelectDate);
      return;
    }
    if (_startTime == null) {
      setState(() => _error = l10n.createRequestSelectTime);
      return;
    }
    if (_locationController.text.trim().isEmpty) {
      setState(() => _error = l10n.createRequestLocationRequired);
      return;
    }
    final price = int.tryParse(_priceController.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    if (price <= 0) {
      setState(() => _error = l10n.createRequestPriceRequired);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final locale = Localizations.localeOf(context).toString();
      final dateLabel = DateFormat.yMMMd(locale).format(_date!);
      final coords = await resolveCoordinates(
        storedLatitude: _latitude,
        storedLongitude: _longitude,
      );
      if (coords == null) {
        if (!mounted) return;
        setState(() {
          _error = l10n.ownerProfileLocationHint;
          _submitting = false;
        });
        return;
      }
      final location = <String, dynamic>{
        'address': _locationController.text.trim(),
        'latitude': coords.latitude,
        'longitude': coords.longitude,
      };

      final result = await MarketplaceV2Service.instance.createRequest(
        serviceType: widget.service.code,
        petIds: _selectedPetIds.toList(),
        dateLabel: dateLabel,
        timeRange: _timeRangeLabel(),
        location: location,
        price: price,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;
      final successMessage = result.sitterCountInRadius != null
          ? l10n.createRequestSuccessBroadcast(result.sitterCountInRadius!)
          : l10n.createRequestSuccess;
      V2Feedback.showSuccess(context, successMessage);
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
    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat.yMMMd(locale);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createRequestTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.miscellaneous_services_outlined),
              title: Text(widget.service.label),
              subtitle: Text(widget.service.categoryLabel),
            ),
            const Divider(),
            Text(l10n.createRequestPet, style: Theme.of(context).textTheme.titleSmall),
            ...widget.pets.map(
              (pet) => CheckboxListTile(
                value: _selectedPetIds.contains(pet.id),
                title: Text(pet.name),
                subtitle: Text(pet.species),
                secondary: V2PetAvatar(petId: pet.id, size: 40),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedPetIds.add(pet.id);
                    } else {
                      _selectedPetIds.remove(pet.id);
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                _date == null ? l10n.createRequestDate : dateFmt.format(_date!),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.schedule_outlined),
              label: Text(
                _startTime == null
                    ? l10n.createRequestTime
                    : _timeRangeLabel(),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.createRequestDuration, style: Theme.of(context).textTheme.titleSmall),
            Slider(
              value: _durationHours.toDouble(),
              min: 1,
              max: 8,
              divisions: 7,
              label: l10n.createRequestDurationHours(_durationHours),
              onChanged: (v) => setState(() => _durationHours = v.round()),
            ),
            Text(
              l10n.createRequestDurationHours(_durationHours),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: l10n.createRequestLocation,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.place_outlined),
              ),
              minLines: 1,
              maxLines: 2,
            ),
            if (_requestLatitude != null && _requestLongitude != null) ...[
              const SizedBox(height: 8),
              if (_estimatingSitters)
                Text(
                  l10n.createRequestSitterEstimateLoading,
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else if (_estimatedSitterCount != null)
                Text(
                  l10n.createRequestSitterEstimate(_estimatedSitterCount!),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: l10n.createRequestNotes,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.notes_outlined),
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.createRequestPrice,
                helperText: _pricePreview(l10n),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.payments_outlined),
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
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.createRequestSubmit),
            ),
          ],
        ),
      ),
    );
  }
}
