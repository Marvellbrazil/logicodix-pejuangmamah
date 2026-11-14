import 'package:flutter/material.dart';

import '../application/api_contracts.dart';
import '../application/api_failure.dart';
import '../domain/profile.dart';
import 'app_state.dart';
import 'app_theme.dart';
import 'ui_kit.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.state});

  final AppState state;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _steps = 3;

  int _step = 0;
  bool _saving = false;
  String? _error;

  late final TextEditingController _fullName;
  late final TextEditingController _displayName;
  late final TextEditingController _headline;
  late final TextEditingController _district;
  late final TextEditingController _skillInput;

  final List<String> _skills = [];
  double _maxDistance = 5;
  int _minPay = 50000;
  RangeValues _hours = const RangeValues(8, 17);

  Profile get _profile => widget.state.profile!;

  @override
  void initState() {
    super.initState();
    final profile = _profile;
    _fullName = TextEditingController(text: profile.fullName);
    _displayName = TextEditingController(text: profile.displayName);
    _headline = TextEditingController(text: profile.headline);
    _district = TextEditingController(text: profile.district);
    _skillInput = TextEditingController();
    _skills.addAll(profile.skills);
    _maxDistance = profile.maxDistanceKm.clamp(1, 30);
    _minPay = profile.minPay;
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
    _skillInput.dispose();
    super.dispose();
  }

  bool get _employer => _profile.isEmployer;

  void _addSkill([String? raw]) {
    final value = (raw ?? _skillInput.text).trim();
    if (value.isEmpty) return;
    if (_skills.any((skill) => skill.toLowerCase() == value.toLowerCase())) {
      _skillInput.clear();
      return;
    }
    setState(() {
      _skills.add(value);
      _skillInput.clear();
    });
  }

  void _next() {
    setState(() => _error = null);
    if (_step == 0) {
      if (_fullName.text.trim().length < 2) {
        setState(() => _error = 'Nama lengkap wajib diisi.');
        return;
      }
      if (_displayName.text.trim().isEmpty) {
        setState(() => _error = 'Nama panggilan wajib diisi.');
        return;
      }
    }
    if (_step == 1 && !_employer) {
      if (_district.text.trim().isEmpty) {
        setState(() => _error = 'Kecamatan wajib diisi.');
        return;
      }
      if (_skills.isEmpty) {
        setState(() => _error = 'Tambahkan minimal satu keahlian.');
        return;
      }
    }
    if (_step < _steps - 1) {
      setState(() => _step += 1);
      return;
    }
    _save();
  }

  Future<void> _save() async {
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
          skills: _skills,
          maxDistanceKm: _maxDistance,
          minPay: _minPay,
          startHour: _hours.start.round(),
          endHour: _hours.end.round(),
        ),
      );
    } on ApiFailure catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.xl,
                Space.lg,
                Space.xl,
                Space.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < _steps; i++) ...[
                        Expanded(
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: i <= _step ? Accent.teal : Surfaces.line,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        if (i < _steps - 1) const SizedBox(width: Space.xs),
                      ],
                    ],
                  ),
                  const SizedBox(height: Space.lg),
                  Text(
                    'Langkah ${_step + 1} dari $_steps',
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    switch (_step) {
                      0 => 'Kenalkan dirimu',
                      1 => _employer ? 'Tentang usahamu' : 'Keahlian & wilayah',
                      _ => _employer ? 'Preferensi kerja' : 'Ketersediaanmu',
                    },
                    style: theme.textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Space.xl,
                  0,
                  Space.xl,
                  Space.xl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null) ...[
                        ErrorBanner(message: _error!),
                        const SizedBox(height: Space.lg),
                      ],
                      switch (_step) {
                        0 => _identityStep(),
                        1 => _employer ? _businessStep() : _skillsStep(),
                        _ => _availabilityStep(),
                      },
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.xl,
                Space.sm,
                Space.xl,
                Space.lg,
              ),
              child: Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => setState(() => _step -= 1),
                      child: const Text('Kembali'),
                    ),
                  const Spacer(),
                  SizedBox(
                    width: 170,
                    child: FilledButton(
                      onPressed: _saving ? null : _next,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Accent.tealInk,
                              ),
                            )
                          : Text(
                              _step == _steps - 1
                                  ? 'Selesai'
                                  : 'Lanjut',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _identityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Avatar(
            initials: _profile.initials,
            photoUrl: _profile.photoUrl,
            size: 76,
            highlight: true,
            radius: 26,
          ),
        ),
        const SizedBox(height: Space.xl),
        TextField(
          controller: _fullName,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama lengkap',
            hintText: 'Rina Pratiwi',
          ),
        ),
        const SizedBox(height: Space.md),
        TextField(
          controller: _displayName,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama panggilan',
            hintText: 'Rina',
            helperText: 'Ini yang dilihat pemberi kerja saat kamu melamar.',
          ),
        ),
        const SizedBox(height: Space.md),
        TextField(
          controller: _headline,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 120,
          decoration: const InputDecoration(
            labelText: 'Headline',
            hintText: 'Barista & pelayanan · Rungkut, Surabaya',
          ),
        ),
      ],
    );
  }

  Widget _businessStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _district,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Kecamatan usahamu',
            hintText: 'Rungkut',
          ),
        ),
        const SizedBox(height: Space.md),
        TextField(
          controller: _headline,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 120,
          decoration: const InputDecoration(
            labelText: 'Tentang usaha',
            hintText: 'Dua gerai kopi kecil di Surabaya timur',
          ),
        ),
        const SizedBox(height: Space.sm),
        const Text(
          'Lowongan yang kamu pasang akan memakai nama usahamu.',
          style: TextStyle(fontSize: 12.5, color: TextTone.muted),
        ),
      ],
    );
  }

  Widget _skillsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _district,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Kecamatan',
            hintText: 'Rungkut',
          ),
        ),
        const SizedBox(height: Space.lg),
        Text(
          'Keahlian',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: Space.sm),
        TextField(
          controller: _skillInput,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _addSkill(),
          decoration: InputDecoration(
            hintText: 'Tulis keahlian, lalu tekan tambah',
            suffixIcon: IconButton(
              tooltip: 'Tambah keahlian',
              onPressed: _addSkill,
              icon: const Icon(Icons.add, size: 20),
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
        const SizedBox(height: Space.lg),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final suggestion in const [
              'Barista',
              'Kasir',
              'Pelayanan',
              'Masak',
              'Kebersihan',
              'Motor',
              'Jahit',
              'Administrasi',
            ])
              if (!_skills.contains(suggestion))
                ActionChip(
                  label: Text(suggestion),
                  onPressed: () => _addSkill(suggestion),
                ),
          ],
        ),
      ],
    );
  }

  Widget _availabilityStep() {
    final start = _hours.start.round();
    final end = _hours.end.round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_employer) ...[
          _SliderHeader(
            label: 'Jarak maksimal',
            value: '${_maxDistance.toStringAsFixed(1).replaceAll('.', ',')} km',
          ),
          Slider(
            value: _maxDistance,
            min: 1,
            max: 30,
            divisions: 29,
            label: '${_maxDistance.round()} km',
            onChanged: (value) => setState(() => _maxDistance = value),
          ),
          const SizedBox(height: Space.md),
          _SliderHeader(
            label: 'Upah minimum per hari',
            value: formatRupiah(_minPay),
          ),
          Slider(
            value: _minPay.toDouble(),
            min: 0,
            max: 500000,
            divisions: 50,
            label: formatRupiah(_minPay),
            onChanged: (value) =>
                setState(() => _minPay = (value / 5000).round() * 5000),
          ),
          const SizedBox(height: Space.md),
        ],
        _SliderHeader(
          label: 'Jam tersedia',
          value: '${_two(start)}:00 – ${_two(end)}:00',
        ),
        RangeSlider(
          values: _hours,
          min: 4,
          max: 24,
          divisions: 20,
          labels: RangeLabels('${_two(start)}:00', '${_two(end)}:00'),
          onChanged: (values) => setState(() => _hours = values),
        ),
        const SizedBox(height: Space.lg),
        Panel(
          color: Accent.tealWash,
          borderColor: Accent.teal.withValues(alpha: 0.3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: Accent.teal),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  _employer
                      ? 'Kamu bisa mengubah ini kapan saja dari Profil.'
                      : 'Data ini dipakai mesin skor untuk memeringkat lowongan; '
                            'kamu bisa mengubahnya kapan saja dari Profil.',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Accent.teal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  static String formatRupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return 'Rp $buffer';
  }
}

class _SliderHeader extends StatelessWidget {
  const _SliderHeader({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(color: Accent.teal),
        ),
      ],
    );
  }
}
