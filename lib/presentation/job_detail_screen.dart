import 'package:flutter/material.dart';

import '../application/api_failure.dart';
import '../domain/job.dart';
import '../domain/match.dart';
import 'app_state.dart';
import 'app_theme.dart';
import 'applicants_screen.dart';
import 'job_widgets.dart';
import 'ui_kit.dart';

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({
    super.key,
    required this.state,
    required this.jobId,
  });

  final AppState state;
  final String jobId;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  Job? _job;
  Match? _match;
  String? _error;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final job = await widget.state.fetchJob(widget.jobId);
      final profile = widget.state.profile;
      if (!mounted) return;
      setState(() {
        _job = job;
        _match = profile == null ? null : Match.evaluate(job, profile);
        _error = null;
      });
    } on ApiFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _apply() async {
    final job = _job;
    if (job == null || _applying) return;
    setState(() => _applying = true);
    try {
      await widget.state.apply(job.id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lamaran terkirim. Chat dengan pemberi kerja dibuka.'),
        ),
      );
    } on ApiFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final job = _job;
    final profile = widget.state.profile;
    final isOwner = job != null && profile != null && job.employerId == profile.id;

    return Scaffold(
      backgroundColor: Surfaces.base,
      appBar: AppBar(
        title: const Text('Detail lowongan'),
        actions: [
          if (isOwner)
            IconButton(
              tooltip: 'Lihat pelamar',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ApplicantsScreen(state: widget.state, jobId: widget.jobId),
                ),
              ),
              icon: const Icon(Icons.people_outline),
            ),
        ],
      ),
      body: _error != null
          ? Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: ErrorBanner(message: _error!, onRetry: _load),
            )
          : job == null
          ? const LoadingLine()
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.sm,
                Space.lg,
                Space.xxl,
              ),
              children: [
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Avatar(
                            initials: (job.employer?.displayName ?? job.company)
                                    .isEmpty
                                ? '?'
                                : (job.employer?.displayName ??
                                          job.company)[0]
                                      .toUpperCase(),
                            photoUrl: job.employer?.photoUrl,
                            size: 48,
                            highlight: true,
                          ),
                          const SizedBox(width: Space.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  job.title,
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${job.company} · ${job.district}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.lg),
                      Wrap(
                        spacing: Space.sm,
                        runSpacing: Space.sm,
                        children: [
                          Tag(
                            label: '${job.money.formatShort()} ${job.payPeriod}',
                            tone: TagTone.teal,
                          ),
                          Tag(label: distanceLabel(job.distanceKm)),
                          Tag(
                            label:
                                '${hourLabel(job.startHour)}–${hourLabel(job.endHour)}',
                          ),
                          UrgencyTag(urgency: job.urgency),
                          if (job.filled)
                            const Tag(
                              label: 'Sudah terisi',
                              tone: TagTone.danger,
                            ),
                        ],
                      ),
                      if (job.skills.isNotEmpty) ...[
                        const SizedBox(height: Space.lg),
                        Wrap(
                          spacing: Space.sm,
                          runSpacing: Space.sm,
                          children: [
                            for (final skill in job.skills)
                              Tag(label: skill, tone: TagTone.neutral),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (_match != null && !isOwner) ...[
                  const SizedBox(height: Space.lg),
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Skor kecocokan',
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            ScoreBadge(match: _match!),
                          ],
                        ),
                        const SizedBox(height: Space.lg),
                        ScoreBreakdown(match: _match!),
                        MatchReasons(match: _match!),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: Space.lg),
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Deskripsi', style: theme.textTheme.titleSmall),
                      const SizedBox(height: Space.sm),
                      Text(job.description, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: Space.md),
                      Text(
                        'Diterbitkan ${relativeTime(job.createdAt)} · '
                        '${job.applicantCount} pelamar',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.xl),
                if (isOwner)
                  _OwnerActions(
                    job: job,
                    onToggle: (filled) async {
                      await widget.state.setJobFilled(job.id, filled);
                      await _load();
                    },
                    onDelete: () async {
                      final confirmed = await _confirmDelete(context);
                      if (confirmed != true) return;
                      await widget.state.deleteJob(job.id);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  )
                else if (job.applied)
                  Panel(
                    color: Accent.tealWash,
                    borderColor: Accent.teal.withValues(alpha: 0.3),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Accent.teal,
                          size: 20,
                        ),
                        const SizedBox(width: Space.md),
                        Expanded(
                          child: Text(
                            'Lamaranmu ${(job.applicationStatus ?? ApplicationStatus.sent).label.toLowerCase()}. '
                            'Lanjutkan di tab Lamaran.',
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: Accent.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  FilledButton(
                    onPressed: job.filled || _applying ? null : _apply,
                    child: _applying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Accent.tealInk,
                            ),
                          )
                        : Text(job.filled ? 'Lowongan sudah terisi' : 'Lamar sekarang'),
                  ),
              ],
            ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Hapus lowongan?'),
      content: const Text(
        'Lowongan dan riwayat lamarannya akan hilang dari semua perangkat.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: Accent.danger),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
}

class _OwnerActions extends StatefulWidget {
  const _OwnerActions({
    required this.job,
    required this.onToggle,
    required this.onDelete,
  });

  final Job job;
  final Future<void> Function(bool filled) onToggle;
  final Future<void> Function() onDelete;

  @override
  State<_OwnerActions> createState() => _OwnerActionsState();
}

class _OwnerActionsState extends State<_OwnerActions> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kelola lowongan', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: Space.md),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tandai sudah terisi'),
            subtitle: const Text(
              'Lowongan terisi disembunyikan dari antrean pencari kerja.',
              style: TextStyle(fontSize: 12),
            ),
            value: widget.job.filled,
            onChanged: _busy
                ? null
                : (value) async {
                    setState(() => _busy = true);
                    await widget.onToggle(value);
                    if (mounted) setState(() => _busy = false);
                  },
          ),
          const Divider(color: Surfaces.lineSoft),
          TextButton.icon(
            onPressed: _busy ? null : widget.onDelete,
            style: TextButton.styleFrom(foregroundColor: Accent.danger),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Hapus lowongan'),
          ),
        ],
      ),
    );
  }
}
