import 'package:flutter/material.dart';
import 'package:kaki_empat/core/models/v2_domain_models.dart';
import 'package:kaki_empat/core/services/owner_v2_service.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class AddPetPage extends StatefulWidget {
  const AddPetPage({super.key, this.initialPet});

  final PetV2? initialPet;

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _species;
  late final TextEditingController _breed;
  late final TextEditingController _age;
  late final TextEditingController _weight;
  late final TextEditingController _notes;
  bool _submitting = false;
  String? _error;

  bool get _isEdit => widget.initialPet != null;

  @override
  void initState() {
    super.initState();
    final pet = widget.initialPet;
    _name = TextEditingController(text: pet?.name ?? '');
    _species = TextEditingController(text: pet?.species ?? '');
    _breed = TextEditingController(text: pet?.breed ?? '');
    _age = TextEditingController(text: pet?.age ?? '');
    _weight = TextEditingController(
      text: pet?.weight != null ? '${pet!.weight}' : '',
    );
    _notes = TextEditingController(text: pet?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _species.dispose();
    _breed.dispose();
    _age.dispose();
    _weight.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final weightRaw = _weight.text.trim();
      final weight = weightRaw.isEmpty ? null : double.tryParse(weightRaw);
      if (_isEdit) {
        await OwnerV2Service.instance.updatePet(
          petId: widget.initialPet!.id,
          name: _name.text.trim(),
          species: _species.text.trim(),
          breed: _breed.text.trim(),
          age: _age.text.trim(),
          weight: weight,
          notes: _notes.text.trim(),
        );
      } else {
        await OwnerV2Service.instance.addPet(
          name: _name.text.trim(),
          species: _species.text.trim(),
          breed: _breed.text.trim(),
          age: _age.text.trim(),
          weight: weight,
          notes: _notes.text.trim(),
        );
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
        _error = AppLocalizations.of(context)!.saveFailed;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.profileEditPet : l10n.addPetTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: l10n.petName,
                  prefixIcon: const Icon(Icons.pets),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l10n.petNameRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _species,
                decoration: InputDecoration(
                  labelText: l10n.petSpecies,
                  hintText: l10n.petSpeciesHint,
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l10n.petSpeciesRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _breed,
                decoration: InputDecoration(
                  labelText: l10n.petBreed,
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _age,
                decoration: InputDecoration(
                  labelText: l10n.petAge,
                  prefixIcon: const Icon(Icons.cake_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.petWeight,
                  prefixIcon: const Icon(Icons.monitor_weight_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: InputDecoration(
                  labelText: l10n.petNotes,
                  prefixIcon: const Icon(Icons.notes_outlined),
                ),
                minLines: 2,
                maxLines: 3,
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
                    : Text(l10n.actionSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
