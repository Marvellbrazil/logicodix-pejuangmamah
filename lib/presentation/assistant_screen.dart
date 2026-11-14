import 'package:flutter/material.dart';

import '../application/ask_assistant.dart';
import 'app_state.dart';
import 'app_theme.dart';

class _Message {
  const _Message(this.text, {required this.fromUser, this.status = ''});

  final String text;
  final bool fromUser;
  final String status;
}

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({
    super.key,
    required this.state,
    required this.askAssistant,
  });

  final AppState state;
  final AskAssistant askAssistant;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Message> _messages = [
    const _Message(
      'Halo! Aku Asisten Kerjaqueue. Tanya apa saja soal lowongan hari ini, '
      'atau minta bantu supaya profilmu lebih dilirik.',
      fromUser: false,
    ),
  ];
  bool _thinking = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final question = (preset ?? _input.text).trim();
    if (question.isEmpty || _thinking) return;
    _input.clear();
    setState(() {
      _messages.add(_Message(question, fromUser: true));
      _thinking = true;
    });
    _scrollDown();

    final history = [
      for (final message in _messages.take(_messages.length - 1))
        (message.fromUser ? 'user' : 'assistant', message.text),
    ];
    final profile = widget.state.profile;
    if (profile == null) return;
    final turn = await widget.askAssistant(
      question: question,
      history: history,
      profile: profile,
      ranked: widget.state.ranked,
    );
    if (!mounted) return;
    setState(() {
      _messages.add(_Message(turn.text, fromUser: false, status: turn.status));
      _thinking = false;
    });
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Surfaces.base,
      appBar: AppBar(
        titleSpacing: Space.lg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 17, color: Accent.teal),
                const SizedBox(width: Space.sm),
                Text('Asisten Kerjaqueue', style: theme.textTheme.titleMedium),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 25, top: 1),
              child: Text(
                widget.askAssistant.gatewayAvailable
                    ? 'Z.ai · saran memakai datamu'
                    : 'Mode lokal · tanpa jaringan',
                style: theme.textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.md,
                Space.lg,
                Space.lg,
              ),
              itemCount: _messages.length + (_thinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _messages.length) {
                  return const _Bubble(text: 'Asisten sedang mengetik…', fromUser: false);
                }
                final message = _messages[index];
                return _Bubble(
                  text: message.text,
                  fromUser: message.fromUser,
                  status: message.status,
                );
              },
            ),
          ),
          if (_messages.length == 1) _Suggestions(onTap: _send),
          Container(
            decoration: const BoxDecoration(
              color: Surfaces.surface,
              border: Border(top: BorderSide(color: Surfaces.lineSoft)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  Space.md,
                  Space.md,
                  Space.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Tulis pertanyaan…',
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
                        onPressed: _thinking ? null : _send,
                        style: IconButton.styleFrom(
                          backgroundColor: Accent.teal,
                          foregroundColor: Accent.tealInk,
                          shape: RoundedRectangleBorder(
                            borderRadius: Radii.mdAll,
                          ),
                        ),
                        icon: const Icon(Icons.arrow_upward, size: 19),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.onTap});

  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      'Lowongan apa yang paling cocok untukku?',
      'Ada kerjaan hari ini di dekat rumah?',
      'Upah tertinggi minggu ini berapa?',
    ];
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.lg),
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(right: Space.sm),
              child: ActionChip(
                label: Text(item),
                onPressed: () => onTap(item),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.fromUser, this.status = ''});

  final String text;
  final bool fromUser;
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: Space.md),
        padding: const EdgeInsets.all(Space.md + 2),
        decoration: BoxDecoration(
          color: fromUser ? Accent.teal : Surfaces.raised,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(Radii.md),
            topRight: const Radius.circular(Radii.md),
            bottomLeft: Radius.circular(fromUser ? Radii.md : 4),
            bottomRight: Radius.circular(fromUser ? 4 : Radii.md),
          ),
          border: fromUser ? null : Border.all(color: Surfaces.lineSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: fromUser ? Accent.tealInk : TextTone.primary,
                height: 1.5,
              ),
            ),
            if (status.isNotEmpty) ...[
              const SizedBox(height: Space.sm),
              Text(
                status,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fromUser ? Accent.tealInk : TextTone.muted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
