import 'package:flutter/material.dart';
import 'package:kaki_empat/core/config/denpasar_kecamatan.dart';

/// Dropdown terkunci ke 4 kecamatan Kota Denpasar (MVP hyperlocal).
class KecamatanDropdown extends StatelessWidget {
  const KecamatanDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelText = 'Kecamatan',
    this.enabled = true,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final String labelText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: DenpasarKecamatan.isValid(value) ? value : null,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.map_outlined),
      ),
      hint: const Text('Pilih kecamatan'),
      items: DenpasarKecamatan.all
          .map(
            (k) => DropdownMenuItem<String>(
              value: k,
              child: Text(k),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
      validator: (v) =>
          DenpasarKecamatan.isValid(v) ? null : 'Pilih kecamatan Denpasar',
    );
  }
}
