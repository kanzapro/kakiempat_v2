import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kaki_empat/core/formatters/v2_formatters.dart';
import 'package:kaki_empat/core/services/auth_service_v2.dart';
import 'package:kaki_empat/core/services/chat_v2_service.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/features/shared/widgets/v2_empty_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_error_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_loading_skeleton.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<ChatMessageV2> _messages = [];
  String? _currentUserIdStr;
  String _since = DateTime.now().toUtc().toIso8601String();
  bool _loading = true;
  bool _sending = false;
  bool _hasNewBadge = false;
  Object? _error;
  Timer? _pollTimer;
  static const _visibleBatch = 40;
  int _visibleCount = _visibleBatch;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final user = await AuthServiceV2.instance.getStoredUser();
    if (!mounted) return;
    setState(() => _currentUserIdStr = user?.id.toString());
    await _loadMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollNew());
  }

  Future<void> _loadMessages() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final messages =
          await ChatV2Service.instance.getMessages(widget.bookingId);
      if (!mounted) return;
      final since = messages.isNotEmpty
          ? messages.last.createdAt
          : DateTime.now().toUtc().toIso8601String();
      setState(() {
        _messages = messages;
        _since = since;
        _loading = false;
        _hasNewBadge = false;
        _visibleCount = _visibleBatch;
      });
      _scrollToBottom();
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

  Future<void> _pollNew() async {
    if (_loading || _sending) return;
    try {
      final result = await ChatV2Service.instance.checkNewMessages(
        bookingId: widget.bookingId,
        since: _since,
      );
      if (!mounted) return;
      if (result.hasNew) {
        setState(() => _hasNewBadge = true);
        await _loadMessages();
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final sent = await ChatV2Service.instance.sendMessage(
        bookingId: widget.bookingId,
        text: text,
      );
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, sent];
        _since = sent.createdAt.isNotEmpty
            ? sent.createdAt
            : DateTime.now().toUtc().toIso8601String();
        _sending = false;
        _hasNewBadge = false;
      });
      _messageController.clear();
      _scrollToBottom();
    } on V2ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      setState(() => _sending = false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.chatSendFailed)),
      );
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final visible = _messages.length <= _visibleCount
        ? _messages
        : _messages.sublist(_messages.length - _visibleCount);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chatTitle),
        actions: [
          if (_hasNewBadge)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Badge(
                label: const Text('!'),
                child: Icon(
                  Icons.mark_chat_unread_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
      body: V2Responsive.constrain(
        Column(
          children: [
            Expanded(
              child: _loading
                  ? const V2ChatSkeleton()
                  : _error != null
                      ? V2ErrorState.fromError(
                          context,
                          error: _error,
                          onRetry: _loadMessages,
                        )
                      : _messages.isEmpty
                          ? V2EmptyState(message: l10n.chatEmpty, icon: Icons.chat_bubble_outline)
                          : Column(
                              children: [
                                if (_messages.length > _visibleCount)
                                  TextButton(
                                    onPressed: () => setState(
                                      () => _visibleCount += _visibleBatch,
                                    ),
                                    child: Text(l10n.loadMore),
                                  ),
                                Expanded(
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.all(16),
                                    itemCount: visible.length,
                                    itemBuilder: (context, index) {
                                      final msg = visible[index];
                              final isMine =
                                  msg.senderUserId == _currentUserIdStr;
                              return Align(
                                alignment: isMine
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.sizeOf(context).width * 0.75,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMine
                                        ? theme.colorScheme.primaryContainer
                                        : theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(msg.text),
                                      const SizedBox(height: 4),
                                      Text(
                                        V2Formatters.dateTime(msg.createdAt),
                                        style: theme.textTheme.labelSmall,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                                  ),
                                ),
                              ],
                            ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: l10n.chatInputHint,
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sending ? null : _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
        ),
        context,
      ),
    );
  }
}
