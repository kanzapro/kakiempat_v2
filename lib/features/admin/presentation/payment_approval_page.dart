import 'package:flutter/material.dart';
import 'package:kaki_empat/core/services/payment_v2_service.dart';

/// Daftar booking PENDING_VERIFICATION — approve / tolak manual.
class PaymentApprovalPage extends StatefulWidget {
  const PaymentApprovalPage({super.key, this.embedded = false});

  /// Tanpa AppBar/Scaffold sendiri — untuk TabBarView admin dashboard.
  final bool embedded;

  @override
  State<PaymentApprovalPage> createState() => _PaymentApprovalPageState();
}

class _PaymentApprovalPageState extends State<PaymentApprovalPage> {
  List<PaymentProofPendingItem> _items = [];
  bool _loading = true;
  String? _error;
  final Set<String> _busyBookingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await PaymentV2Service.instance.listPendingVerification();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on PaymentV2Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat daftar pembayaran.';
        _loading = false;
      });
    }
  }

  Future<void> _approve(PaymentProofPendingItem item) async {
    setState(() => _busyBookingIds.add(item.bookingId));
    try {
      await PaymentV2Service.instance.adminApprovePayment(item.bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking #${item.bookingId} disetujui')),
      );
      await _load();
    } on PaymentV2Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _busyBookingIds.remove(item.bookingId));
      }
    }
  }

  Future<void> _reject(PaymentProofPendingItem item) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Tolak pembayaran'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Alasan (opsional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Tolak'),
            ),
          ],
        );
      },
    );
    if (reason == null) return;

    setState(() => _busyBookingIds.add(item.bookingId));
    try {
      await PaymentV2Service.instance.adminRejectPayment(
        item.bookingId,
        reason: reason.isEmpty ? null : reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking #${item.bookingId} ditolak')),
      );
      await _load();
    } on PaymentV2Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _busyBookingIds.remove(item.bookingId));
      }
    }
  }

  String _formatIdr(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Widget _buildBody(BuildContext context) {
    return _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                )
              : _items.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined, size: 56),
                          SizedBox(height: 12),
                          Text('Tidak ada pembayaran menunggu verifikasi'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final busy = _busyBookingIds.contains(item.bookingId);
                          final screenshotUrl = item.screenshotFullUrl();

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.ownerName,
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                      ),
                                      Text('Booking #${item.bookingId}'),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.payments_outlined, size: 20),
                                      const SizedBox(width: 8),
                                      Text('Rp ${_formatIdr(item.paymentAmount)}'),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.tag, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text('Ref: ${item.referenceCode}'),
                                      ),
                                    ],
                                  ),
                                  if (screenshotUrl != null) ...[
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        screenshotUrl,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const ListTile(
                                          leading: Icon(Icons.broken_image_outlined),
                                          title: Text('Screenshot tidak dapat dimuat'),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: busy ? null : () => _reject(item),
                                          icon: const Icon(Icons.close),
                                          label: const Text('Tolak'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: busy ? null : () => _approve(item),
                                          icon: busy
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : const Icon(Icons.check),
                                          label: const Text('Approve'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _load,
              tooltip: 'Muat ulang',
            ),
          ),
          Expanded(child: body),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Pembayaran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: body,
    );
  }
}
