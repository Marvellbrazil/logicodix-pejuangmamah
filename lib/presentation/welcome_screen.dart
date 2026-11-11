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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FadeIn(delay: 0, child: _Brand()),
                        const SizedBox(height: 20),
                        const _FadeIn(delay: 1, child: _HeroIllustration()),
                        const SizedBox(height: 28),
                        _FadeIn(
                          delay: 2,
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
                          delay: 3,
                          child: Text(
                            'Foto nota belanja, barang dan harganya masuk sendiri. Tanpa ngetik, tanpa buku catatan.',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        const SizedBox(height: 28),
                        const _FadeIn(
                          delay: 4,
                          child: _Steps(
                            steps: [
                              _Step(
                                icon: Icons.photo_camera_outlined,
                                title: 'Foto',
                                body: 'Bidik nota belanja',
                              ),
                              _Step(
                                icon: Icons.fact_check_outlined,
                                title: 'Cek',
                                body: 'Koreksi bila perlu',
                              ),
                              _Step(
                                icon: Icons.insights_outlined,
                                title: 'Pantau',
                                body: 'Lihat harga bergerak',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const _FadeIn(
                          delay: 5,
                          child: _Point(
                            icon: Icons.lock_outline,
                            title: 'Nota dibaca di HP kamu',
                            body: 'Foto tidak dikirim ke server mana pun.',
                          ),
                        ),
                        const SizedBox(height: 14),
                        const _FadeIn(
                          delay: 6,
                          child: _Point(
                            icon: Icons.trending_up,
                            title: 'Tahu saat harga naik',
                            body:
                                'Bandingkan harga barang langganan antar nota.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
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
                        const SizedBox(height: 4),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.document_scanner_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Nota UMKM',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return ExcludeSemantics(
      child: SizedBox(
        height: 236,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
            Positioned(
              left: 22,
              top: 22,
              child: Transform.rotate(
                angle: -0.06,
                child: const _ReceiptSketch(),
              ),
            ),
            Positioned(
              right: 16,
              top: 52,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            const Positioned(right: 14, bottom: 22, child: _DataChip()),
          ],
        ),
      ),
    );
  }
}

class _ReceiptSketch extends StatelessWidget {
  const _ReceiptSketch();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = theme.colorScheme.outlineVariant;
    Widget row(double width, double price) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: width,
            height: 7,
            decoration: BoxDecoration(
              color: line,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Container(
            width: price,
            height: 7,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
    return ClipPath(
      clipper: const _ZigzagClipper(),
      child: Container(
        width: 136,
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 70,
              height: 9,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            row(58, 26),
            row(76, 22),
            row(48, 30),
            row(66, 24),
            Divider(color: line, height: 18),
            row(40, 38),
          ],
        ),
      ),
    );
  }
}

class _ZigzagClipper extends CustomClipper<Path> {
  const _ZigzagClipper();

  @override
  Path getClip(Size size) {
    const tooth = 8.0;
    final path = Path()..moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - tooth);
    var x = size.width;
    var down = false;
    while (x > 0) {
      x = (x - tooth).clamp(0, size.width);
      path.lineTo(x, size.height - (down ? tooth : 0));
      down = !down;
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _DataChip extends StatelessWidget {
  const _DataChip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 136,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Harga barang', style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            'Rp 30.000',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  size: 14,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Naik 20%',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step {
  const _Step({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}

class _Steps extends StatelessWidget {
  const _Steps({required this.steps});

  final List<_Step> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(steps[i].icon, color: theme.colorScheme.primary),
                      const Spacer(),
                      Text(
                        '${i + 1}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(steps[i].title, style: theme.textTheme.titleSmall),
                  Text(steps[i].body, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ],
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 14),
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
