import 'package:flutter/material.dart';

import '../domain/job.dart';
import '../domain/match.dart';
import '../domain/profile.dart';
import 'app_state.dart';
import 'app_theme.dart';
import 'job_detail_screen.dart';
import 'job_widgets.dart';
import 'ui_kit.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({
    super.key,
    required this.state,
    required this.onOpenAssistant,
  });

  final AppState state;
  final VoidCallback onOpenAssistant;

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  String _category = '';
  bool _refreshing = false;

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await Future.wait([
      widget.state.refreshFeed(category: _category),
      widget.state.refreshProfile(),
    ]);
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _openDetail(String id) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => JobDetailScreen(state: widget.state, jobId: id),
      ),
    );
    await _refresh();
  }

  Future<void> _apply(Job job) async {
    try {
      await widget.state.apply(job.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lamaran untuk "${job.title}" terkirim.'),
          action: SnackBarAction(
            label: 'Lihat',
            onPressed: () => widget.state.selectTab(2),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final profile = state.profile;
    final employer = profile?.isEmployer ?? false;
    final theme = Theme.of(context);

    if (employer) {
      return _EmployerFeed(
        state: state,
        onRefresh: _refresh,
        onOpenDetail: _openDetail,
      );
    }

    final matches = state.ranked;
    final visible = _category.isEmpty
        ? matches
        : matches.where((m) => m.job.category == _category).toList();

    return Scaffold(
      backgroundColor: Surfaces.base,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onOpenAssistant,
        backgroundColor: Accent.teal,
        foregroundColor: Accent.tealInk,
        icon: const Icon(Icons.auto_awesome, size: 19),
        label: const Text(
          'Asisten',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: Accent.teal,
        backgroundColor: Surfaces.raised,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Surfaces.base,
              surfaceTintColor: Colors.transparent,
              titleSpacing: Space.xl,
              title: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Accent.teal, Accent.tealDeep],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: Radii.smAll,
                    ),
                    child: const Icon(
                      Icons.work_history_outlined,
                      size: 17,
                      color: Accent.tealInk,
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Text(
                    'Kerjaqueue',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Cari lowongan',
                  onPressed: () => state.selectTab(1),
                  icon: const Icon(Icons.search, size: 22),
                ),
                const SizedBox(width: Space.sm),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, 0),
              sliver: SliverList.list(
                children: [
                  _GreetingRow(profile: profile, state: state),
                  const SizedBox(height: Space.lg),
                  if (!(profile?.isProfileComplete ?? true)) ...[
                    _ProfilePrompt(onEdit: () => state.selectTab(4)),
                    const SizedBox(height: Space.lg),
                  ],
                  _QueueHero(matches: state.rankedToday),
                  const SizedBox(height: Space.xl),
                  _CategoryStrip(
                    categories: state.categories,
                    selected: _category,
                    onSelect: (value) {
                      setState(() => _category = value);
                      state.refreshFeed(category: value);
                    },
                  ),
                  const SizedBox(height: Space.lg),
                  SectionTitle(
                    title: _category.isEmpty
                        ? 'Untukmu'
                        : 'Kategori $_category',
                    action: '${visible.length}',
                  ),
                ],
              ),
            ),
            if (state.feedError != null)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: Space.lg),
                    child: ErrorBanner(
                      message: state.feedError!,
                      onRetry: _refresh,
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, 96),
              sliver: visible.isEmpty
                  ? SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.inbox_outlined,
                        title: _category.isEmpty
                            ? 'Belum ada lowongan'
                            : 'Tidak ada di kategori ini',
                        body: _category.isEmpty
                            ? 'Tarik ke bawah untuk memuat ulang, atau lengkapi profil '
                                  'supaya jangkauan lowongannya lebih luas.'
                            : 'Coba pilih kategori lain.',
                      ),
                    )
                  : SliverList.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: Space.md),
                      itemBuilder: (context, index) {
                        final match = visible[index];
                        return JobCard(
                          match: match,
                          onTap: () => _openDetail(match.job.id),
                          onApply: match.job.applied
                              ? null
                              : () => _apply(match.job),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GreetingRow extends StatelessWidget {
  const _GreetingRow({required this.profile, required this.state});

  final Profile? profile;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = profile?.displayName ?? '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Avatar(
          initials: profile?.initials ?? '?',
          photoUrl: profile?.photoUrl,
          size: 42,
          highlight: true,
        ),
        const SizedBox(width: Space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'Halo' : 'Halo, $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                '${state.ranked.length} lowongan cocok · ${profile?.role.label ?? ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfilePrompt extends StatelessWidget {
  const _ProfilePrompt({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Panel(
      onTap: onEdit,
      color: Accent.amberWash,
      borderColor: Accent.amber.withValues(alpha: 0.3),
      child: Row(
        children: [
          const Icon(Icons.badge_outlined, color: Accent.amber, size: 20),
          const SizedBox(width: Space.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lengkapi profilmu',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Accent.amber,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Tambahkan keahlian dan jam tersedia supaya skor lebih akurat.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: TextTone.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.sm),
          TextButton(onPressed: onEdit, child: const Text('Isi')),
        ],
      ),
    );
  }
}

class _QueueHero extends StatelessWidget {
  const _QueueHero({required this.matches});

  final List<Match> matches;

  @override
  Widget build(BuildContext context) {
    final top = matches.isEmpty ? null : matches.first;
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Accent.teal.withValues(alpha: 0.16),
            Accent.tealDeep.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: Radii.lgAll,
        border: Border.all(color: Accent.teal.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Accent.teal.withValues(alpha: 0.18),
                  borderRadius: Radii.pillAll,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, size: 12, color: Accent.teal),
                    SizedBox(width: 3),
                    Text(
                      'ANTREAN HARI INI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                        color: Accent.teal,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (matches.length > 1)
                Text(
                  '${matches.length} lain',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Accent.teal,
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          Text(
            top == null ? 'Belum ada lowongan hari ini.' : top.job.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (top != null) ...[
            const SizedBox(height: Space.xs),
            Text(
              '${top.job.company} · ${top.job.money.formatShort()} ${top.job.payPeriod}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: TextTone.secondary),
            ),
            const SizedBox(height: Space.md),
            Row(
              children: [
                ScoreBadge(match: top, compact: true),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    top.reasons.isEmpty
                        ? 'Lengkapi profil untuk alasan.'
                        : top.reasons.first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TextTone.muted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          for (final category in ['', ...categories])
            Padding(
              padding: const EdgeInsets.only(right: Space.sm),
              child: ChoiceChip(
                label: Text(category.isEmpty ? 'Semua' : category),
                selected: selected == category,
                showCheckmark: false,
                onSelected: (_) => onSelect(category),
                side: BorderSide(
                  color: selected == category ? Accent.teal : Surfaces.lineSoft,
                ),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected == category
                      ? Accent.teal
                      : TextTone.secondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmployerFeed extends StatelessWidget {
  const _EmployerFeed({
    required this.state,
    required this.onRefresh,
    required this.onOpenDetail,
  });

  final AppState state;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String id) onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final matches = state.employerJobs;
    final open = matches.where((m) => !m.job.filled).length;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Surfaces.base,
      body: RefreshIndicator(
        onRefresh: onRefresh,
        color: Accent.teal,
        backgroundColor: Surfaces.raised,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, 96),
          children: [
            Row(
              children: [
                Avatar(
                  initials: state.profile?.initials ?? '?',
                  photoUrl: state.profile?.photoUrl,
                  size: 42,
                  highlight: true,
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.profile?.displayName ?? 'Dasbor',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        '$open lowongan aktif · ${state.inbox.length} pelamar',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.lg),
            _EmployerStats(
              open: open,
              total: matches.length,
              applicants: state.inbox.length,
            ),
            const SizedBox(height: Space.xl),
            const SectionTitle(title: 'Lowongan kamu'),
            if (matches.isEmpty)
              const EmptyState(
                icon: Icons.post_add,
                title: 'Belum ada lowongan',
                body: 'Pasang lowongan pertama dari tab Pasang.',
              )
            else
              for (final match in matches) ...[
                JobCard(
                  match: match,
                  showScore: false,
                  onTap: () => onOpenDetail(match.job.id),
                ),
                const SizedBox(height: Space.md),
              ],
          ],
        ),
      ),
    );
  }
}

class _EmployerStats extends StatelessWidget {
  const _EmployerStats({
    required this.open,
    required this.total,
    required this.applicants,
  });

  final int open;
  final int total;
  final int applicants;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Stat(label: 'Aktif', value: '$open')),
        const SizedBox(width: Space.md),
        Expanded(child: _Stat(label: 'Total', value: '$total')),
        const SizedBox(width: Space.md),
        Expanded(child: _Stat(label: 'Pelamar', value: '$applicants')),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Accent.teal,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
