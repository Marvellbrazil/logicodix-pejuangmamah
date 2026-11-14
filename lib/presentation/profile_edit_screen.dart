import 'package:flutter/material.dart';

import '../application/api_contracts.dart';
import '../application/api_failure.dart';
import '../domain/profile.dart';
import 'app_state.dart';
import 'app_theme.dart';
import 'ui_kit.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final TextEditingController _fullName;
  late final TextEditingController _displayName;
  late final TextEditingController _headline;
  late final TextEditingController _district;
  late final TextEditingController _bio;
  late final TextEditingController _phone;
  late final TextEditingController _skillInput;
  late final TextEditingController _minPay;

  final List<String> _skills = [];
  final List<Experience> _experience = [];
  double _maxDistance = 5;
  RangeValues _hours = const RangeValues(8, 17);
  bool _saving = false;
  String? _error;

  Profile get _profile => widget.state.profile!;

  @override
  void initState() {
    super.initState();
    final profile = _profile;
    _fullName = TextEditingController(text: profile.fullName);
    _displayName = TextEditingController(text: profile.displayName);
    _headline = TextEditingController(text: profile.headline);
    _district = TextEditingController(text: profile.district);
    _bio = TextEditingController(text: profile.bio);
    _phone = TextEditingController(text: profile.phone);
    _skillInput = TextEditingController();
    _minPay = TextEditingController(text: profile.minPay.toString());
    _skills.addAll(profile.skills);
    _experience.addAll(profile.experience);
    _maxDistance = profile.maxDistanceKm.clamp(1, 30);
    _hours = RangeValues(
      profile.startHour.toDouble(),
      profile.endHour.toDouble(),
    );
  }

  @override
  void dispose() {
    _fullName.dispose();
    _displayName.dispose();
    _headline.dispose();
    _district.dispose();
    _bio.dispose();
    _phone.dispose();
    _skillInput.dispose();
    _minPay.dispose();
    super.dispose();
  }

  void _addSkill([String? raw]) {
    final value = (raw ?? _skillInput.text).trim();
    if (value.isEmpty) return;
    setState(() {
      if (!_skills.any((s) => s.toLowerCase() == value.toLowerCase())) {
        _skills.add(value);
      }
      _skillInput.clear();
    });
  }

  Future<void> _addExperience() async {
    final result = await showModalBottomSheet<Experience>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ExperienceSheet(),
    );
    if (result != null) setState(() => _experience.add(result));
  }

  Future<void> _save() async {
    if (_fullName.text.trim().length < 2) {
      setState(() => _error = 'Nama lengkap wajib diisi.');
      return;
    }
    if (_displayName.text.trim().isEmpty) {
      setState(() => _error = 'Nama panggilan wajib diisi.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.state.updateProfile(
        ProfilePatch(
          fullName: _fullName.text.trim(),
          displayName: _displayName.text.trim(),
          headline: _headline.text.trim(),
          district: _district.text.trim(),
          bio: _bio.text.trim(),
          phone: _phone.text.trim(),
          skills: _skills,
          experience: _experience,
          maxDistanceKm: _maxDistance,
          minPay: int.tryParse(_minPay.text) ?? 0,
          startHour: _hours.start.round(),
          endHour: _hours.end.round(),
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } on ApiFailure catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = _profile;
    final start = _hours.start.round();
    final end = _hours.end.round();

    return Scaffold(
      backgroundColor: Surfaces.base,
      appBar: AppBar(
        title: const Text('Edit profil'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.sm,
          Space.lg,
          Space.xxl,
        ),
        children: [
          if (_error != null) ...[
            ErrorBanner(message: _error!),
            const SizedBox(height: Space.lg),
          ],
          Center(
            child: Avatar(
              initials: profile.initials,
              photoUrl: profile.photoUrl,
              size: 74,
              highlight: true,
              radius: 24,
            ),
          ),
          const SizedBox(height: Space.xl),
          TextField(
            controller: _fullName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nama lengkap'),
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: _displayName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama panggilan',
              helperText: 'Ditampilkan di kartu lamaranmu.',
            ),
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: _headline,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'Headline'),
          ),
          TextField(
            controller: _district,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: profile.isEmployer
                  ? 'Kecamatan usaha'
                  : 'Kecamatan',
            ),
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: _bio,
            maxLines: 4,
            maxLength: 800,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Tentang',
              hintText:
                  'Ceritakan singkat dirimu, pengalaman, atau usaha yang kamu jalankan.',
            ),
          ),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Nomor WhatsApp',
              hintText: '62812xxxxxxx',
              helperText: 'Hanya dipakai untuk kontak setelah lamaran diterima.',
            ),
          ),
          const SizedBox(height: Space.xl),
          const SectionTitle(title: 'Keahlian'),
          TextField(
            controller: _skillInput,
            onSubmitted: (_) => _addSkill(),
            decoration: InputDecoration(
              hintText: 'Tambah keahlian',
              suffixIcon: IconButton(
                onPressed: _addSkill,
                icon: const Icon(Icons.add, size: 20),
                tooltip: 'Tambah',
              ),
            ),
          ),
          if (_skills.isNotEmpty) ...[
            const SizedBox(height: Space.md),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                for (final skill in _skills)
                  InputChip(
                    label: Text(skill),
                    onDeleted: () => setState(() => _skills.remove(skill)),
                    deleteIconColor: TextTone.muted,
                  ),
              ],
            ),
          ],
          const SizedBox(height: Space.xl),
          SectionTitle(
            title: 'Pengalaman',
            action: 'Tambah',
            onAction: _addExperience,
          ),
          if (_experience.isEmpty)
            Text(
              'Belum ada pengalaman kerja. Tambahkan satu supaya profil lebih meyakinkan.',
              style: theme.textTheme.bodyMedium,
            )
          else
            for (var i = 0; i < _experience.length; i++) ...[
              Panel(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _experience[i].title,
                            style: theme.textTheme.titleSmall,
                          ),
                          if (_experience[i].company.isNotEmpty ||
                              _experience[i].period.isNotEmpty)
                            Text(
                              [
                                _experience[i].company,
                                _experience[i].period,
                              ].where((p) => p.isNotEmpty).join(' · '),
                              style: theme.textTheme.bodySmall,
                            ),
                          if (_experience[i].detail.isNotEmpty) ...[
                            const SizedBox(height: Space.xs + 2),
                            Text(
                              _experience[i].detail,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Hapus',
                      onPressed: () => setState(() => _experience.removeAt(i)),
                      icon: const Icon(Icons.close, size: 17),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.sm),
            ],
          if (!profile.isEmployer) ...[
            const SizedBox(height: Space.xl),
            const SectionTitle(title: 'Preferensi kerja'),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Jarak maksimal',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                Text(
                  '${_maxDistance.toStringAsFixed(1).replaceAll('.', ',')} km',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Accent.teal,
                  ),
                ),
              ],
            ),
            Slider(
              value: _maxDistance,
              min: 1,
              max: 30,
              divisions: 29,
              label: '${_maxDistance.round()} km',
              onChanged: (value) => setState(() => _maxDistance = value),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _minPay,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Upah minimum per hari (Rp)',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.md),
            Row(
              children: [
                Expanded(
                  child: Text('Jam tersedia', style: theme.textTheme.bodyLarge),
                ),
                Text(
                  '${_two(start)}:00 – ${_two(end)}:00',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Accent.teal,
                  ),
                ),
              ],
            ),
            RangeSlider(
              values: _hours,
              min: 4,
              max: 24,
              divisions: 20,
              labels: RangeLabels('${_two(start)}:00', '${_two(end)}:00'),
              onChanged: (values) => setState(() => _hours = values),
            ),
          ],
          const SizedBox(height: Space.xl),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Accent.tealInk,
                    ),
                  )
                : const Text('Simpan perubahan'),
          ),
        ],
      ),
    );
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

