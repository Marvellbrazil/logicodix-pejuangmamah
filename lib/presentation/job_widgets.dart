import 'package:flutter/material.dart';

import '../domain/chat.dart';
import '../domain/job.dart';
import '../domain/match.dart';
import 'app_theme.dart';
import 'ui_kit.dart';

String hourLabel(int hour) => '${hour.toString().padLeft(2, '0')}:00';

String distanceLabel(double km) =>
    '${km.toStringAsFixed(1).replaceAll('.', ',')} km';

String relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 30) return '${diff.inDays} hari lalu';
  return '${(diff.inDays / 30).floor()} bulan lalu';
}

Color scoreColor(BuildContext context, MatchBand band) => switch (band) {
  MatchBand.high => Accent.teal,
  MatchBand.medium => Accent.amber,
  MatchBand.low => Accent.danger,
};

TagTone scoreTone(MatchBand band) => switch (band) {
  MatchBand.high => TagTone.teal,
  MatchBand.medium => TagTone.amber,
  MatchBand.low => TagTone.danger,
};

class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, required this.match, this.compact = false});

  final Match match;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(context, match.band);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: Radii.smAll,
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, size: compact ? 11 : 13, color: color),
          const SizedBox(width: 2),
          Text(
            '${match.score}',
            style: TextStyle(
              fontSize: compact ? 11.5 : 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class UrgencyTag extends StatelessWidget {
  const UrgencyTag({super.key, required this.urgency});

  final JobUrgency urgency;

  @override
  Widget build(BuildContext context) {
    return Tag(
      label: urgency.label,
      tone: switch (urgency) {
        JobUrgency.today => TagTone.amber,
        JobUrgency.thisWeek => TagTone.neutral,
        JobUrgency.flexible => TagTone.neutral,
      },
      icon: urgency == JobUrgency.today ? Icons.bolt : null,
    );
  }
}

class StatusTag extends StatelessWidget {
  const StatusTag({super.key, required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    return Tag(
      label: status.label,
      tone: switch (status) {
        ApplicationStatus.accepted => TagTone.success,
        ApplicationStatus.interview => TagTone.teal,
        ApplicationStatus.viewed => TagTone.teal,
        ApplicationStatus.rejected => TagTone.danger,
        ApplicationStatus.withdrawn => TagTone.neutral,
        ApplicationStatus.sent => TagTone.amber,
      },
    );
  }
}

class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.match,
    required this.onTap,
    this.onApply,
    this.showScore = true,
  });

  final Match match;
  final VoidCallback onTap;
  final VoidCallback? onApply;
  final bool showScore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final job = match.job;
    final employerInitials = (job.employer?.displayName ?? job.company).isEmpty
        ? '?'
        : (job.employer?.displayName ?? job.company)[0].toUpperCase();

    return Semantics(
      button: true,
      label:
          '${job.title} di ${job.company}, ${distanceLabel(job.distanceKm)}'
          '${showScore ? ', skor ${match.score} dari 100' : ''}',
      child: Panel(
        onTap: onTap,
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Avatar(
                  initials: employerInitials,
                  photoUrl: job.employer?.photoUrl,
                  size: 42,
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${job.company} · ${job.district}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (showScore) ...[
                  const SizedBox(width: Space.sm),
                  ScoreBadge(match: match),
                ],
              ],
            ),
            const SizedBox(height: Space.md),
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
              ],
            ),
            if (showScore && match.reasons.isNotEmpty) ...[
              const SizedBox(height: Space.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, size: 13, color: Accent.teal),
                  const SizedBox(width: Space.xs + 2),
                  Expanded(
                    child: Text(
                      match.reasons.first,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: Accent.teal,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: Space.md),
            Row(
              children: [
                Text(
                  relativeTime(job.createdAt),
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                if (job.applied)
                  Tag(
                    label: job.applicationStatus?.label ?? 'Dilamar',
                    tone:
                        job.applicationStatus == ApplicationStatus.accepted
                        ? TagTone.success
                        : TagTone.teal,
                    icon: Icons.check,
                  )
                else if (onApply != null)
                  SizedBox(
                    height: 34,
                    child: FilledButton(
                      onPressed: onApply,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.lg,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Lamar'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MatchReasons extends StatelessWidget {
  const MatchReasons({super.key, required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final reason in match.reasons)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, size: 15, color: Accent.teal),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(reason, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
        for (final gap in match.gaps)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 15,
                  color: TextTone.muted,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(gap, style: theme.textTheme.bodySmall),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class ScoreBreakdown extends StatelessWidget {
  const ScoreBreakdown({super.key, required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, int, int)>[
      ('Keahlian', match.skillScore, 35),
      ('Jarak', match.distanceScore, 25),
      ('Upah', match.payScore, 20),
      ('Jadwal', match.scheduleScore, 20),
    ];
    return Column(
      children: [
        for (final (label, value, max) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: Row(
              children: [
                SizedBox(
                  width: 74,
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: max == 0 ? 0 : value / max,
                      minHeight: 5,
                      backgroundColor: Surfaces.overlay,
                      valueColor: const AlwaysStoppedAnimation(Accent.teal),
                    ),
                  ),
                ),
                const SizedBox(width: Space.md),
                SizedBox(
                  width: 46,
                  child: Text(
                    '$value/$max',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class ChatTile extends StatelessWidget {
  const ChatTile({super.key, required this.chat, required this.onTap});

  final ChatSummary chat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Panel(
      onTap: onTap,
      padding: const EdgeInsets.all(Space.md),
      child: Row(
        children: [
          Avatar(
            initials: chat.counterpart.initials,
            photoUrl: chat.counterpart.photoUrl,
            size: 44,
            highlight: chat.unread > 0,
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        chat.counterpart.fullName.isEmpty
                            ? chat.company
                            : chat.counterpart.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: chat.unread > 0
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      relativeTime(chat.lastMessageAt),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  chat.jobTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: Accent.teal),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        chat.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    if (chat.unread > 0) ...[
                      const SizedBox(width: Space.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: const BoxDecoration(
                          color: Accent.teal,
                          borderRadius: BorderRadius.all(Radius.circular(99)),
                        ),
                        child: Text(
                          '${chat.unread}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Accent.tealInk,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
