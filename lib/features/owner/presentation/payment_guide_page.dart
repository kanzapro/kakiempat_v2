import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kaki_empat/core/config/app_config.dart';
import 'package:kaki_empat/core/services/booking_v2_service.dart';
import 'package:kaki_empat/core/services/payment_status_service.dart';
import 'package:kaki_empat/core/services/payment_v2_service.dart';
import 'package:kaki_empat/core/utils/v2_feedback.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

/// Pembayaran Wise / Revolut / International Bank Transfer — peer-to-peer.
class PaymentGuidePage extends StatefulWidget {
  const PaymentGuidePage({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<PaymentGuidePage> createState() => _PaymentGuidePageState();
}

class _PaymentGuidePageState extends State<PaymentGuidePage>
    with SingleTickerProviderStateMixin {
  final _referenceController = TextEditingController();
  late final TabController _methodTabs;

  String? _screenshotName;
  String? _screenshotBase64;
  String? _screenshotMime;
  bool _loadingAmount = true;
  bool _submitting = false;
  bool _submitted = false;
  bool _isPaid = false;
  String? _error;
  String _bookingStatus = '';
  int _totalPrice = 0;
  int _platformFeeOwner = 0;
  int _amountToSend = 0;
  Timer? _pollTimer;

  static const _pollInterval = Duration(seconds: 3);

  static const _bankName = 'PT Bank SeaBank Indonesia';

  String get _accountNumber => AppConfig.seabankAccountNumber;
  String get _accountName => AppConfig.seabankAccountName;
  String get _bankCode => AppConfig.seabankBankCode;

  @override
  void initState() {
    super.initState();
    _methodTabs = TabController(length: 3, vsync: this);
    _loadAmount();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _methodTabs.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _loadAmount() async {
    setState(() => _loadingAmount = true);
    var totalPrice = 0;
    var amountToSend = 0;
    var platformFee = 0;
    var isPaid = false;
    var status = '';
    try {
      final booking =
          await BookingV2Service.instance.getBooking(widget.bookingId);
      totalPrice = booking.totalPrice;
      amountToSend = booking.paymentAmount;
      status = booking.status;
      isPaid = booking.isPaid;
    } catch (_) {
      try {
        final snap =
            await PaymentStatusService.instance.fetchStatus(widget.bookingId);
        totalPrice = snap.totalPrice;
        amountToSend = snap.ownerPays > 0 ? snap.ownerPays : snap.paymentAmount;
        platformFee = snap.platformFeeOwner;
        status = snap.status;
        isPaid = snap.isPaid;
      } catch (_) {
        totalPrice = 0;
        amountToSend = 0;
      }
    }
    if (totalPrice <= 0 && amountToSend > 0) {
      totalPrice = (amountToSend / (1 + AppConfig.platformFeeOwnerPercent)).round();
    }
    platformFee = platformFee > 0
        ? platformFee
        : AppConfig.platformFeeOwner(totalPrice);
    if (amountToSend <= 0 && totalPrice > 0) {
      amountToSend = AppConfig.ownerTotalFromRate(totalPrice);
    }
    if (!mounted) return;
    setState(() {
      _totalPrice = totalPrice;
      _platformFeeOwner = platformFee;
      _amountToSend = amountToSend;
      _bookingStatus = status;
      _isPaid = isPaid;
      _loadingAmount = false;
    });
    if (isPaid) {
      _stopPolling();
    } else {
      _maybeStartPolling();
    }
  }

  bool _shouldPollForPayment(String status) {
    final normalized = status.toLowerCase().replaceAll('_', '');
    return normalized == 'awaitingpayment' || normalized == 'pendingverification';
  }

  void _maybeStartPolling() {
    if (_isPaid || !_shouldPollForPayment(_bookingStatus)) return;
    _startPolling();
  }

  Future<void> _pollPaymentStatus() async {
    try {
      final snap =
          await PaymentStatusService.instance.fetchStatus(widget.bookingId);
      if (!mounted) return;
      if (snap.isPaid) {
        setState(() {
          _isPaid = true;
          _bookingStatus = snap.status;
          _totalPrice = snap.totalPrice;
          _platformFeeOwner = snap.platformFeeOwner;
          _amountToSend = snap.ownerPays;
        });
        _stopPolling();
      } else if (snap.isMismatch) {
        setState(() => _error = snap.displayLabel);
      }
    } catch (_) {}
  }

  void _startPolling() {
    _pollTimer?.cancel();
    unawaited(_pollPaymentStatus());
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollPaymentStatus());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  String _formatIdr(int amount) {
    if (amount <= 0) return AppLocalizations.of(context)!.valueEmpty;
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'IDR ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _formatIdrCompact(int amount) {
    if (amount <= 0) return AppLocalizations.of(context)!.valueEmpty;
    final formatted = NumberFormat('#,###', 'en_US').format(amount);
    return 'IDR $formatted';
  }

  Future<void> _pickScreenshot() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;
    setState(() {
      _screenshotName = file.name;
      _screenshotBase64 = base64Encode(bytes);
      _screenshotMime = _mimeFromExtension(file.extension);
    });
  }

  String _mimeFromExtension(String? ext) {
    return switch (ext?.toLowerCase()) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final reference = _referenceController.text.trim();
    if (reference.isEmpty) {
      setState(() => _error = l10n.paymentReferenceRequired);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await PaymentV2Service.instance.submitPaymentProof(
        bookingId: widget.bookingId,
        referenceCode: reference,
        screenshotBase64: _screenshotBase64,
        screenshotMime: _screenshotMime,
      );
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _submitting = false;
      });
      V2Feedback.showSuccess(context, l10n.paymentWaitingVerification);
      _startPolling();
    } on PaymentV2Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = l10n.paymentSubmitFailed;
        _submitting = false;
      });
    }
  }

  void _copyToClipboard(String value) {
    final l10n = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.paymentCopied)),
    );
  }

  List<String> _paymentSteps(AppLocalizations l10n) {
    final amountLabel = _formatIdrCompact(_amountToSend);
    final amountStep = '${l10n.paymentAmountToSend}: $amountLabel. '
        '${l10n.paymentExactAmountHint}';
    return switch (_methodTabs.index) {
      1 => [
          l10n.paymentRevolutStep1,
          l10n.paymentRevolutStep2,
          l10n.paymentRevolutStep3,
          l10n.paymentRevolutStep4,
          amountStep,
        ],
      2 => [
          l10n.paymentBankStep1,
          l10n.paymentBankStep2,
          l10n.paymentBankStep3,
          l10n.paymentBankStep4,
          amountStep,
        ],
      _ => [
          l10n.paymentWiseStep1,
          l10n.paymentWiseStep2,
          l10n.paymentWiseStep3,
          l10n.paymentWiseStep4,
          amountStep,
        ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final feePct =
        (AppConfig.platformFeeOwnerPercent * 100).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentTitle)),
      body: _isPaid
          ? _PaidSuccessBanner(
              l10n: l10n,
              theme: theme,
              totalPrice: _totalPrice,
              platformFeeOwner: _platformFeeOwner,
              amountToSend: _amountToSend,
              bookingStatus: _bookingStatus,
              formatIdr: _formatIdr,
              feePct: feePct,
            )
          : _submitted
              ? _SubmittedBanner(
                  l10n: l10n,
                  theme: theme,
                  totalPrice: _totalPrice,
                  platformFeeOwner: _platformFeeOwner,
                  amountToSend: _amountToSend,
                  formatIdr: _formatIdr,
                  feePct: feePct,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.paymentMethodTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.paymentMethodDescription(feePct),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TabBar(
                        controller: _methodTabs,
                        onTap: (_) => setState(() {}),
                        tabs: [
                          Tab(text: l10n.paymentTabWise),
                          Tab(text: l10n.paymentTabRevolut),
                          Tab(text: l10n.paymentTabBankTransfer),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _BankInfoCard(
                        l10n: l10n,
                        bankName: _bankName,
                        bankCode: _bankCode,
                        accountNumber: _accountNumber,
                        accountName: _accountName,
                        onCopy: _copyToClipboard,
                      ),
                      const SizedBox(height: 20),
                      _AmountCard(
                        l10n: l10n,
                        loading: _loadingAmount,
                        totalPrice: _totalPrice,
                        platformFeeOwner: _platformFeeOwner,
                        amountToSend: _amountToSend,
                        formatIdr: _formatIdr,
                        feePct: feePct,
                        onCopy: () => _copyToClipboard('$_amountToSend'),
                      ),
                      const SizedBox(height: 20),
                      _HowToPaySteps(
                        title: l10n.paymentHowToPay,
                        steps: _paymentSteps(l10n),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _referenceController,
                        decoration: InputDecoration(
                          labelText: l10n.paymentReferenceLabel,
                          hintText: l10n.paymentReferenceHint,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.tag_outlined),
                        ),
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: _pickScreenshot,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.upload_file_outlined),
                        label: Text(
                          _screenshotName == null
                              ? l10n.paymentUploadProof
                              : l10n.paymentProofSelected(_screenshotName!),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_error != null) ...[
                        Text(
                          _error!,
                          style: TextStyle(color: colorScheme.error),
                        ),
                        const SizedBox(height: 12),
                      ],
                      FilledButton.icon(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(l10n.paymentConfirm),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _HowToPaySteps extends StatelessWidget {
  const _HowToPaySteps({required this.title, required this.steps});

  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.phone_iphone_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(steps.length, (i) {
              final step = steps[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        '${i + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.l10n,
    required this.loading,
    required this.totalPrice,
    required this.platformFeeOwner,
    required this.amountToSend,
    required this.formatIdr,
    required this.feePct,
    required this.onCopy,
  });

  final AppLocalizations l10n;
  final bool loading;
  final int totalPrice;
  final int platformFeeOwner;
  final int amountToSend;
  final String Function(int) formatIdr;
  final String feePct;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.paymentAmountToSend,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatIdr(amountToSend),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      if (amountToSend > 0)
                        IconButton(
                          icon: const Icon(Icons.copy_outlined),
                          onPressed: onCopy,
                        ),
                    ],
                  ),
                  if (totalPrice > 0) ...[
                    const SizedBox(height: 12),
                    _FeeLine(
                      label: l10n.paymentServiceRate,
                      value: formatIdr(totalPrice),
                    ),
                    _FeeLine(
                      label: l10n.paymentPlatformFee(feePct),
                      value: formatIdr(platformFeeOwner),
                    ),
                    const Divider(height: 20),
                  ],
                  Text(
                    l10n.paymentExactAmountHint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BankInfoCard extends StatelessWidget {
  const _BankInfoCard({
    required this.l10n,
    required this.bankName,
    required this.bankCode,
    required this.accountNumber,
    required this.accountName,
    required this.onCopy,
  });

  final AppLocalizations l10n;
  final String bankName;
  final String bankCode;
  final String accountNumber;
  final String accountName;
  final void Function(String value) onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.push_pin_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.paymentBankDetailsTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _InfoRow(label: l10n.paymentBankName, value: bankName),
            _InfoRow(
              label: l10n.paymentBankCode,
              value: '$bankCode (If required by Revolut)',
            ),
            _InfoRow(
              label: l10n.paymentAccountNo,
              value: accountNumber,
              onCopy: () => onCopy(accountNumber),
            ),
            _InfoRow(
              label: l10n.paymentAccountName,
              value: accountName,
              onCopy: () => onCopy(accountName),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy_outlined, size: 20),
              visualDensity: VisualDensity.compact,
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }
}

class _FeeLine extends StatelessWidget {
  const _FeeLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Text(value, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PaymentBreakdownCard extends StatelessWidget {
  const _PaymentBreakdownCard({
    required this.l10n,
    required this.theme,
    required this.totalPrice,
    required this.platformFeeOwner,
    required this.amountToSend,
    required this.formatIdr,
    required this.feePct,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final int totalPrice;
  final int platformFeeOwner;
  final int amountToSend;
  final String Function(int) formatIdr;
  final String feePct;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.paymentDetails, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _FeeLine(label: l10n.paymentServiceRate, value: formatIdr(totalPrice)),
            _FeeLine(
              label: l10n.paymentPlatformFee(feePct),
              value: formatIdr(platformFeeOwner),
            ),
            const Divider(),
            _FeeLine(label: l10n.paymentTotalPaid, value: formatIdr(amountToSend)),
          ],
        ),
      ),
    );
  }
}

class _PaidSuccessBanner extends StatelessWidget {
  const _PaidSuccessBanner({
    required this.l10n,
    required this.theme,
    required this.totalPrice,
    required this.platformFeeOwner,
    required this.amountToSend,
    required this.bookingStatus,
    required this.formatIdr,
    required this.feePct,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final int totalPrice;
  final int platformFeeOwner;
  final int amountToSend;
  final String bookingStatus;
  final String Function(int) formatIdr;
  final String feePct;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 0,
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 48, color: Colors.green.shade700),
                  const SizedBox(height: 16),
                  Text(
                    l10n.paymentSuccess,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.paymentSuccessId,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.green.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.bookingDetailStatus}: ${bookingStatus.isEmpty ? 'PAID' : bookingStatus}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _PaymentBreakdownCard(
            l10n: l10n,
            theme: theme,
            totalPrice: totalPrice,
            platformFeeOwner: platformFeeOwner,
            amountToSend: amountToSend,
            formatIdr: formatIdr,
            feePct: feePct,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.paymentBackToDashboard),
          ),
        ],
      ),
    );
  }
}

class _SubmittedBanner extends StatelessWidget {
  const _SubmittedBanner({
    required this.l10n,
    required this.theme,
    required this.totalPrice,
    required this.platformFeeOwner,
    required this.amountToSend,
    required this.formatIdr,
    required this.feePct,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final int totalPrice;
  final int platformFeeOwner;
  final int amountToSend;
  final String Function(int) formatIdr;
  final String feePct;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 0,
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.hourglass_top_rounded,
                    size: 48,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.paymentWaitingVerification,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.paymentWaitingVerificationId,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.85,
                      ),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.paymentWaitingVerificationBody,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _PaymentBreakdownCard(
            l10n: l10n,
            theme: theme,
            totalPrice: totalPrice,
            platformFeeOwner: platformFeeOwner,
            amountToSend: amountToSend,
            formatIdr: formatIdr,
            feePct: feePct,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.paymentBackToDashboard),
          ),
        ],
      ),
    );
  }
}
