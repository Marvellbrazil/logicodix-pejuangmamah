import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onGoogle,
    required this.onGuest,
    required this.busy,
  });

  final VoidCallback onGoogle;
  final VoidCallback onGuest;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FadeIn(
                          delay: 0,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Icon(
                              Icons.document_scanner_outlined,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _FadeIn(
                          delay: 1,
                          child: Text(
                            'Nota jadi data,\nusaha jadi terarah.',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FadeIn(
                          delay: 2,
                          child: Text(
                            'Foto nota belanja, barang dan harganya masuk sendiri. Tanpa ngetik, tanpa buku catatan.',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const _FadeIn(
                          delay: 3,
                          child: _Point(
                            icon: Icons.photo_camera_outlined,
                            title: 'Scan nota',
                            body: 'Dibaca langsung di HP, tanpa internet.',
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _FadeIn(
                          delay: 4,
                          child: _Point(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'Pembukuan otomatis',
                            body:
                                'Total pengeluaran terhitung dari setiap nota.',
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _FadeIn(
                          delay: 5,
                          child: _Point(
                            icon: Icons.trending_up,
                            title: 'Pantau harga',
                            body:
                                'Tahu saat harga barang langganan naik atau turun.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton.icon(
                        onPressed: busy ? null : onGoogle,
                        icon: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.login),
                        label: const Text('Masuk dengan Google'),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: busy ? null : onGuest,
                          child: const Text('Lanjut sebagai tamu'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              Text(body, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _FadeIn extends StatelessWidget {
  const _FadeIn({required this.delay, required this.child});

  final int delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + delay * 90),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 14),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
