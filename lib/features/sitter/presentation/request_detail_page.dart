import 'package:flutter/material.dart';
import 'package:kaki_empat/core/config/app_config.dart';
import 'package:kaki_empat/core/formatters/v2_formatters.dart';
import 'package:kaki_empat/core/models/v2_domain_models.dart';
import 'package:kaki_empat/core/services/marketplace_v2_service.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';
import 'package:kaki_empat/core/utils/v2_feedback.dart';
import 'package:kaki_empat/features/shared/widgets/booking_status_chip.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class RequestDetailPage extends StatefulWidget {
  const RequestDetailPage({super.key, required this.request});

  final BookingRequestV2 request;

  @override
  State<RequestDetailPage> createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends State<RequestDetailPage> {
  final _priceController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.request.totalPrice > 0) {
      _priceController.text = '${widget.request.totalPrice}';
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _serviceLabel(BookingRequestV2 request) {
    if (request.serviceLabel.isNotEmpty) return request.serviceLabel;
    return V2Formatters.serviceLabel(request.serviceCode);
  }

  String _scheduleLabel(BookingRequestV2 request) {
    if (request.dateLabel.isNotEmpty && request.timeRange.isNotEmpty) {
      return '${request.dateLabel} · ${request.timeRange}';
    }
    if (request.dateLabel.isNotEmpty) return request.dateLabel;
    return V2Formatters.dateTime(request.scheduledAt);
  }

  Future<void> _submitOffer() async {
    final l10n = AppLocalizations.of(context)!;
    final price = int.tryParse(_priceController.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await MarketplaceV2Service.instance.createOffer(
        requestId: widget.request.id,
        price: price,
        message: _messageController.text.trim(),
      );
      if (!mounted) return;
      V2Feedback.showSuccess(context, l10n.requestOfferSuccess);
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
        _error = l10n.saveFailed;
        _submitting = false;
      });
    }
  }

  String? _netEstimate(AppLocalizations l10n) {
    final price = int.tryParse(_priceController.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    if (price <= 0) return null;
    final net = AppConfig.sitterNetFromRate(price);
    return l10n.sitterEarningsEstimate(V2Formatters.money(net));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final request = widget.request;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.requestDetailTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _serviceLabel(request),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            BookingStatusChip(status: request.status),
            const SizedBox(height: 24),
            _DetailRow(
              icon: Icons.person_outline,
              label: l10n.requestDetailOwner,
              value: request.ownerName.isNotEmpty
                  ? request.ownerName
                  : l10n.valueEmpty,
            ),
            _DetailRow(
              icon: Icons.pets,
              label: l10n.requestDetailPets,
              value: request.petNames.isNotEmpty
                  ? request.petNames.asMap().entries.map((entry) {
                      final species = entry.key < request.petSpecies.length
                          ? request.petSpecies[entry.key]
                          : '';
                      return V2Formatters.petDisplayLabel(
                        name: entry.value,
                        species: species,
                      );
                    }).join(', ')
                  : l10n.requestPetCount(request.petIds.length),
            ),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: l10n.requestDetailSchedule,
              value: _scheduleLabel(request),
            ),
            _DetailRow(
              icon: Icons.place_outlined,
              label: l10n.requestDetailLocation,
              value: request.location?.address.isNotEmpty == true
                  ? request.location!.address
                  : l10n.valueEmpty,
            ),
            if (request.distanceKm != null)
              _DetailRow(
                icon: Icons.near_me_outlined,
                label: l10n.sitterFilterRadius,
                value: l10n.sitterRequestDistance(
                  request.distanceKm!.toStringAsFixed(1),
                ),
              ),
            if (request.notes.isNotEmpty)
              _DetailRow(
                icon: Icons.notes_outlined,
                label: l10n.requestDetailNotes,
                value: request.notes,
              ),
            _DetailRow(
              icon: Icons.payments_outlined,
              label: l10n.requestDetailPrice,
              value: V2Formatters.money(request.totalPrice),
            ),
            const Divider(height: 32),
            Text(
              l10n.requestOfferSubmit,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.requestOfferPrice,
                helperText: l10n.sitterOfferPriceTip,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.attach_money),
              ),
            ),
            if (_netEstimate(l10n) != null) ...[
              const SizedBox(height: 8),
              Text(
                _netEstimate(l10n)!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: l10n.requestOfferMessage,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.message_outlined),
              ),
              minLines: 2,
              maxLines: 4,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submitOffer,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.requestOfferSubmit),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
              child: Text(l10n.requestSkipOffer),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