class _ExperienceSheet extends StatefulWidget {
  const _ExperienceSheet();

  @override
  State<_ExperienceSheet> createState() => _ExperienceSheetState();
}

class _ExperienceSheetState extends State<_ExperienceSheet> {
  final _title = TextEditingController();
  final _company = TextEditingController();
  final _period = TextEditingController();
  final _detail = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _company.dispose();
    _period.dispose();
    _detail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: Space.xl,
        right: Space.xl,
        top: Space.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + Space.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Surfaces.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: Space.lg),
          Text(
            'Tambah pengalaman',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: Space.lg),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Posisi',
              hintText: 'Barista',
            ),
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: _company,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Tempat',
              hintText: 'Kopi Jempol',
            ),
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: _period,
            decoration: const InputDecoration(
              labelText: 'Periode',
              hintText: '2024 – sekarang',
            ),
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: _detail,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Rincian',
              hintText: 'Buka gerai pagi, seduh kopi manual, layani pembeli.',
            ),
          ),
          const SizedBox(height: Space.xl),
          FilledButton(
            onPressed: () {
              if (_title.text.trim().isEmpty) return;
              Navigator.of(context).pop(
                Experience(
                  title: _title.text.trim(),
                  company: _company.text.trim(),
                  period: _period.text.trim(),
                  detail: _detail.text.trim(),
                ),
              );
            },
            child: const Text('Tambahkan'),
          ),
        ],
      ),
    );
  }
}
