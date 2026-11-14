import 'package:flutter/material.dart';

import '../application/api_failure.dart';
import '../domain/chat.dart';
import '../domain/job.dart';
import '../domain/match.dart';
import 'app_state.dart';
import 'app_theme.dart';
import 'job_widgets.dart';
import 'ui_kit.dart';

class ApplicantsScreen extends StatefulWidget {
  const ApplicantsScreen({super.key, required this.state, required this.jobId});

  final AppState state;
  final String jobId;

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  Job? _job;
  List<Applicant> _applicants = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final (job, applicants) = await widget.state.jobApplicants(
        widget.jobId,
      );
      if (!mounted) return;
      setState(() {
        _job = job;
        _applicants = applicants;
        _error = null;
      });
    } on ApiFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setStatus(Applicant applicant, ApplicationStatus status) async {
    try {
      await widget.state.updateApplication(applicant.applicationId, status);
      await _load();
    } on ApiFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = widget.state.profile;
    final job = _job;
    final match = job != null && profile != null
        ? Match.evaluate(job, profile)
        : null;

    return Scaffold(
      backgroundColor: Surfaces.base,
      appBar: AppBar(title: const Text('Pelamar')),
      body: _loading
          ? const LoadingLine()
          : _error != null
          ? Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: ErrorBanner(message: _error!, onRetry: _load),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.sm,
                Space.lg,
                Space.xxl,
              ),
              children: [
                if (job != null)
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.title, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text(
                          '${job.company} · ${_applicants.length} pelamar',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (match != null) ...[
                          const SizedBox(height: Space.md),
                          ScoreBreakdown(match: match),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: Space.xl),
                if (_applicants.isEmpty)
                  const EmptyState(
                    icon: Icons.people_outline,
                    title: 'Belum ada pelamar',
                    body:
                        'Bagikan lowongan ini; pelamar akan muncul lengkap dengan keahlian dan kontak.',
                  )
                else
                  for (final applicant in _applicants) ...[
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Avatar(
                                initials: applicant.initials,
                                photoUrl: applicant.photoUrl,
                                size: 44,
                                highlight: true,
                              ),
                              const SizedBox(width: Space.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      applicant.fullName,
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    Text(
                                      applicant.headline.isEmpty
                                          ? applicant.district
                                          : applicant.headline,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              StatusTag(status: applicant.status),
                            ],
                          ),
                          if (applicant.skills.isNotEmpty) ...[
                            const SizedBox(height: Space.md),
                            Wrap(
                              spacing: Space.sm,
                              runSpacing: Space.sm,
                              children: [
                                for (final skill in applicant.skills)
                                  Tag(label: skill),
                              ],
                            ),
                          ],
                          const SizedBox(height: Space.md),
                          Wrap(
                            spacing: Space.sm,
                            runSpacing: Space.sm,
                            children: [
                              for (final status in const [
                                ApplicationStatus.interview,
                                ApplicationStatus.accepted,
                                ApplicationStatus.rejected,
                              ])
                                ActionChip(
                                  label: Text(status.label),
                                  onPressed: applicant.status == status
                                      ? null
                                      : () => _setStatus(applicant, status),
                                  backgroundColor:
                                      applicant.status == status
                                      ? Accent.tealWash
                                      : Surfaces.overlay,
                                  side: BorderSide(
                                    color: applicant.status == status
                                        ? Accent.teal
                                        : Surfaces.lineSoft,
                                  ),
                                ),
                            ],
                          ),
                          if (applicant.phone.isNotEmpty &&
                              (applicant.status ==
                                      ApplicationStatus.accepted ||
                                  applicant.status ==
                                      ApplicationStatus.interview))
                            Padding(
                              padding: const EdgeInsets.only(top: Space.sm),
                              child: SelectableText(
                                applicant.phone,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Accent.teal,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Space.md),
                  ],
              ],
            ),
    );
  }
}
