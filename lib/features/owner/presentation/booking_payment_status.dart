import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kaki_empat/core/services/payment_status_service.dart';

/// Tampilan status pembayaran real-time (polling 5 detik).
class BookingPaymentStatusPage extends StatefulWidget {
  const BookingPaymentStatusPage({
    super.key,
    required this.bookingId,
  });

  final String bookingId;

  @override
  State<BookingPaymentStatusPage> createState() => _BookingPaymentStatusPageState();
}

class _BookingPaymentStatusPageState extends State<BookingPaymentStatusPage> {
  static const Duration _pollInterval = Duration(seconds: 3);

  PaymentStatusSnapshot? _snapshot;
  String? _error;
  Timer? _timer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(_pollInterval, (_) => _refresh(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final snap = await PaymentStatusService.instance.fetchStatus(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _snapshot = snap;
        _error = null;
        _loading = false;
      });
    } on PaymentStatusException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Tidak dapat memuat status. Periksa koneksi.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final snap = _snapshot;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Pembayaran'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _loading && snap == null
            ? const Center(child: CircularProgressIndicator())
            : _error != null && snap == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => _refresh(),
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking #${widget.bookingId}',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 24),
                      if (snap != null) ...[
                        _StatusCard(snapshot: snap),
                        const SizedBox(height: 16),
                        Text(
                          'Nominal: Rp ${_formatIdr(snap.paymentAmount)}',
                          style: theme.textTheme.bodyLarge,
                        ),
                        if (snap.paymentMatchedAt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Dikonfirmasi: ${snap.paymentMatchedAt}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                      const Spacer(),
                      Text(
                        'Memperbarui otomatis setiap 3 detik',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (_loading) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(),
                      ],
                    ],
                  ),
      ),
    );
  }

  String _formatIdr(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buf.write('.');
      }
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.snapshot});

  final PaymentStatusSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (snapshot.paymentState) {
      'received' => (Icons.check_circle, Colors.green),
      'mismatch' => (Icons.error_outline, Colors.orange),
      _ => (Icons.hourglass_top, Colors.blue),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                snapshot.displayLabel,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
