import 'dart:async';

import 'package:flutter/material.dart';

import '../application/api_failure.dart';
import 'app_state.dart';
import 'app_theme.dart';
import 'chat_room_screen.dart';
import 'job_widgets.dart';
import 'ui_kit.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
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
      await widget.state.refreshChats();
    } on ApiFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chats = widget.state.chats;
    return Scaffold(
      backgroundColor: Surfaces.base,
      appBar: AppBar(
        title: const Text('Pesan'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _load,
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ],
      ),
      body: _loading
          ? const LoadingLine()
          : _error != null
          ? Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: ErrorBanner(message: _error!, onRetry: _load),
            )
          : chats.isEmpty
          ? const EmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'Belum ada percakapan',
              body:
                  'Percakapan dibuat otomatis saat kamu melamar lowongan atau menerima pelamar.',
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: Accent.teal,
              backgroundColor: Surfaces.raised,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  Space.md,
                  Space.lg,
                  Space.xl,
                ),
                itemCount: chats.length,
                separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  return ChatTile(
                    chat: chat,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatRoomScreen(
                            state: widget.state,
                            chatId: chat.id,
                          ),
                        ),
                      );
                      await _load();
                    },
                  );
                },
              ),
            ),
    );
  }
}
