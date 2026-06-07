import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kaki_empat/core/formatters/v2_formatters.dart';
import 'package:kaki_empat/core/models/v2_domain_models.dart';
import 'package:kaki_empat/core/services/admin_v2_service.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';
import 'package:kaki_empat/core/services/payment_v2_service.dart';
import 'package:kaki_empat/core/theme/app_colors.dart';
import 'package:kaki_empat/core/utils/v2_feedback.dart';
import 'package:kaki_empat/features/admin/presentation/admin_launch_metrics_panel.dart';
import 'package:kaki_empat/features/shared/widgets/v2_loading_skeleton.dart';
import 'package:kaki_empat/features/shared/widgets/booking_status_chip.dart';
import 'package:kaki_empat/features/auth/presentation/auth_logout.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _totalSitters = 0;
  int _totalOwners = 0;
  int _totalBookings = 0;
  int _pendingVerification = 0;
  int _transactionTotal = 0;
  bool _summaryLoading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _summaryLoading = true);
    try {
      final results = await Future.wait([
        AdminV2Service.instance.countSitters(),
        AdminV2Service.instance.listOwners(),
        AdminV2Service.instance.listBookings(),
        AdminV2Service.instance.listPendingSitters(),
      ]);
      if (!mounted) return;
      setState(() {
        _totalSitters = results[0] as int;
        _totalOwners = (results[1] as List).length;
        final bookings = results[2] as List<AdminBookingV2>;
        _totalBookings = bookings.length;
        _transactionTotal = bookings
            .where((b) {
              final s = b.status.toLowerCase();
              return s == 'paid' || s == 'completed' || s == 'in_progress';
            })
            .fold(0, (sum, b) => sum + b.paymentAmount);
        _pendingVerification = (results[3] as List).length;
        _summaryLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _summaryLoading = false);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminDashboardTitle),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            Tab(text: l10n.adminTabLaunch),
            Tab(text: l10n.adminTabSitters),
            Tab(text: l10n.adminTabOwners),
            Tab(text: l10n.adminTabBookings),
            Tab(text: l10n.adminTabWithdrawals),
          ],
        ),
        actions: [
          Tooltip(
            message: l10n.tooltipLogout,
            child: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => performAuthLogout(context),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _summaryLoading
                ? const LinearProgressIndicator()
                : Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _SummaryCard(
                        icon: Icons.people_outline,
                        label: l10n.adminStatSitters(_totalSitters),
                        value: '$_totalSitters',
                        color: AppColors.primary,
                      ),
                      _SummaryCard(
                        icon: Icons.pets_outlined,
                        label: l10n.adminStatOwners(_totalOwners),
                        value: '$_totalOwners',
                        color: AppColors.statusInfo(Theme.of(context).colorScheme),
                      ),
                      _SummaryCard(
                        icon: Icons.verified_user_outlined,
                        label: l10n.adminStatPendingVerify(_pendingVerification),
                        value: '$_pendingVerification',
                        color: AppColors.accentWarm,
                      ),
                      _SummaryCard(
                        icon: Icons.payments_outlined,
                        label: l10n.adminStatTransactions(
                          V2Formatters.money(_transactionTotal),
                        ),
                        value: V2Formatters.money(_transactionTotal),
                        color: const Color(0xFF7B1FA2),
                      ),
                    ],
                  ),
          ),
          _AdminPendingActions(onChanged: _loadSummary),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                const AdminLaunchMetricsPanel(),
                _SitterTab(onChanged: _loadSummary),
                const _OwnerTab(),
                const _BookingTab(),
                _WithdrawalTab(onChanged: _loadSummary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SitterTab extends StatefulWidget {
  const _SitterTab({this.onChanged});

  final VoidCallback? onChanged;

  @override
  State<_SitterTab> createState() => _SitterTabState();
}

class _SitterTabState extends State<_SitterTab> {
  List<PendingSitterV2> _sitters = [];
  bool _loading = true;
  String? _error;
  final Set<String> _busy = {};

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
      final items = await AdminV2Service.instance.listPendingSitters();
      if (!mounted) return;
      setState(() {
        _sitters = items;
        _loading = false;
      });
    } on V2ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.loadFailed;
        _loading = false;
      });
    }
  }

  Future<void> _approve(PendingSitterV2 sitter) async {
    setState(() => _busy.add(sitter.userId));
    try {
      await AdminV2Service.instance.approveSitter(sitter.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.adminSitterApproved(sitter.name),
          ),
        ),
      );
      await _load();
      widget.onChanged?.call();
    } on V2ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy.remove(sitter.userId));
    }
  }

  Future<void> _reject(PendingSitterV2 sitter) async {
    setState(() => _busy.add(sitter.userId));
    try {
      await AdminV2Service.instance.rejectSitter(sitter.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.adminSitterRejected(sitter.name),
          ),
        ),
      );
      await _load();
      widget.onChanged?.call();
    } on V2ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy.remove(sitter.userId));
    }
  }

  void _viewDocuments(PendingSitterV2 sitter) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sitter.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sitter.hasKtp && sitter.ktpData != null) ...[
                const Text('KTP'),
                const SizedBox(height: 8),
                _DocImage(dataUrl: sitter.ktpData!),
                const SizedBox(height: 16),
              ],
              if (sitter.hasSelfie && sitter.selfieData != null) ...[
                const Text('Selfie'),
                const SizedBox(height: 8),
                _DocImage(dataUrl: sitter.selfieData!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: _sitters.isEmpty
          ? ListView(
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!),
                  ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.adminSittersEmpty),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _sitters.length,
              itemBuilder: (context, index) {
                final s = _sitters[index];
                final busy = _busy.contains(s.userId);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: Theme.of(context).textTheme.titleMedium),
                        Text(s.phone),
                        if (s.address.isNotEmpty) Text(s.address),
                        const SizedBox(height: 8),
                        if (s.hasKtp || s.hasSelfie)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: OutlinedButton.icon(
                              onPressed: () => _viewDocuments(s),
                              icon: const Icon(Icons.description_outlined),
                              label: Text(l10n.adminViewDocuments),
                            ),
                          ),
                        Row(
                          children: [
                            FilledButton(
                              onPressed: busy ? null : () => _approve(s),
                              child: Text(l10n.adminApprove),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: busy ? null : () => _reject(s),
                              child: Text(l10n.adminReject),
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
}

class _DocImage extends StatelessWidget {
  const _DocImage({required this.dataUrl});

  final String dataUrl;

  @override
  Widget build(BuildContext context) {
    try {
      final b64 = dataUrl.split(',').last;
      return Image.memory(base64Decode(b64), height: 160, fit: BoxFit.contain);
    } catch (_) {
      return const Icon(Icons.broken_image_outlined, size: 48);
    }
  }
}

class _OwnerTab extends StatefulWidget {
  const _OwnerTab();

  @override
  State<_OwnerTab> createState() => _OwnerTabState();
}

class _OwnerTabState extends State<_OwnerTab> {
  List<AdminOwnerV2> _owners = [];
  bool _loading = true;
  String? _error;

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
      final items = await AdminV2Service.instance.listOwners();
      if (!mounted) return;
      setState(() {
        _owners = items;
        _loading = false;
      });
    } on V2ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.loadFailed;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: _owners.isEmpty
          ? ListView(
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!),
                  ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.adminOwnersEmpty),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: _owners.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final o = _owners[index];
                return ListTile(
                  title: Text(o.name),
                  subtitle: Text(
                    [
                      if (o.phone.isNotEmpty) o.phone,
                      if (o.address.isNotEmpty) o.address,
                      if (o.createdAt.isNotEmpty)
                        V2Formatters.dateTime(o.createdAt),
                    ].join(' · '),
                  ),
                  trailing: Chip(
                    label: Text(
                      o.isActive ? l10n.adminActive : l10n.adminInactive,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _BookingTab extends StatefulWidget {
  const _BookingTab();

  @override
  State<_BookingTab> createState() => _BookingTabState();
}

class _BookingTabState extends State<_BookingTab> {
  List<AdminBookingV2> _bookings = [];
  bool _loading = true;
  String? _error;

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
      final items = await AdminV2Service.instance.listBookings();
      if (!mounted) return;
      setState(() {
        _bookings = items;
        _loading = false;
      });
    } on V2ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.loadFailed;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: _bookings.isEmpty
          ? ListView(
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!),
                  ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.adminBookingsEmpty),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: _bookings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final b = _bookings[index];
                return ListTile(
                  title: Text('#${b.id} · ${b.ownerName}'),
                  subtitle: Text(
                    '${b.sitterName} · ${V2Formatters.money(b.paymentAmount)} · '
                    '${V2Formatters.dateTime(b.createdAt)}',
                  ),
                  trailing: BookingStatusChip(status: b.status),
                );
              },
            ),
    );
  }
}

