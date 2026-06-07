import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kaki_empat/core/services/notification_v2_service.dart';
import 'package:kaki_empat/features/shared/presentation/notifications_page.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

/// Tombol notifikasi dengan badge unread; polling setiap 30 detik.
class NotificationBadgeButton extends StatefulWidget {
  const NotificationBadgeButton({super.key});

  @override
  State<NotificationBadgeButton> createState() =>
      _NotificationBadgeButtonState();
}

class _NotificationBadgeButtonState extends State<NotificationBadgeButton> {
  int _unread = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _check();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    try {
      final count = await NotificationV2Service.instance.checkNew();
      if (!mounted) return;
      setState(() => _unread = count);
    } catch (_) {}
  }

  Future<void> _open() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const NotificationsPage()),
    );
    await _check();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      tooltip: l10n.notificationsTitle,
      onPressed: _open,
      icon: Badge(
        isLabelVisible: _unread > 0,
        label: Text(_unread > 99 ? '99+' : '$_unread'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
