import 'package:flutter/material.dart';
import 'package:kaki_empat/core/services/auth_service_v2.dart';
import 'package:kaki_empat/features/common/presentation/local_notification_handler.dart';

/// Memulai polling overlay notifikasi saat user login (owner/sitter).
class EventNotificationShell extends StatefulWidget {
  const EventNotificationShell({super.key, required this.child});

  final Widget child;

  @override
  State<EventNotificationShell> createState() => _EventNotificationShellState();
}

class _EventNotificationShellState extends State<EventNotificationShell> {
  LocalNotificationHandler? _handler;

  @override
  void initState() {
    super.initState();
    _startIfLoggedIn();
  }

  @override
  void dispose() {
    _handler?.stopListening();
    super.dispose();
  }

  Future<void> _startIfLoggedIn() async {
    final user = await AuthServiceV2.instance.getStoredUser();
    if (!mounted || user == null) return;
    _handler?.stopListening();
    _handler = LocalNotificationHandler(userId: user.id);
    _handler!.startListening();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
