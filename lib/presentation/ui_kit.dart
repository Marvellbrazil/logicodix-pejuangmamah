import 'package:flutter/material.dart';

import 'app_theme.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.initials,
    this.photoUrl,
    this.size = 44,
    this.highlight = false,
    this.radius,
  });

  final String initials;
  final String? photoUrl;
  final double size;
  final bool highlight;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: highlight ? Accent.tealWash : Surfaces.overlay,
        borderRadius: BorderRadius.circular(radius ?? size * 0.32),
        border: Border.all(
          color: highlight ? Accent.teal.withValues(alpha: 0.45) : Surfaces.line,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: photoUrl == null || photoUrl!.isEmpty
          ? Text(
              initials,
              style: TextStyle(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: highlight ? Accent.teal : scheme.onSurface,
              ),
            )
          : Image.network(
              photoUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: size * 0.36,
                    fontWeight: FontWeight.w800,
                    color: TextTone.secondary,
                  ),
                ),
              ),
            ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: theme.textTheme.titleMedium),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.lg),
    this.color,
    this.borderColor,
    this.onTap,
    this.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius ?? Radii.lg);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? Surfaces.raised,
        borderRadius: shape,
        border: Border.all(color: borderColor ?? Surfaces.lineSoft),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class Tag extends StatelessWidget {
  const Tag({
    super.key,
    required this.label,
    this.tone = TagTone.neutral,
    this.icon,
  });

  final String label;
  final TagTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      TagTone.neutral => (Surfaces.overlay, TextTone.secondary),
      TagTone.teal => (Accent.tealWash, Accent.teal),
      TagTone.amber => (Accent.amberWash, Accent.amber),
      TagTone.danger => (Accent.dangerWash, Accent.danger),
      TagTone.success => (
        Accent.teal.withValues(alpha: 0.12),
        Accent.success,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: Radii.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum TagTone { neutral, teal, amber, danger, success }

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: Accent.dangerWash,
          borderRadius: Radii.mdAll,
          border: Border.all(color: Accent.danger.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, size: 18, color: Accent.danger),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Accent.danger,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: Accent.danger,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Coba lagi'),
              ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.xl,
        vertical: Space.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Surfaces.raised,
              borderRadius: Radii.lgAll,
              border: Border.all(color: Surfaces.lineSoft),
            ),
            child: Icon(icon, color: TextTone.muted, size: 26),
          ),
          const SizedBox(height: Space.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: Space.xs),
          Text(body, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          if (action != null) ...[
            const SizedBox(height: Space.lg),
            action!,
          ],
        ],
      ),
    );
  }
}

class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final center = Offset(s / 2, s / 2);
    final radius = s / 2;
    final strokeWidth = s * 0.24;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(
      rect,
      -0.25 * 3.14159265,
      0.62 * 3.14159265,
      false,
      paint..color = const Color(0xFF4285F4),
    );
    canvas.drawArc(
      rect,
      0.37 * 3.14159265,
      0.42 * 3.14159265,
      false,
      paint..color = const Color(0xFF34A853),
    );
    canvas.drawArc(
      rect,
      0.79 * 3.14159265,
      0.46 * 3.14159265,
      false,
      paint..color = const Color(0xFFFBBC05),
    );
    canvas.drawArc(
      rect,
      1.25 * 3.14159265,
      0.75 * 3.14159265,
      false,
      paint..color = const Color(0xFFEA4335),
    );

    final bar = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(s * 0.52, s * 0.44, s * 0.44, s * 0.14),
      bar,
    );
  }

  @override
  bool shouldRepaint(_GooglePainter oldDelegate) => false;
}

class LoadingLine extends StatelessWidget {
  const LoadingLine({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: Space.xxl),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      ),
    );
  }
}
