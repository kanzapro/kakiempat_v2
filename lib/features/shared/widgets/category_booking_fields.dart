import 'package:flutter/material.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

/// Field tambahan per kategori layanan (health, grooming, transport, sports, boarding).
class CategoryBookingFields extends StatefulWidget {
  const CategoryBookingFields({
    super.key,
    required this.category,
    required this.onChanged,
    this.summaryPetNames = const [],
    this.summaryDuration = '',
    this.summaryLocation = '',
  });

  final String category;
  final ValueChanged<String> onChanged;
  final List<String> summaryPetNames;
  final String summaryDuration;
  final String summaryLocation;

  @override
  State<CategoryBookingFields> createState() => _CategoryBookingFieldsState();
}

class _CategoryBookingFieldsState extends State<CategoryBookingFields> {
  final _symptomsController = TextEditingController();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _packageController = TextEditingController();
  final _specialNotesController = TextEditingController();
  String _crateSize = 'medium';
  bool _urgent = false;

  @override
  void dispose() {
    _symptomsController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    _packageController.dispose();
    _specialNotesController.dispose();
    super.dispose();
  }

  void _emit() {
    final l10n = AppLocalizations.of(context)!;
    final lines = <String>[];

    switch (widget.category) {
      case 'health':
        if (_symptomsController.text.trim().isNotEmpty) {
          lines.add('${l10n.categoryFormHealthSymptoms}: ${_symptomsController.text.trim()}');
        }
        if (_urgent) {
          lines.add(l10n.categoryFormHealthUrgent);
        }
      case 'grooming':
        if (_packageController.text.trim().isNotEmpty) {
          lines.add('${l10n.categoryFormGroomingPackage}: ${_packageController.text.trim()}');
        }
      case 'transport':
        if (_pickupController.text.trim().isNotEmpty) {
          lines.add('${l10n.categoryFormTransportPickup}: ${_pickupController.text.trim()}');
        }
        if (_dropoffController.text.trim().isNotEmpty) {
          lines.add('${l10n.categoryFormTransportDropoff}: ${_dropoffController.text.trim()}');
        }
        lines.add('${l10n.categoryFormTransportCrate}: $_crateSize');
      case 'sports':
      case 'boarding':
        if (_specialNotesController.text.trim().isNotEmpty) {
          lines.add('Catatan khusus: ${_specialNotesController.text.trim()}');
        }
      default:
        break;
    }

    widget.onChanged(lines.join('\n'));
  }

  Widget _summaryPanel(ThemeData theme) {
    final pets = widget.summaryPetNames.where((n) => n.trim().isNotEmpty).toList();
    final duration = widget.summaryDuration.trim();
    final location = widget.summaryLocation.trim();

    if (pets.isEmpty && duration.isEmpty && location.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pets.isNotEmpty)
              _SummaryRow(
                icon: Icons.pets,
                label: 'Hewan',
                value: pets.join(', '),
              ),
            if (duration.isNotEmpty)
              _SummaryRow(
                icon: Icons.schedule_outlined,
                label: 'Durasi',
                value: duration,
              ),
            if (location.isNotEmpty)
              _SummaryRow(
                icon: Icons.place_outlined,
                label: 'Lokasi',
                value: location,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return switch (widget.category) {
      'health' => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.categoryFormHealthTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _symptomsController,
              onChanged: (_) => _emit(),
              decoration: InputDecoration(
                labelText: l10n.categoryFormHealthSymptoms,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.medical_services_outlined),
              ),
              minLines: 2,
              maxLines: 4,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.categoryFormHealthUrgent),
              value: _urgent,
              onChanged: (v) {
                setState(() => _urgent = v);
                _emit();
              },
            ),
          ],
        ),
      'grooming' => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.categoryFormGroomingTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _packageController,
              onChanged: (_) => _emit(),
              decoration: InputDecoration(
                labelText: l10n.categoryFormGroomingPackage,
                helperText: l10n.categoryFormGroomingPackageHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.content_cut_outlined),
              ),
            ),
          ],
        ),
      'transport' => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.categoryFormTransportTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _pickupController,
              onChanged: (_) => _emit(),
              decoration: InputDecoration(
                labelText: l10n.categoryFormTransportPickup,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.trip_origin_outlined),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _dropoffController,
              onChanged: (_) => _emit(),
              decoration: InputDecoration(
                labelText: l10n.categoryFormTransportDropoff,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _crateSize,
              decoration: InputDecoration(
                labelText: l10n.categoryFormTransportCrate,
                border: const OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'small', child: Text('Small')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'large', child: Text('Large')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _crateSize = v);
                _emit();
              },
            ),
          ],
        ),
      'sports' => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ringkasan Dog Walking', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _summaryPanel(theme),
            TextFormField(
              controller: _specialNotesController,
              onChanged: (_) => _emit(),
              decoration: const InputDecoration(
                labelText: 'Catatan khusus',
                hintText: 'Mis. leash, rute favorit, energi hewan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              minLines: 2,
              maxLines: 4,
            ),
          ],
        ),
      'boarding' => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ringkasan Pet Sitting', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _summaryPanel(theme),
            TextFormField(
              controller: _specialNotesController,
              onChanged: (_) => _emit(),
              decoration: const InputDecoration(
                labelText: 'Catatan khusus',
                hintText: 'Mis. makanan, obat, rutinitas di rumah',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              minLines: 2,
              maxLines: 4,
            ),
          ],
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kategori yang punya form khusus di create request.
bool categoryHasBookingFields(String category) {
  return category == 'health' ||
      category == 'grooming' ||
      category == 'transport' ||
      category == 'sports' ||
      category == 'boarding';
}

/// Kategori yang memblokir submit jika supply pengasuh kosong.
bool categoryRequiresSupplyCheck(String category) {
  return category == 'health' || category == 'grooming' || category == 'transport';
}
