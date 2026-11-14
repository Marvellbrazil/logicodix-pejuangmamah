import 'package:flutter/material.dart';

import '../application/api_failure.dart';
import '../domain/profile.dart';
import 'app_state.dart';
import 'app_theme.dart';
import 'job_widgets.dart';
import 'ui_kit.dart';

class PersonScreen extends StatefulWidget {
  const PersonScreen({super.key, required this.state, required this.personId});

  final AppState state;
  final String personId;

  @override
  State<PersonScreen> createState() => _PersonScreenState();
}

class _PersonScreenState extends State<PersonScreen> {
  PublicProfile? _person;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final person = await widget.state.fetchPerson(widget.personId);
      if (mounted) setState(() => _person = person);
    } on ApiFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final person = _person;
    return Scaffold(
      backgroundColor: Surfaces.base,
      appBar: AppBar(title: const Text('Profil')),
      body: _error != null
          ? Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: ErrorBanner(message: _error!, onRetry: _load),
            )
          : person == null
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Avatar(
                        initials: person.initials,
                        photoUrl: person.photoUrl,
                        size: 60,
                        highlight: true,
                      ),
                      const SizedBox(width: Space.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              person.fullName,
                              style: theme.textTheme.titleLarge,
                            ),
                            Text(
                              '“${person.displayName}”',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Accent.teal,
                              ),
                            ),
                            const SizedBox(height: Space.xs),
                            Text(
                              person.headline.isEmpty
                                  ? person.role.label
                                  : person.headline,
                              style: theme.textTheme.bodyMedium,
                            ),
                            if (person.district.isNotEmpty)
                              Text(
                                person.district,
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (person.bio.isNotEmpty) ...[
                  const SizedBox(height: Space.xl),
                  const SectionTitle(title: 'Tentang'),
                  Panel(
                    child: Text(person.bio, style: theme.textTheme.bodyLarge),
                  ),
                ],
                if (person.skills.isNotEmpty) ...[
                  const SizedBox(height: Space.xl),
                  const SectionTitle(title: 'Keahlian'),
                  Panel(
                    child: Wrap(
                      spacing: Space.sm,
                      runSpacing: Space.sm,
                      children: [
                        for (final skill in person.skills)
                          Tag(label: skill, tone: TagTone.teal),
                      ],
                    ),
                  ),
                ],
                if (person.experience.isNotEmpty) ...[
                  const SizedBox(height: Space.xl),
                  const SectionTitle(title: 'Pengalaman'),
                  for (final item in person.experience) ...[
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: theme.textTheme.titleSmall),
                          if (item.company.isNotEmpty || item.period.isNotEmpty)
                            Text(
                              [item.company, item.period]
                                  .where((part) => part.isNotEmpty)
                                  .join(' · '),
                              style: theme.textTheme.bodySmall,
                            ),
                          if (item.detail.isNotEmpty) ...[
                            const SizedBox(height: Space.sm),
                            Text(
                              item.detail,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: Space.sm),
                  ],
                ],
                if (person.openJobs.isNotEmpty) ...[
                  const SizedBox(height: Space.xl),
                  const SectionTitle(title: 'Lowongan aktif'),
                  for (final job in person.openJobs) ...[
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${job.company} · ${job.pay.toDouble().toStringAsFixed(0)} '
                            '${job.payPeriod}',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: Space.sm),
                          UrgencyTag(urgency: job.urgency),
                        ],
                      ),
                    ),
                    const SizedBox(height: Space.sm),
                  ],
                ],
              ],
            ),
    );
  }
}
