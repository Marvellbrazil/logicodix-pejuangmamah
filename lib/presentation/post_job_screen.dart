import 'package:flutter/material.dart';

import '../application/api_contracts.dart';
import '../application/api_failure.dart';
import '../domain/job.dart';
import 'app_state.dart';
import 'app_theme.dart';
import 'ui_kit.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key, required this.state});

  final AppState state;

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _company = TextEditingController();
  final _category = TextEditingController();
  final _description = TextEditingController();
  final _pay = TextEditingController(text: '100000');
  final _district = TextEditingController();
  final _contact = TextEditingController();
  final _skillInput = TextEditingController();

  final List<String> _skills = [];
  JobUrgency _urgency = JobUrgency.today;
  RangeValues _hours = const RangeValues(8, 16);
  double _distance = 2;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = widget.state.profile;
    _company.text = profile?.headline.isEmpty == false
        ? profile!.fullName
        : profile?.fullName ?? '';
    _district.text = profile?.district ?? '';
  }

  @override
  void dispose() {
    _title.dispose();
    _company.dispose();
    _category.dispose();
    _description.dispose();
    _pay.dispose();
    _district.dispose();
    _contact.dispose();
    _skillInput.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.state.postJob(
        NewJob(
          title: _title.text.trim(),
          company: _company.text.trim(),
          category: _category.text.trim(),
          description: _description.text.trim(),
          pay: int.tryParse(_pay.text) ?? 0,
          payPeriod: 'per hari',
          district: _district.text.trim(),
          distanceKm: _distance,
          startHour: _hours.start.round(),
          endHour: _hours.end.round(),
          urgency: _urgency,
          skills: _skills,
          contact: _contact.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lowongan berhasil dipasang.')),
      );
    } on ApiFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = _hours.start.round();
    final end = _hours.end.round();

    return Scaffold(
      backgroundColor: Surfaces.base,
      appBar: AppBar(title: const Text('Pasang lowongan')),
      body: Form(
        key: _formKey,
        child: ListView(
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
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Judul lowongan',
                hintText: 'Barista shift pagi',
              ),
              validator: (value) => (value?.trim().length ?? 0) < 3
                  ? 'Judul minimal 3 karakter.'
                  : null,
            ),
            const SizedBox(height: Space.md),
            TextFormField(
              controller: _company,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama usaha',
                hintText: 'Kopi Jempol',
              ),
              validator: (value) => (value?.trim().length ?? 0) < 2
                  ? 'Nama usaha wajib diisi.'
                  : null,
            ),
            const SizedBox(height: Space.md),
            TextFormField(
              controller: _category,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                hintText: 'Kuliner',
              ),
              validator: (value) => (value?.trim().length ?? 0) < 2
                  ? 'Kategori wajib diisi.'
                  : null,
            ),
            const SizedBox(height: Space.md),
            TextFormField(
              controller: _district,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Kecamatan',
                hintText: 'Rungkut',
              ),
              validator: (value) => (value?.trim().length ?? 0) < 2
                  ? 'Kecamatan wajib diisi.'
                  : null,
            ),
            const SizedBox(height: Space.md),
            TextFormField(
              controller: _description,
              maxLines: 4,
              maxLength: 1200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Deskripsi pekerjaan',
                hintText: 'Tugas, perlengkapan, dan hal penting lain.',
              ),
              validator: (value) => (value?.trim().length ?? 0) < 10
                  ? 'Deskripsi minimal 10 karakter.'
                  : null,
            ),
            TextFormField(
              controller: _pay,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Upah per hari (Rp)',
                hintText: '100000',
              ),
              validator: (value) => (int.tryParse(value ?? '') ?? 0) <= 0
                  ? 'Upah harus lebih dari nol.'
                  : null,
            ),
            const SizedBox(height: Space.lg),
            Text('Urgensi', style: theme.textTheme.labelMedium),
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.sm,
              children: [
                for (final urgency in JobUrgency.values)
                  ChoiceChip(
                    label: Text(urgency.label),
                    selected: _urgency == urgency,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _urgency = urgency),
                    side: BorderSide(
                      color: _urgency == urgency ? Accent.teal : Surfaces.lineSoft,
                    ),
                    labelStyle: TextStyle(
                      color: _urgency == urgency
                          ? Accent.teal
                          : TextTone.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Space.lg),
            Row(
              children: [
                Expanded(
                  child: Text('Jam kerja', style: theme.textTheme.bodyLarge),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Jarak dari pusat',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                Text(
                  '${_distance.toStringAsFixed(1).replaceAll('.', ',')} km',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Accent.teal,
                  ),
                ),
              ],
            ),
            Slider(
              value: _distance,
              min: 0.5,
              max: 20,
              divisions: 39,
              label: '${_distance.toStringAsFixed(1)} km',
              onChanged: (value) => setState(() => _distance = value),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _skillInput,
              onSubmitted: (_) => _addSkill(),
              decoration: InputDecoration(
                labelText: 'Keahlian dibutuhkan',
                hintText: 'Barista',
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
            const SizedBox(height: Space.md),
            TextField(
              controller: _contact,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'WhatsApp untuk kontak',
                hintText: '62812xxxxxxx',
              ),
            ),
            const SizedBox(height: Space.xl),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Accent.tealInk,
                      ),
                    )
                  : const Text('Pasang lowongan'),
            ),
          ],
        ),
      ),
    );
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
