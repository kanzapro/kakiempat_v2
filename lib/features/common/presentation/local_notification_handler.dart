import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:kaki_empat/core/services/event_notification_service.dart';
import 'package:kaki_empat/core/services/notification_v2_service.dart';
import 'package:overlay_support/overlay_support.dart';

/// Polling ke notification_v2.php + pop-up overlay (tanpa Firebase/FCM).
class LocalNotificationHandler {
  LocalNotificationHandler({required this.userId});

  final int userId;
  Timer? _pollingTimer;
  final LinkedHashSet<String> _shownIds = LinkedHashSet<String>();

  void startListening() {
    _pollingTimer?.cancel();
    _checkServerNotifications();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkServerNotifications(),
    );
  }

  void stopListening() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _shownIds.clear();
  }

  Future<void> _checkServerNotifications() async {
    try {
      final v2Batch = await NotificationV2Service.instance.pollUnreadBatch();
      if (v2Batch.isEmpty) {
        final legacy = await EventNotificationService.instance.pollUnreadBatch(
          userId: userId,
        );
        for (final notif in legacy) {
          _showIfNew(notif.id, notif.title, notif.message);
        }
        return;
      }

      for (final notif in v2Batch) {
        _showIfNew(notif.id, notif.title, notif.message);
      }
    } catch (e) {
      debugPrint('Gagal polling notifikasi lokal: $e');
    }
  }

  void _showIfNew(String id, String title, String message) {
    if (_shownIds.contains(id)) return;
    _shownIds.add(id);
    if (_shownIds.length > 100) {
      _shownIds.remove(_shownIds.first);
    }
    _triggerOverlayPopup(title, message);
  }

  void _triggerOverlayPopup(String title, String message) {
    showOverlayNotification(
      (context) {
        final scheme = Theme.of(context).colorScheme;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: scheme.primaryContainer,
          elevation: 4,
          child: SafeArea(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.primary,
                child: Icon(Icons.pets, color: scheme.onPrimary, size: 22),
              ),
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              subtitle: Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.close, size: 20, color: scheme.onPrimaryContainer),
                onPressed: () => OverlaySupportEntry.of(context)?.dismiss(),
              ),
            ),
          ),
        );
      },
      duration: const Duration(seconds: 4),
    );
  }
}
