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
                Space.lg,
                Space.lg,
                Space.lg,
                Space.xxl,
              ),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Accent.teal, Accent.tealDeep],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: Radii.mdAll,
                        ),
                        child: const Icon(
                          Icons.work_history_outlined,
                          size: 22,
                          color: Accent.tealInk,
                        ),
                      ),
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
                  const SizedBox(height: Space.xxl),
                  Container(
                    padding: const EdgeInsets.all(Space.xl),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Accent.teal.withValues(alpha: 0.16),
                          Accent.tealDeep.withValues(alpha: 0.07),
                          Surfaces.raised,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: Radii.xlAll,
                      border: Border.all(
                        color: Accent.teal.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Tag(
                          label: 'KERJA LOKAL · PELUANG NYATA',
                          tone: TagTone.teal,
                          icon: Icons.bolt,
                        ),
                        const SizedBox(height: Space.lg),
                        Text(
                          'Kesempatan kerja\nada di dekatmu.',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontSize: 34,
                            height: 1.1,
                            letterSpacing: -1.1,
                          ),
                        ),
                        const SizedBox(height: Space.md),
                        Text(
                          'Temukan pekerjaan harian dari UMKM sekitar. '
                          'Lihat kecocokan, kirim lamaran, dan ngobrol langsung.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: TextTone.secondary,
                          ),
                        ),
                        const SizedBox(height: Space.xl),
                        FilledButton.icon(
                          onPressed: onRegister,
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: const Text('Buat akun gratis'),
                        ),
                        const SizedBox(height: Space.sm),
                        OutlinedButton.icon(
                          onPressed: () => onGoogle(UserRole.worker),
                          icon: const GoogleMark(size: 18),
                          label: const Text('Lanjutkan dengan Google'),
                        ),
                        const SizedBox(height: Space.md),
                        Center(
                          child: TextButton(
                            onPressed: onLogin,
                            child: const Text('Sudah punya akun? Masuk'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.xxl),
                  Text(
                    'Dari profil sampai percakapan,\nsatu tempat untuk mulai kerja.',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: Space.md),
                  Text(
                    'Profil profesional sederhana membantu UMKM mengenalmu; '
                    'kamu juga bisa melihat bagaimana pengalamanmu cocok dengan '
                    'kebutuhan mereka.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: Space.lg),
                  const _FeatureRow(
                    number: '01',
                    icon: Icons.tune_rounded,
                    title: 'Kecocokan yang transparan',
                    body: 'Skor keahlian, upah, jarak, dan jadwal beserta alasannya.',
                  ),
                  const SizedBox(height: Space.sm),
                  const _FeatureRow(
                    number: '02',
                    icon: Icons.mark_chat_unread_outlined,
                    title: 'Lamaran, lanjut ngobrol',
                    body: 'Percakapan langsung terbuka saat kamu melamar pekerjaan.',
                  ),
                  const SizedBox(height: Space.sm),
                  const _FeatureRow(
                    number: '03',
                    icon: Icons.storefront_outlined,
                    title: 'Dibangun untuk UMKM lokal',
                    body: 'Pemberi kerja pasang shift singkat dan kelola pelamar.',
                  ),
                  const SizedBox(height: Space.xxl),
                  Center(
                    child: Text(
                      'Kerjaqueue · Kerja dekat, peluang terbuka.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall,
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

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String number;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(Space.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Accent.teal,
            ),
          ),
          const SizedBox(width: Space.md),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Accent.tealWash,
              borderRadius: Radii.mdAll,
            ),
            child: Icon(icon, size: 19, color: Accent.teal),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(body, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
