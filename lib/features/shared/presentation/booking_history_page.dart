import 'package:flutter/material.dart';
import 'package:kaki_empat/core/formatters/v2_formatters.dart';
import 'package:kaki_empat/core/models/v2_domain_models.dart';
import 'package:kaki_empat/core/services/booking_v2_service.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';
import 'package:kaki_empat/core/navigation/v2_page_route.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/features/shared/presentation/booking_detail_page.dart';
import 'package:kaki_empat/features/shared/widgets/booking_status_chip.dart';
import 'package:kaki_empat/features/shared/widgets/v2_empty_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_error_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_loading_skeleton.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

enum _BookingDateFilter { all, last7, last30, last90 }

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  List<BookingV2> _all = [];
  bool _loading = true;
  Object? _error;
  _BookingDateFilter _filter = _BookingDateFilter.all;
  String _statusFilter = 'all';

  static const _pageSize = 15;
  int _visibleCount = _pageSize;

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
      final bookings = await BookingV2Service.instance.listMyBookings();
      if (!mounted) return;
      setState(() {
        _all = bookings;
        _loading = false;
        _visibleCount = _pageSize;
      });
    } on V2ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  List<BookingV2> get _filtered {
    final now = DateTime.now();
    return _all.where((b) {
      if (_statusFilter != 'all' && b.status.toLowerCase() != _statusFilter) {
        return false;
      }
      if (_filter == _BookingDateFilter.all || b.createdAt.isEmpty) return true;
      final dt = DateTime.tryParse(b.createdAt);
      if (dt == null) return true;
      final days = switch (_filter) {
        _BookingDateFilter.last7 => 7,
        _BookingDateFilter.last30 => 30,
        _BookingDateFilter.last90 => 90,
        _ => 0,
      };
      return now.difference(dt).inDays <= days;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = _filtered;
    final visible = filtered.take(_visibleCount).toList();
    final hasMore = _visibleCount < filtered.length;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookingHistoryTitle)),
      body: V2Responsive.constrain(
        _loading
            ? const V2ListSkeleton()
            : _error != null
                ? V2ErrorState.fromError(context, error: _error, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: V2Responsive.pagePadding(context),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(l10n.bookingHistoryFilterDate,
                                    style: Theme.of(context).textTheme.titleSmall),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: _BookingDateFilter.values.map((f) {
                                    final label = switch (f) {
                                      _BookingDateFilter.all => l10n.filterAll,
                                      _BookingDateFilter.last7 => l10n.filterLast7Days,
                                      _BookingDateFilter.last30 => l10n.filterLast30Days,
                                      _BookingDateFilter.last90 => l10n.filterLast90Days,
                                    };
                                    return FilterChip(
                                      label: Text(label),
                                      selected: _filter == f,
                                      onSelected: (_) => setState(() {
                                        _filter = f;
                                        _visibleCount = _pageSize;
                                      }),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: _statusFilter,
                                  decoration: InputDecoration(
                                    labelText: l10n.bookingHistoryFilterStatus,
                                    isDense: true,
                                  ),
                                  items: [
                                    DropdownMenuItem(value: 'all', child: Text(l10n.filterAll)),
                                    DropdownMenuItem(
                                        value: 'awaitingpayment',
                                        child: Text(l10n.bookingStatusAwaitingPayment)),
                                    DropdownMenuItem(
                                        value: 'pending_verification',
                                        child: Text(l10n.bookingStatusPendingVerification)),
                                    DropdownMenuItem(
                                        value: 'paid', child: Text(l10n.bookingStatusPaid)),
                                    DropdownMenuItem(
                                        value: 'confirmed',
                                        child: Text(l10n.bookingStatusConfirmed)),
                                    DropdownMenuItem(
                                        value: 'en_route', child: Text(l10n.bookingStatusEnRoute)),
                                    DropdownMenuItem(
                                        value: 'in_progress',
                                        child: Text(l10n.bookingStatusInProgress)),
                                    DropdownMenuItem(
                                        value: 'completed', child: Text(l10n.bookingStatusCompleted)),
                                    DropdownMenuItem(
                                        value: 'cancelled',
                                        child: Text(l10n.bookingStatusCancelled)),
                                  ],
                                  onChanged: (v) => setState(() {
                                    _statusFilter = v ?? 'all';
                                    _visibleCount = _pageSize;
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (filtered.isEmpty)
                          SliverFillRemaining(
                            child: V2EmptyState(
                              message: l10n.bookingHistoryEmpty,
                              icon: Icons.history,
                            ),
                          )
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index >= visible.length) return null;
                                final b = visible[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  child: Card(
                                    child: ListTile(
                                      title: Text(
                                        b.serviceCode.isNotEmpty
                                            ? V2Formatters.serviceLabel(b.serviceCode)
                                            : '#${b.id}',
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          BookingStatusChip(status: b.status),
                                          Text(
                                            '${V2Formatters.dateTime(b.scheduledAt.isNotEmpty ? b.scheduledAt : b.createdAt)} · ${V2Formatters.money(b.paymentAmount)}',
                                          ),
                                        ],
                                      ),
                                      isThreeLine: true,
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          V2PageRoute<void>(
                                            page: BookingDetailPage(bookingId: b.id),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                              childCount: visible.length,
                            ),
                          ),
                        if (hasMore)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: OutlinedButton(
                                onPressed: () => setState(
                                  () => _visibleCount += _pageSize,
                                ),
                                child: Text(l10n.loadMore),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
        context,
      ),
    );
  }
}
