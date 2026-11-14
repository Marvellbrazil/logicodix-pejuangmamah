import 'package:flutter/material.dart';

import '../application/api_contracts.dart';
import '../application/api_failure.dart';
import '../domain/profile.dart';
import 'app_state.dart';
import 'app_theme.dart';
import 'profile_edit_screen.dart';
import 'ui_kit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _switching = false;

  Future<void> _switchRole(UserRole role) async {
    final profile = widget.state.profile;
    if (profile == null || profile.role == role || _switching) return;
    setState(() => _switching = true);
    try {
      await widget.state.updateProfile(ProfilePatch(role: role));
      await widget.state.refreshFeed();
      if (mounted) setState(() {});
    } on ApiFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Kamu perlu masuk lagi untuk melihat lamaran dan pesan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Accent.danger),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.state.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.state;
    final profile = state.profile;
    if (profile == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Surfaces.base,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Cover(profile: profile),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.lg,
              Space.lg,
              Space.lg,
              Space.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ProfileEditScreen(state: state),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        label: const Text('Edit profil'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.lg),
                Row(
                  children: [
                    Expanded(
                      child: _Counter(
                        value: '${state.stats.applications}',
                        label: 'Lamaran',
                      ),
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: _Counter(
                        value: '${state.stats.chats}',
                        label: 'Pesan',
                      ),
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: _Counter(
                        value: '${state.stats.jobs}',
                        label: 'Lowongan',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.lg),
                _Completeness(profile: profile, state: state),
                const SizedBox(height: Space.xl),
                if (profile.bio.isNotEmpty) ...[
                  const SectionTitle(title: 'Tentang'),
                  Panel(
                    child: Text(profile.bio, style: theme.textTheme.bodyLarge),
                  ),
                  const SizedBox(height: Space.xl),
                ],
                const SectionTitle(title: 'Keahlian'),
                Panel(
                  child: profile.skills.isEmpty
                      ? Text(
                          'Belum ada keahlian. Tambahkan supaya skor kecocokan akurat.',
                          style: theme.textTheme.bodyMedium,
                        )
                      : Wrap(
                          spacing: Space.sm,
                          runSpacing: Space.sm,
                          children: [
                            for (final skill in profile.skills)
                              Tag(label: skill, tone: TagTone.teal),
                          ],
                        ),
                ),
                const SizedBox(height: Space.xl),
                const SectionTitle(title: 'Preferensi kerja'),
                Panel(
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.place_outlined,
                        label: 'Kecamatan',
                        value: profile.district.isEmpty
                            ? 'Belum diisi'
                            : profile.district,
                      ),
                      _DetailRow(
                        icon: Icons.straighten,
                        label: 'Jarak maksimal',
                        value:
                            '${profile.maxDistanceKm.toStringAsFixed(1).replaceAll('.', ',')} km',
                      ),
                      _DetailRow(
                        icon: Icons.payments_outlined,
                        label: 'Upah minimum',
                        value: _rupiah(profile.minPay),
                      ),
                      _DetailRow(
                        icon: Icons.schedule,
                        label: 'Jam tersedia',
                        value:
                            '${profile.startHour.toString().padLeft(2, '0')}:00 – '
                            '${profile.endHour.toString().padLeft(2, '0')}:00',
                      ),
                    ],
                  ),
                ),
                if (profile.experience.isNotEmpty) ...[
                  const SizedBox(height: Space.xl),
                  const SectionTitle(title: 'Pengalaman'),
                  for (final item in profile.experience) ...[
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
                const SizedBox(height: Space.xl),
                const SectionTitle(title: 'Peran akun'),
                SegmentedButton<UserRole>(
                  segments: const [
                    ButtonSegment(
                      value: UserRole.worker,
                      icon: Icon(Icons.person_search_outlined, size: 16),
                      label: Text('Cari kerja'),
                    ),
                    ButtonSegment(
                      value: UserRole.employer,
                      icon: Icon(Icons.storefront_outlined, size: 16),
                      label: Text('Butuh pekerja'),
                    ),
                  ],
                  selected: {profile.role},
                  showSelectedIcon: false,
                  onSelectionChanged: _switching
                      ? null
                      : (value) => _switchRole(value.first),
                ),
                const SizedBox(height: Space.xl),
                const SectionTitle(title: 'Akun'),
                Panel(
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.mail_outline,
                        label: 'Email',
                        value: profile.email,
                      ),
                      _DetailRow(
                        icon: Icons.phonelink_lock_outlined,
                        label: 'Metode masuk',
                        value: profile.hasGoogle && profile.hasPassword
                            ? 'Google dan kata sandi'
                            : profile.hasGoogle
                            ? 'Google'
                            : 'Kata sandi',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.lg),
                OutlinedButton.icon(
                  onPressed: state.busy ? null : _signOut,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Accent.danger,
                    side: BorderSide(color: Accent.danger.withValues(alpha: 0.4)),
                  ),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Keluar'),
                ),
                const SizedBox(height: Space.lg),
                Text(
                  'Kerjaqueue 2.0 · data profil, lamaran, dan pesan tersimpan di server.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _rupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return 'Rp $buffer';
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 108,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Accent.tealDeep, Color(0xFF0A3A44), Surfaces.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.lg, 70, Space.lg, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Surfaces.base, width: 3),
                ),
                child: Avatar(
                  initials: profile.initials,
                  photoUrl: profile.photoUrl,
                  size: 78,
                  highlight: true,
                  radius: 18,
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              profile.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          if (profile.isEmployer) ...[
                            const SizedBox(width: Space.xs + 2),
                            const Icon(
                              Icons.verified,
                              size: 15,
                              color: Accent.teal,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '“${profile.displayName}”',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Accent.teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: Space.lg,
          right: Space.lg,
          top: 172,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.headline.isEmpty
                    ? '${profile.role.label} · Kerjaqueue'
                    : profile.headline,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 2),
              Text(
                [
                  if (profile.district.isNotEmpty) profile.district,
                  '${profile.role.label} · Kerjaqueue',
                ].join(' · '),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 208),
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.md,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Accent.teal,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _Completeness extends StatelessWidget {
  const _Completeness({required this.profile, required this.state});

  final Profile profile;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    if (profile.isProfileComplete) return const SizedBox.shrink();
    final total = profile.isEmployer ? 60 : 100;
    final percent = profile.completeness.clamp(0, total);
    return Panel(
      color: Accent.amberWash,
      borderColor: Accent.amber.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, size: 17, color: Accent.amber),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
            'Profil $percent/$total lengkap',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Accent.amber,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProfileEditScreen(state: state),
                  ),
                ),
                child: const Text('Lengkapi'),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: percent / total,
              minHeight: 5,
              backgroundColor: Surfaces.overlay,
              valueColor: const AlwaysStoppedAnimation(Accent.amber),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: TextTone.muted),
          const SizedBox(width: Space.md),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: Space.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}
