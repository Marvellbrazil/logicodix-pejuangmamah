import 'dart:async';

import 'package:flutter/material.dart';

import '../application/api_failure.dart';
import '../domain/job.dart';
import '../domain/profile.dart';
import 'app_state.dart';
import 'app_theme.dart';
import 'job_detail_screen.dart';
import 'job_widgets.dart';
import 'person_screen.dart';
import 'ui_kit.dart';
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.state});

  final AppState state;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  bool _searchingPeople = false;
  List<Job> _jobs = const [];
  List<PeopleCard> _people = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQuery(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _run);
  }

  Future<void> _run() async {
    final query = _controller.text.trim();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_searchingPeople) {
        final people = await widget.state.searchPeople(q: query);
        if (mounted) setState(() => _people = people);
      } else {
        final jobs = await widget.state.searchJobs(query);
        if (mounted) setState(() => _jobs = jobs);
      }
    } on ApiFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Surfaces.base,
      appBar: AppBar(
        titleSpacing: Space.lg,
        title: Text(_searchingPeople ? 'Cari orang' : 'Cari lowongan'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, 0),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  onChanged: _onQuery,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _run(),
                  decoration: InputDecoration(
                    hintText: _searchingPeople
                        ? 'Nama, headline, atau kecamatan'
                        : 'Barista, kurir, Rungkut…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Bersihkan',
                            onPressed: () {
                              _controller.clear();
                              _run();
                            },
                            icon: const Icon(Icons.close, size: 18),
                          ),
                  ),
                ),
                const SizedBox(height: Space.md),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            label: Text('Lowongan'),
                            icon: Icon(Icons.work_outline, size: 16),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text('Orang'),
                            icon: Icon(Icons.people_outline, size: 16),
                          ),
                        ],
                        selected: {_searchingPeople},
                        showSelectedIcon: false,
                        onSelectionChanged: (value) {
                          setState(() => _searchingPeople = value.first);
                          _run();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          Expanded(
            child: _loading
                ? const LoadingLine()
                : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(Space.lg),
                    child: ErrorBanner(message: _error!, onRetry: _run),
                  )
                : _searchingPeople
                ? _peopleList()
                : _jobsList(),
          ),
        ],
      ),
    );
  }

  Widget _jobsList() {
    if (_jobs.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'Tidak ada hasil',
        body: 'Coba kata kunci lain seperti nama keahlian atau kecamatan.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.xl),
      itemCount: _jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: Space.md),
      itemBuilder: (context, index) {
        final job = _jobs[index];
        return Panel(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  JobDetailScreen(state: widget.state, jobId: job.id),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(job.title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 3),
              Text(
                '${job.company} · ${job.district} · ${distanceLabel(job.distanceKm)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: Space.sm),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  Tag(label: '${job.money.formatShort()} ${job.payPeriod}', tone: TagTone.teal),
                  UrgencyTag(urgency: job.urgency),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _peopleList() {
    if (_people.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'Belum ada orang',
        body: 'Coba cari nama atau kecamatan lain.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.xl),
      itemCount: _people.length,
      separatorBuilder: (_, _) => const SizedBox(height: Space.md),
      itemBuilder: (context, index) {
        final card = _people[index];
        final person = card.profile;
        return Panel(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PersonScreen(
                state: widget.state,
                personId: person.id,
              ),
            ),
          ),
          child: Row(
            children: [
              Avatar(initials: person.initials, photoUrl: person.photoUrl),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.fullName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      person.headline.isEmpty
                          ? person.district
                          : person.headline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (card.openJobs > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${card.openJobs} lowongan aktif',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Accent.teal,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        );
      },
    );
  }
}
