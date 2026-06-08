import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kaki_empat/core/formatters/v2_formatters.dart';
import 'package:kaki_empat/core/services/notification_v2_service.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/features/shared/widgets/v2_empty_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_error_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_loading_skeleton.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const _pageSize = 20;

  String? _typeFilter;
  List<AppNotificationV2> _items = [];
  int _unread = 0;
  int _page = 1;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _marking = false;
  Object? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final pageNum = reset ? 1 : _page;
      final results = await Future.wait([
        NotificationV2Service.instance.getNotifications(
          page: pageNum,
          limit: _pageSize,
          typeFilter: _typeFilter,
        ),
        NotificationV2Service.instance.checkNew(),
      ]);
      if (!mounted) return;
      final page = results[0] as NotificationPageResult;
      setState(() {
        if (reset) {
          _items = page.notifications;
        } else {
          _items = [..._items, ...page.notifications];
        }
        _unread = results[1] as int;
        _hasMore = page.hasMore;
        _page = pageNum + 1;
        _loading = false;
        _loadingMore = false;
      });
    } on V2ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _poll() async {
    try {
      final count = await NotificationV2Service.instance.checkNew();
      if (!mounted) return;
      if (count > _unread) {
        await _load(reset: true);
      } else {
        setState(() => _unread = count);
      }
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    setState(() => _marking = true);
    try {
      await NotificationV2Service.instance.markRead(markAll: true);
      if (!mounted) return;
      await _load(reset: true);
    } on V2ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          if (_unread > 0)
            TextButton(
              onPressed: _marking ? null : _markAllRead,
              child: _marking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.notificationsMarkAllRead),
            ),
        ],
      ),
      body: V2Responsive.constrain(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: _filterChips(l10n),
              ),
            ),
            Expanded(
              child: _loading
            ? const V2ListSkeleton()
            : _error != null && _items.isEmpty
                ? V2ErrorState.fromError(
                    context,
                    error: _error,
                    onRetry: () => _load(reset: true),
                  )
                : RefreshIndicator(
                    onRefresh: () => _load(reset: true),
                    child: _items.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.sizeOf(context).height * 0.4,
                                child: V2EmptyState(
                                  message: l10n.notificationsEmpty,
                                  icon: Icons.notifications_none,
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: V2Responsive.pagePadding(context),
                            itemCount: _items.length + (_hasMore ? 1 : 0),
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              if (index >= _items.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: OutlinedButton(
                                    onPressed: _loadingMore
                                        ? null
                                        : () => _load(reset: false),
                                    child: _loadingMore
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(l10n.loadMore),
                                  ),
                                );
                              }
                              final n = _items[index];
                              return Dismissible(
                                key: ValueKey(n.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  child: Icon(Icons.check, color: theme.colorScheme.primary),
                                ),
                                confirmDismiss: (_) async {
                                  if (!n.isRead) {
                                    await NotificationV2Service.instance.markRead(
                                      notificationId: n.id,
                                    );
                                  }
                                  return false;
                                },
                                child: ListTile(
                                leading: Icon(
                                  _iconForType(n.type),
                                  color: n.isRead
                                      ? theme.colorScheme.onSurfaceVariant
                                      : theme.colorScheme.primary,
                                ),
                                title: Text(
                                  n.title,
                                  style: TextStyle(
                                    fontWeight: n.isRead
                                        ? FontWeight.normal
                                        : FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n.message),
                                    if (n.createdAt.isNotEmpty)
                                      Text(
                                        V2Formatters.relativeTime(
                                          n.createdAt,
                                          locale: Localizations.localeOf(context).languageCode,
                                        ),
                                        style: theme.textTheme.labelSmall,
                                      ),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                              );
                            },
                          ),
                  ),
            ),
          ],
        ),
        context,
      ),
    );
  }

  List<Widget> _filterChips(AppLocalizations l10n) {
    final filters = <(String?, String)>[
      (null, l10n.notificationsFilterAll),
      ('booking', l10n.notificationsFilterBooking),
      ('payment', l10n.notificationsFilterPayment),
      ('chat', l10n.notificationsFilterChat),
      ('loyalty', l10n.notificationsFilterLoyalty),
    ];

    return filters.map((entry) {
      final selected = _typeFilter == entry.$1;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(entry.$2),
          selected: selected,
          onSelected: (_) {
            setState(() => _typeFilter = entry.$1);
            _load(reset: true);
          },
        ),
      );
    }).toList();
  }

  static IconData _iconForType(String type) {
    return switch (type.toLowerCase()) {
      'booking' || 'booking_update' => Icons.event_note_outlined,
      'payment' || 'payment_update' => Icons.payments_outlined,
      'chat' || 'message' => Icons.chat_bubble_outline,
      'offer' || 'marketplace' => Icons.local_offer_outlined,
      'review' => Icons.star_outline,
      'wallet' || 'withdrawal' => Icons.account_balance_wallet_outlined,
      _ => Icons.notifications_outlined,
    };
  }
}
