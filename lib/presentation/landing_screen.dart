import 'package:flutter/material.dart';

import '../domain/profile.dart';
import 'app_theme.dart';
import 'ui_kit.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({
    super.key,
    required this.onLogin,
    required this.onRegister,
    required this.onGoogle,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final Future<void> Function(UserRole role) onGoogle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Surfaces.base,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                Space.xl,
                Space.lg,
                Space.xl,
                Space.xxl,
              ),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      const BrandMark(size: 40),
                      const SizedBox(width: Space.md),
                      Text(
                        'Kerjaqueue',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton(onPressed: onLogin, child: const Text('Masuk')),
                    ],
                  ),
                  const SizedBox(height: Space.xxxl),
                  Text(
                    'Kesempatan kerja\nada di dekatmu.',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: 38,
                      height: 1.05,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  Text(
                    'Pekerjaan harian dari UMKM di sekitarmu, diurutkan dari '
                    'yang paling butuh orang hari ini.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: TextTone.secondary,
                    ),
                  ),
                  const SizedBox(height: Space.xl),
                  const _SampleTicket(),
                  const SizedBox(height: Space.xl),
                  FilledButton(
                    onPressed: onRegister,
                    child: const Text('Buat akun gratis'),
                  ),
                  if (googleSignInEnabled) ...[
                    const SizedBox(height: Space.sm),
                    OutlinedButton.icon(
                      onPressed: () => onGoogle(UserRole.worker),
                      icon: const GoogleMark(size: 18),
                      label: const Text('Lanjutkan dengan Google'),
                    ),
                  ],
                  const SizedBox(height: Space.xs),
                  Center(
                    child: TextButton(
                      onPressed: onLogin,
                      child: const Text('Sudah punya akun? Masuk'),
                    ),
                  ),
                  const SizedBox(height: Space.xxl),
                  const TicketDivider(),
                  const SizedBox(height: Space.xl),
                  const _RoleLine(
                    role: 'Cari kerja',
                    body:
                        'Lihat skor kecocokan beserta alasannya, lamar, lalu '
                        'langsung ngobrol dengan pemilik usaha.',
                  ),
                  const SizedBox(height: Space.lg),
                  const _RoleLine(
                    role: 'Butuh pekerja',
                    body:
                        'Pasang shift singkat, lihat siapa yang melamar, dan '
                        'tentukan statusnya dari satu layar.',
                  ),
                  const SizedBox(height: Space.xxl),
                  Center(
                    child: Text(
                      'Kerjaqueue · Kerja dekat, peluang terbuka.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
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
}

/// Contoh karcis lowongan: memperlihatkan isi aplikasi sebelum pengguna daftar.
/// Datanya contoh dan diberi label, bukan lowongan sungguhan.
class _SampleTicket extends StatelessWidget {
  const _SampleTicket();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label:
          'Contoh lowongan: Barista shift pagi di Kopi Jempol, Rungkut, '
          'seratus dua puluh ribu rupiah per hari, skor kecocokan 96.',
      child: ExcludeSemantics(
        child: Container(
          decoration: BoxDecoration(
            color: Surfaces.raised,
            borderRadius: Radii.lgAll,
            border: Border.all(color: Surfaces.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  Space.lg,
                  Space.lg,
                  Space.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contoh lowongan', style: theme.textTheme.bodySmall),
                    const SizedBox(height: Space.xs),
                    Text(
                      'Barista shift pagi',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kopi Jempol · Rungkut',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: Space.md),
                    const Wrap(
                      spacing: Space.sm,
                      runSpacing: Space.sm,
                      children: [
                        Tag(label: 'Rp120rb per hari', tone: TagTone.teal),
                        Tag(label: '07.00 sampai 12.00'),
                        Tag(label: 'Hari ini', tone: TagTone.amber),
                      ],
                    ),
                  ],
                ),
              ),
              const TicketDivider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  Space.md,
                  Space.lg,
                  Space.lg,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '96',
                      style: TextStyle(
                        fontSize: 40,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                        color: Accent.teal,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Skor kecocokan',
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            'Keahlian Barista dibutuhkan, jarak 1,2 km.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleLine extends StatelessWidget {
  const _RoleLine({required this.role, required this.body});

  final String role;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(role, style: theme.textTheme.titleMedium),
        const SizedBox(height: Space.xs),
        Text(body, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
