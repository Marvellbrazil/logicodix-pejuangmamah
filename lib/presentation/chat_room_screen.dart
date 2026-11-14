import 'package:flutter/material.dart';

import '../application/api_failure.dart';
import '../domain/chat.dart';
import 'app_state.dart';
import 'app_theme.dart';
import 'job_widgets.dart';
import 'ui_kit.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.state,
    required this.chatId,
  });

  final AppState state;
  final String chatId;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen>
    with WidgetsBindingObserver {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  ChatSummary? _chat;
  List<ChatMessage> _messages = const [];
  bool _loading = true;
  bool _sending = false;
  bool _readBusy = false;
  String? _error;
  int _loadSequence = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load(silent: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    final sequence = ++_loadSequence;
    if (!silent) setState(() => _loading = true);
    try {
      final (chat, messages) = await widget.state.openChat(widget.chatId);
      if (!mounted || sequence != _loadSequence) return;
      final shouldStick = !_scroll.hasClients || _scroll.position.pixels < 120;
      setState(() {
        _chat = chat;
        _messages = messages;
        _error = null;
      });
      if (shouldStick) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _stickToBottom());
      }
      if (chat != null && chat.unread > 0 && !_readBusy) {
        _readBusy = true;
        try {
          await widget.state.markChatRead(widget.chatId);
        } finally {
          _readBusy = false;
        }
      }
    } on ApiFailure catch (error) {
      if (mounted && !silent && sequence == _loadSequence) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted && !silent && sequence == _loadSequence) {
        setState(() => _loading = false);
      }
    }
  }

  void _stickToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _input.clear();
    try {
      final message = await widget.state.sendMessage(widget.chatId, text);
      if (!mounted) return;
      setState(() => _messages = [..._messages, message]);
      WidgetsBinding.instance.addPostFrameCallback((_) => _stickToBottom());
    } on ApiFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final counterpart = _chat?.counterpart;
    return Scaffold(
      backgroundColor: Surfaces.base,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            if (counterpart != null)
              Avatar(
                initials: counterpart.initials,
                photoUrl: counterpart.photoUrl,
                size: 34,
              ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    counterpart?.fullName.isNotEmpty == true
                        ? counterpart!.fullName
                        : _chat?.company ?? 'Percakapan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (_chat != null)
                    Text(
                      _chat!.jobTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: TextTone.muted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const LoadingLine()
                : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(Space.lg),
                    child: ErrorBanner(message: _error!, onRetry: _load),
                  )
                : _messages.isEmpty
                ? const EmptyState(
                    icon: Icons.waving_hand_outlined,
                    title: 'Mulai percakapan',
                    body:
                        'Perkenalkan dirimu singkat: kapan bisa mulai dan apa keahlianmu.',
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(
                      Space.lg,
                      Space.md,
                      Space.lg,
                      Space.md,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _Bubble(message: message);
                    },
                  ),
          ),
          _Composer(
            controller: _input,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.mine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: Space.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm + 2,
        ),
        decoration: BoxDecoration(
          color: mine ? Accent.teal : Surfaces.raised,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(Radii.md),
            topRight: const Radius.circular(Radii.md),
            bottomLeft: Radius.circular(mine ? Radii.md : 4),
            bottomRight: Radius.circular(mine ? 4 : Radii.md),
          ),
          border: mine ? null : Border.all(color: Surfaces.lineSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.body,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: mine ? Accent.tealInk : TextTone.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              relativeTime(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: mine
                    ? Accent.tealInk.withValues(alpha: 0.6)
                    : TextTone.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        Space.lg,
        Space.md,
        Space.lg,
        Space.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Surfaces.surface,
        border: Border(top: BorderSide(color: Surfaces.lineSoft)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Tulis pesan…',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: Space.md,
                  vertical: Space.md,
                ),
              ),
            ),
          ),
          const SizedBox(width: Space.sm),
          SizedBox(
            width: 46,
            height: 46,
            child: IconButton.filled(
              onPressed: sending ? null : onSend,
              tooltip: 'Kirim',
              style: IconButton.styleFrom(
                backgroundColor: Accent.teal,
                foregroundColor: Accent.tealInk,
                shape: RoundedRectangleBorder(borderRadius: Radii.mdAll),
              ),
              icon: const Icon(Icons.send_rounded, size: 19),
            ),
          ),
        ],
      ),
    );
  }
}