class _WithdrawalTab extends StatefulWidget {
  const _WithdrawalTab({this.onChanged});

  final VoidCallback? onChanged;

  @override
  State<_WithdrawalTab> createState() => _WithdrawalTabState();
}

class _WithdrawalTabState extends State<_WithdrawalTab> {
  List<AdminWithdrawalV2> _items = [];
  bool _loading = true;
  String? _error;
  final Set<String> _busy = {};

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
      final items = await AdminV2Service.instance.listPendingWithdrawals();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on V2ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.loadFailed;
        _loading = false;
      });
    }
  }

  Future<void> _approve(AdminWithdrawalV2 item) async {
    setState(() => _busy.add(item.id));
    try {
      await AdminV2Service.instance.approveWithdrawal(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.adminWithdrawalApproved)),
      );
      await _load();
      widget.onChanged?.call();
    } on V2ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy.remove(item.id));
    }
  }

  Future<void> _reject(AdminWithdrawalV2 item) async {
    setState(() => _busy.add(item.id));
    try {
      await AdminV2Service.instance.rejectWithdrawal(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.adminReject)),
      );
      await _load();
      widget.onChanged?.call();
    } on V2ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: _items.isEmpty
          ? ListView(
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!),
                  ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.adminWithdrawalsEmpty),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: _items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final w = _items[index];
                final busy = _busy.contains(w.id);
                return Card(
                  child: ListTile(
                    title: Text(w.userName.isNotEmpty ? w.userName : w.userId),
                    subtitle: Text(
                      '${V2Formatters.money(w.amount)} · ${w.phone} · '
                      '${V2Formatters.dateTime(w.createdAt)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: busy ? null : () => _reject(w),
                          child: Text(l10n.adminReject),
                        ),
                        const SizedBox(width: 4),
                        FilledButton(
                          onPressed: busy ? null : () => _approve(w),
                          child: Text(l10n.adminApprove),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _AdminPendingActions extends StatefulWidget {
  const _AdminPendingActions({this.onChanged});

  final VoidCallback? onChanged;

  @override
  State<_AdminPendingActions> createState() => _AdminPendingActionsState();
}

class _AdminPendingActionsState extends State<_AdminPendingActions> {
  List<PendingSitterV2> _sitters = [];
  List<PaymentProofPendingItem> _payments = [];
  List<AdminWithdrawalV2> _withdrawals = [];
  bool _loading = true;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        AdminV2Service.instance.listPendingSitters(),
        PaymentV2Service.instance.listPendingVerification(),
        AdminV2Service.instance.listPendingWithdrawals(),
      ]);
      if (!mounted) return;
      setState(() {
        _sitters = (results[0] as List<PendingSitterV2>).take(3).toList();
        _payments = (results[1] as List<PaymentProofPendingItem>).take(3).toList();
        _withdrawals = (results[2] as List<AdminWithdrawalV2>).take(3).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approveSitter(PendingSitterV2 sitter) async {
    setState(() => _busy.add(sitter.userId));
    try {
      await AdminV2Service.instance.approveSitter(sitter.userId);
      if (!mounted) return;
      V2Feedback.showSuccess(
        context,
        AppLocalizations.of(context)!.adminSitterApproved(sitter.name),
      );
      await _load();
      widget.onChanged?.call();
    } on V2ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(sitter.userId));
    }
  }

  Future<void> _rejectSitter(PendingSitterV2 sitter) async {
    setState(() => _busy.add(sitter.userId));
    try {
      await AdminV2Service.instance.rejectSitter(sitter.userId);
      await _load();
      widget.onChanged?.call();
    } finally {
      if (mounted) setState(() => _busy.remove(sitter.userId));
    }
  }

  Future<void> _approvePayment(PaymentProofPendingItem item) async {
    setState(() => _busy.add(item.bookingId));
    try {
      await PaymentV2Service.instance.adminApprovePayment(item.bookingId);
      if (!mounted) return;
      V2Feedback.showSuccess(context, '✅ Pembayaran disetujui');
      await _load();
      widget.onChanged?.call();
    } on PaymentV2Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(item.bookingId));
    }
  }

  Future<void> _approveWithdrawal(AdminWithdrawalV2 item) async {
    setState(() => _busy.add(item.id));
    try {
      await AdminV2Service.instance.approveWithdrawal(item.id);
      if (!mounted) return;
      V2Feedback.showSuccess(
        context,
        AppLocalizations.of(context)!.adminWithdrawalApproved,
      );
      await _load();
      widget.onChanged?.call();
    } finally {
      if (mounted) setState(() => _busy.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasItems = _sitters.isNotEmpty || _payments.isNotEmpty || _withdrawals.isNotEmpty;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: V2SkeletonBox(height: 80, radius: 16),
      );
    }
    if (!hasItems) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.adminPendingActionsTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._sitters.map((s) {
            final services = s.services.isNotEmpty ? s.services.join(', ') : '—';
            final busy = _busy.contains(s.userId);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(l10n.adminActionNewSitter(s.name, services)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: busy ? null : () => _rejectSitter(s),
                      child: Text(l10n.adminReject),
                    ),
                    FilledButton(
                      onPressed: busy ? null : () => _approveSitter(s),
                      child: Text(l10n.adminApprove),
                    ),
                  ],
                ),
              ),
            );
          }),
          ..._payments.map((p) {
            final busy = _busy.contains(p.bookingId);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  l10n.adminActionPayment(
                    V2Formatters.money(p.paymentAmount),
                    p.ownerName,
                  ),
                ),
                trailing: FilledButton(
                  onPressed: busy ? null : () => _approvePayment(p),
                  child: Text(l10n.adminApprove),
                ),
              ),
            );
          }),
          ..._withdrawals.map((w) {
            final busy = _busy.contains(w.id);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  l10n.adminActionWithdrawal(
                    V2Formatters.money(w.amount),
                    w.userName.isNotEmpty ? w.userName : w.phone,
                  ),
                ),
                trailing: FilledButton(
                  onPressed: busy ? null : () => _approveWithdrawal(w),
                  child: Text(l10n.adminApprove),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
