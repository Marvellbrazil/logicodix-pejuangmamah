import 'package:flutter/material.dart';

import '../application/api_failure.dart';
import '../domain/chat.dart';
import '../domain/job.dart';
import '../domain/money.dart';
import 'app_state.dart';
import 'app_theme.dart';
import 'chat_room_screen.dart';
import 'job_detail_screen.dart';
import 'job_widgets.dart';
import 'ui_kit.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({
    super.key,
    required this.state,
    required this.onOpenChat,
  });

  final AppState state;
  final void Function(String chatId) onOpenChat;

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await widget.state.refreshApplications();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _withdraw(Application application) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tarik lamaran?'),
        content: Text(
          'Lamaran untuk "${application.jobTitle}" akan ditandai ditarik.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Accent.danger),
            child: const Text('Tarik'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.state.updateApplication(
        application.id,
        ApplicationStatus.withdrawn,
      );
      await _refresh();
    } on ApiFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final employer = state.profile?.isEmployer ?? false;
    final items = employer ? state.inbox : state.myApplications;

    return Scaffold(
      backgroundColor: Surfaces.base,
      appBar: AppBar(
        title: Text(employer ? 'Pelamar masuk' : 'Lamaran saya'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ],
      ),
      body: _loading
          ? const LoadingLine()
          : items.isEmpty
          ? EmptyState(
              icon: employer
                  ? Icons.people_outline
                  : Icons.send_outlined,
              title: employer ? 'Belum ada pelamar' : 'Belum ada lamaran',
              body: employer
                  ? 'Pelamar akan muncul di sini begitu ada yang melamar lowonganmu.'
                  : 'Buka Beranda, lalu tekan Lamar pada lowongan yang cocok.',
              action: employer
                  ? null
                  : FilledButton(
                      onPressed: () => state.selectTab(0),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(160, 44),
                      ),
                      child: const Text('Cari lowongan'),
                    ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.md,
                Space.lg,
                Space.xl,
              ),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: Space.md),
              itemBuilder: (context, index) {
                final application = items[index];
                return _ApplicationCard(
                  application: application,
                  employerView: employer,
                  onOpen: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => JobDetailScreen(
                        state: state,
                        jobId: application.jobId,
                      ),
                    ),
                  ),
                  onChat: application.chatId == null
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ChatRoomScreen(
                              state: state,
                              chatId: application.chatId!,
                            ),
                          ),
                        ),
                  onWithdraw: application.status == ApplicationStatus.withdrawn
                      ? null
                      : () => _withdraw(application),
                  onStatus: (status) async {
                    await state.updateApplication(application.id, status);
                    await _refresh();
                  },
                );
              },
            ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.employerView,
    required this.onOpen,
    required this.onStatus,
    this.onChat,
    this.onWithdraw,
  });

  final Application application;
  final bool employerView;
  final VoidCallback onOpen;
  final void Function(ApplicationStatus status) onStatus;
  final VoidCallback? onChat;
  final VoidCallback? onWithdraw;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = employerView
        ? application.employerDisplayName
        : application.employerDisplayName;

    return Panel(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(
                initials: _initials(name),
                photoUrl: application.employerPhotoUrl,
                size: 42,
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.jobTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${application.company} · ${application.district}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.sm),
              StatusTag(status: application.status),
            ],
          ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              Tag(
                label: '${Money(application.pay).formatShort()} ${application.payPeriod}',
                tone: TagTone.teal,
              ),
              UrgencyTag(urgency: application.urgency),
            ],
          ),
          const SizedBox(height: Space.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Dilamar ${relativeTime(application.createdAt)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              if (onChat != null)
                TextButton.icon(
                  onPressed: onChat,
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Chat'),
                ),
            ],
          ),
          if (!employerView &&
              application.status == ApplicationStatus.sent &&
              onWithdraw != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onWithdraw,
                style: TextButton.styleFrom(foregroundColor: Accent.danger),
                child: const Text('Tarik lamaran'),
              ),
            ),
          if (employerView) ...[
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                for (final status in const [
                  ApplicationStatus.viewed,
                  ApplicationStatus.interview,
                  ApplicationStatus.accepted,
                  ApplicationStatus.rejected,
                ])
                  ActionChip(
                    label: Text(status.label),
                    onPressed: () => onStatus(status),
                    backgroundColor: application.status == status
                        ? Accent.tealWash
                        : Surfaces.overlay,
                    side: BorderSide(
                      color: application.status == status
                          ? Accent.teal
                          : Surfaces.lineSoft,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
